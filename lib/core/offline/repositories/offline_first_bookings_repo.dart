import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/local_entity_record.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/store/transactional_local_store.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_summary_model.dart';
import 'package:eyadty/features/bookings/data/models/bookings_response_model.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/apply_discount_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/change_booking_status_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/reassign_technician_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/remove_discount_params.dart';

class OfflineFirstBookingsRepo implements BookingsRepo {
  final TransactionalLocalStore localStore;
  final DataModeService dataModeService;
  final BookingsRepo? remoteRepo;
  final String Function() getCurrentAccountId;
  final String Function() getCurrentBranchId;

  int remoteCallCount = 0;

  OfflineFirstBookingsRepo({
    required this.localStore,
    required this.dataModeService,
    this.remoteRepo,
    required this.getCurrentAccountId,
    required this.getCurrentBranchId,
  });

  @override
  Future<Either<Failures, BookingSummaryModel>> getBookingSummary({
    DateTime? date,
    String? branchId,
  }) async {
    final effectiveBranchId = branchId ?? getCurrentBranchId();
    final accountId = getCurrentAccountId();

    final records = await localStore.getEntities(
      entityType: 'booking',
      accountId: accountId,
      branchId: effectiveBranchId,
    );

    // Calculate local provisional summary
    int total = records.length;
    int pending = 0;
    int completed = 0;
    int cancelled = 0;

    for (final r in records) {
      final status = r.payload['status']?.toString();
      if (status == 'completed') {
        completed++;
      } else if (status == 'cancelled') {
        cancelled++;
      } else {
        pending++;
      }
    }

    return Right(
      BookingSummaryModel(
        totalBookings: total,
        upcomingBookings: pending,
        completedBookings: completed,
        cancelledBookings: cancelled,
      ),
    );
  }

  @override
  Future<Either<Failures, BookingsResponseModel>> getBookings(
    PaginationParams params,
  ) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();

