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
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/domain/helpers/booking_statistics_calculator.dart';
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

    // Calculate local provisional summary using BookingStatisticsCalculator
    final targetDate = date;
    final bookings = records
        .map((r) => BookingModel.fromJson(Map<String, dynamic>.from(r.payload)))
        .toList();

    if (targetDate != null) {
      final summary = BookingStatisticsCalculator.calculateSummary(
        bookings: bookings,
        selectedDate: targetDate,
        branchId: effectiveBranchId,
      );
      return Right(summary);
    }

    // If date is null (overall summary across dates)
    int total = bookings.length;
    int pending = 0;
    int completed = 0;
    int cancelled = 0;
    int noShow = 0;

    for (final b in bookings) {
      if (b.status == BookingStatusEnum.completed) {
        completed++;
      } else if (b.status == BookingStatusEnum.cancelled) {
        cancelled++;
      } else if (b.status == BookingStatusEnum.noShow) {
        noShow++;
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
        noShowCount: noShow,
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

    var bookings = records
        .map((r) => BookingModel.fromJson(Map<String, dynamic>.from(r.payload)))
        .toList();

    // Apply filtering on local store results
    final filterList = params.filterList;
    String? searchQuery;
    String? branchIdFilter;
    String? dateFilter;
    String? statusFilter;
    String? bookingTypeFilter;
    String? customerIdFilter;

    for (final f in filterList) {
      if (f.key == 'search') searchQuery = f.value;
      if (f.key == 'branchId') branchIdFilter = f.value;
      if (f.key == 'date') dateFilter = f.value;
      if (f.key == 'status') statusFilter = f.value;
      if (f.key == 'bookingType') bookingTypeFilter = f.value;
      if (f.key == 'customerId') customerIdFilter = f.value;
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      bookings = bookings.where((b) {
        final cName = b.customerName?.toLowerCase() ?? '';
        final cPhone = b.customerPhone?.toLowerCase() ?? '';
        final sName = b.serviceName?.toLowerCase() ?? '';
        final bId = b.id?.toLowerCase() ?? '';
        return cName.contains(q) || cPhone.contains(q) || sName.contains(q) || bId.contains(q);
      }).toList();
    }

    if (branchIdFilter != null && branchIdFilter.isNotEmpty && branchIdFilter != 'all') {
      bookings = bookings
          .where((b) => BookingStatisticsCalculator.matchesBranch(b, branchIdFilter))
          .toList();
    }

    DateTime? selectedDateObj;
    if (dateFilter != null && dateFilter.isNotEmpty && dateFilter.length == 10) {
      selectedDateObj = DateTime.tryParse(dateFilter);
    }

    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      final statusEnum = BookingStatusEnum.fromValue(statusFilter);
      if (statusEnum != null && selectedDateObj != null) {
        bookings = bookings.where((b) {
          return BookingStatisticsCalculator.matchesStatusFilter(
            b,
            statusEnum,
            selectedDate: selectedDateObj!,
            branchId: branchIdFilter,
          );
        }).toList();
      } else if (statusEnum != null) {
        bookings = bookings.where((b) => b.status == statusEnum).toList();
      }
    } else if (selectedDateObj != null) {
      bookings = bookings.where((b) {
        return BookingStatisticsCalculator.matchesStatusFilter(
          b,
          null,
          selectedDate: selectedDateObj!,
          branchId: branchIdFilter,
        );
      }).toList();
    } else if (dateFilter != null && dateFilter.length == 7) {
      bookings = bookings.where((b) {
        final d = b.appointmentTime ?? b.date;
        if (d == null) return false;
        final monthFormatted = "${d.year}-${d.month.toString().padLeft(2, '0')}";
        return monthFormatted == dateFilter;
      }).toList();
    }

    if (bookingTypeFilter != null && bookingTypeFilter.isNotEmpty && bookingTypeFilter != 'all') {
      bookings = bookings.where((b) {
        return b.bookingType?.value.toLowerCase() == bookingTypeFilter;
      }).toList();
    }

    if (customerIdFilter != null && customerIdFilter.isNotEmpty) {
      bookings = bookings.where((b) {
        return b.customerId == customerIdFilter || b.customer?.id == customerIdFilter;
      }).toList();
    }

    // Sort by date desc
    bookings.sort((a, b) {
      final dateA = a.date ?? DateTime(1970);
      final dateB = b.date ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    final totalCount = bookings.length;
    final page = params.page ?? 1;
    final limit = params.limit ?? 10;
    final totalPages = (totalCount / limit).ceil().clamp(1, 999999);
    final startIndex = (page - 1) * limit;
    final pagedBookings = startIndex < bookings.length
        ? bookings.skip(startIndex).take(limit).toList()
        : <BookingModel>[];

    return Right(
      BookingsResponseModel(
        bookings: pagedBookings,
        pagination: PaginationModel(
          page: page,
          limit: limit,
          total: totalCount,
          pages: totalPages,
        ),
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