    if (dataModeService.isOnline && remoteRepo != null) {
      remoteCallCount++;
      try {
        final remoteRes = await remoteRepo!.getBookings(params);
        await remoteRes.fold(
          (failure) async {},
          (response) async {
            await localStore.runInTransaction((txn) async {
              for (final b in response.bookings ?? <BookingModel>[]) {
                final localId = b.id ?? 'BOOK-${DateTime.now().microsecondsSinceEpoch}';
                txn.upsertEntity(
                  LocalEntityRecord(
                    localId: localId,
                    entityType: 'booking',
                    serverId: b.id,
                    accountId: accountId,
                    branchId: branchId,
                    payload: b.toJson(),
                    syncStatus: SyncStatus.synced,
                    isProvisional: false,
                    isTombstone: false,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
              }
            });
          },
        );
      } catch (_) {
        // Fallback to local store
      }
    }

    final records = await localStore.getEntities(
      entityType: 'booking',
      accountId: accountId,
      branchId: branchId,
    );

    final bookings = records
        .map((r) => BookingModel.fromJson(Map<String, dynamic>.from(r.payload)))
        .toList();

    return Right(
      BookingsResponseModel(
        bookings: bookings,
      ),
    );
  }

  @override
  Future<Either<Failures, BookingModel>> getBookingById(String id) async {
    final record = await localStore.getEntity(
      localId: id,
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    if (record == null || record.isTombstone) {
      return const Left(ServerFailure(errMessage: 'Booking not available offline.'));
    }

    return Right(BookingModel.fromJson(record.payload));
  }

  @override
  Future<Either<Failures, BookingModel>> createBooking(
    BookingModel booking, {
    DateTime? customNow,
  }) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final localId = booking.id ?? 'BOOK-${DateTime.now().millisecondsSinceEpoch}';
    final isProvisional = !dataModeService.isOnline;
    final bookingWithId = booking.copyWith(id: localId);

    final operationId = 'OP-BOOK-ADD-$localId-${DateTime.now().microsecondsSinceEpoch}';

    // Dependency references: Appointment depends on Patient!
    final dependencies = <String>[];
    if (booking.patientId != null && booking.patientId!.isNotEmpty) {
      dependencies.add('patient:${booking.patientId}');
    }

    // Atomic transaction: Row + Outbox entry
    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: localId,
          entityType: 'booking',
          accountId: accountId,
          branchId: branchId,
          payload: bookingWithId.toJson(),
          localRevision: 1,
          syncStatus: SyncStatus.pending,
          isProvisional: isProvisional,
          isTombstone: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: operationId,
          entityType: 'booking',
          localId: localId,
          operation: OutboxOperationType.create,
          payload: bookingWithId.toJson(),
          baseRevision: 1,
          createdAt: DateTime.now(),
          status: OutboxStatus.pending,
          dependencyRefs: dependencies,
        ),
      );
    });

    dataModeService.updatePendingOutboxCount(
      (await localStore.getPendingOutboxEntries()).length,
    );

    return Right(bookingWithId);
  }

  @override
  Future<Either<Failures, BookingModel>> updateBooking(
    BookingModel booking, {
    DateTime? customNow,
  }) async {
    final localId = booking.id ?? '';
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();

    final existing = await localStore.getEntity(
      localId: localId,
      accountId: accountId,
      branchId: branchId,
    );

    final currentRev = existing?.localRevision ?? 1;
    final operationId = 'OP-BOOK-UPD-$localId-${DateTime.now().microsecondsSinceEpoch}';

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: localId,
          entityType: 'booking',
          serverId: existing?.serverId,
          accountId: accountId,
          branchId: branchId,
          payload: booking.toJson(),
          localRevision: currentRev + 1,
          syncStatus: SyncStatus.pending,
          isProvisional: !dataModeService.isOnline,
          isTombstone: false,
          createdAt: existing?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: operationId,
          entityType: 'booking',
          localId: localId,
          operation: OutboxOperationType.update,
          payload: booking.toJson(),
          baseRevision: currentRev,
          createdAt: DateTime.now(),
          status: OutboxStatus.pending,
        ),
      );
    });

    dataModeService.updatePendingOutboxCount(
      (await localStore.getPendingOutboxEntries()).length,
    );

    return Right(booking);
  }

  @override
  Future<Either<Failures, Unit>> changeBookingStatus(
    ChangeBookingStatusParams params,
  ) async {
    final existingRes = await getBookingById(params.bookingId);
    return existingRes.fold(
      (failure) => Left(failure),
      (booking) async {
        final updated = booking.copyWith(status: params.newStatus);
        final updateRes = await updateBooking(updated);
        return updateRes.fold(
          (f) => Left(f),
          (_) => const Right(unit),
        );
      },
    );
  }

  @override
  Future<Either<Failures, Unit>> deleteBooking(String bookingId) async {
    final operationId = 'OP-BOOK-DEL-$bookingId-${DateTime.now().microsecondsSinceEpoch}';

    await localStore.runInTransaction((txn) async {
      txn.markTombstone(bookingId);
      txn.insertOutbox(
        OutboxEntry(
          operationId: operationId,
          entityType: 'booking',
          localId: bookingId,
          operation: OutboxOperationType.delete,
          payload: {'bookingId': bookingId, 'isTombstone': true},
          baseRevision: 1,
          createdAt: DateTime.now(),
          status: OutboxStatus.pending,
        ),
      );
    });

    dataModeService.updatePendingOutboxCount(
      (await localStore.getPendingOutboxEntries()).length,
    );

    return const Right(unit);
  }

  @override
  Future<Either<Failures, List<BookingModel>>> getDoctorBookingsForDate({
    required String doctorId,
    required DateTime date,
  }) async {
    final records = await localStore.getEntities(
      entityType: 'booking',
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    final bookings = records
        .map((r) => BookingModel.fromJson(r.payload))
        .where((b) => b.doctorId == doctorId)
        .toList();

    return Right(bookings);
  }

  @override
  Future<Either<Failures, BookingModel>> applyDiscount(
    ApplyDiscountParams params,
  ) async {
    final bookingRes = await getBookingById(params.bookingId ?? '');
    return bookingRes;
  }

  @override
  Future<Either<Failures, BookingModel>> removeDiscount(
    RemoveDiscountParams params,
  ) async {
    final bookingRes = await getBookingById(params.bookingId ?? '');
    return bookingRes;
  }

  @override
  Future<Either<Failures, Unit>> reassignTechnician(
    ReassignTechnicianParams params,
  ) async {
    return const Right(unit);
  }
}
