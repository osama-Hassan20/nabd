import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../features/bookings/domain/contracts/active_visit_lookup.dart';
import '../../../features/visits/data/models/consultation_queue_item_model.dart';
import '../../../features/visits/data/models/enums/visit_status_enum.dart';
import '../../../features/visits/data/models/visit_addendum_model.dart';
import '../../../features/visits/data/models/visit_model.dart';
import '../../../features/visits/data/models/vitals_model.dart';
import '../../../features/visits/domain/repo/visits_repo.dart';
import '../data_mode_service.dart';
import '../models/local_entity_record.dart';
import '../models/outbox_entry.dart';
import '../models/sync_status.dart';
import '../policies/entity_mutation_policy.dart';
import '../store/transactional_local_store.dart';

class OfflineFirstVisitsRepo implements VisitsRepo, ActiveVisitLookup {
  final TransactionalLocalStore localStore;
  final DataModeService dataModeService;
  final VisitsRepo remoteRepo;
  final String Function() getCurrentAccountId;
  final String Function() getCurrentBranchId;
  final EntityMutationPolicy mutationPolicy;

  OfflineFirstVisitsRepo({
    required this.localStore,
    required this.dataModeService,
    required this.remoteRepo,
    required this.getCurrentAccountId,
    required this.getCurrentBranchId,
    this.mutationPolicy = const ClinicalRecordMutationPolicy(),
  });

  @override
  Future<Either<Failures, List<ConsultationQueueItemModel>>> getDoctorQueue({
    String? doctorId,
    required String branchId,
    required DateTime date,
  }) async {
    // 1. Fetch seed queue items from remote repo
    final remoteRes = await remoteRepo.getDoctorQueue(
      doctorId: doctorId,
      branchId: branchId,
      date: date,
    );

    List<ConsultationQueueItemModel> baseQueue = [];
    remoteRes.fold((_) {}, (items) => baseQueue = List.from(items));

    // 2. Fetch local visit updates
    final localVisits = await localStore.getEntities(
      entityType: 'visit',
      accountId: getCurrentAccountId(),
      branchId: branchId,
    );

    final localVisitMap = <String, VisitModel>{};
    for (final rec in localVisits) {
      if (!rec.isTombstone) {
        try {
          final visit = VisitModel.fromJson(rec.payload);
          if (visit.bookingId != null) {
            localVisitMap[visit.bookingId!] = visit;
          }
        } catch (_) {}
      }
    }

    // 3. Reconcile queue item statuses with local visits
    final updatedQueue = baseQueue.map((item) {
      final localVisit = localVisitMap[item.bookingId];
      if (localVisit != null) {
        return item.copyWith(
          visit: localVisit,
        );
      }
      return item;
    }).toList();

    return Right(updatedQueue);
  }

  @override
  Future<Either<Failures, VisitModel?>> getVisitById({
    required String visitId,
  }) async {
    final localRec = await localStore.getEntity(
      localId: visitId,
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    if (localRec != null && !localRec.isTombstone) {
      try {
        return Right(VisitModel.fromJson(localRec.payload));
      } catch (_) {}
    }

    // Fallback to remote/mock
    return remoteRepo.getVisitById(visitId: visitId);
  }

  @override
  Future<Either<Failures, VisitModel?>> getVisitByBookingId({
    required String bookingId,
  }) async {
    final records = await localStore.getEntities(
      entityType: 'visit',
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    for (final rec in records) {
      if (!rec.isTombstone) {
        try {
          final visit = VisitModel.fromJson(rec.payload);
          if (visit.bookingId == bookingId) {
            return Right(visit);
          }
        } catch (_) {}
      }
    }

    return remoteRepo.getVisitByBookingId(bookingId: bookingId);
  }

  @override
  Future<Either<Failures, List<VisitModel>>> getVisitsByPatientId({
    required String patientId,
  }) async {
    final records = await localStore.getEntities(
      entityType: 'visit',
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    final localVisits = <VisitModel>[];
    final seenVisitIds = <String>{};

    for (final rec in records) {
      if (!rec.isTombstone) {
        try {
          final visit = VisitModel.fromJson(rec.payload);
          if (visit.patientId == patientId) {
            localVisits.add(visit);
            if (visit.id != null) seenVisitIds.add(visit.id!);
          }
        } catch (_) {}
      }
    }

    // Merge remote visits not in local store
    final remoteRes = await remoteRepo.getVisitsByPatientId(patientId: patientId);
    remoteRes.fold((_) {}, (items) {
      for (final v in items) {
        if (v.id != null && !seenVisitIds.contains(v.id)) {
          localVisits.add(v);
        }
      }
    });

    return Right(localVisits);
  }

  @override
  Future<Either<Failures, VisitModel>> upsertConsultationStart({
    required String bookingId,
    required String patientId,
    required String branchId,
    required String patientName,
    String? patientPhone,
    required String doctorId,
    required String doctorName,
    String? specialty,
  }) async {
    final existingRes = await getVisitByBookingId(bookingId: bookingId);
    VisitModel? existing;
    existingRes.fold((_) {}, (v) => existing = v);

    final now = DateTime.now();
    final visitId = existing?.id ?? 'VIS-${now.millisecondsSinceEpoch}';

    final updated = (existing ?? const VisitModel()).copyWith(
      id: visitId,
      bookingId: bookingId,
      patientId: patientId,
      branchId: branchId,
      patientName: patientName,
      patientPhone: patientPhone ?? existing?.patientPhone,
      doctorId: doctorId,
      doctorName: doctorName,
      specialty: specialty ?? existing?.specialty,
      status: VisitStatusEnum.inProgress,
      startedAt: existing?.startedAt ?? now,
      lastSavedAt: now,
    );

    return _persistVisitMutation(
      visit: updated,
      operationType: OutboxOperationType.create,
    );
  }

  @override
  Future<Either<Failures, VisitModel>> recordVitals({
    required String bookingId,
    required String patientId,
    required String branchId,
    required String patientName,
    String? patientPhone,
    required String doctorId,
    required String doctorName,
    String? specialty,
    required VitalsModel vitals,
  }) async {
    final existingRes = await getVisitByBookingId(bookingId: bookingId);
    VisitModel? existing;
    existingRes.fold((_) {}, (v) => existing = v);

    final now = DateTime.now();
    final visitId = existing?.id ?? 'VIS-${now.millisecondsSinceEpoch}';

    final updated = (existing ?? const VisitModel()).copyWith(
      id: visitId,
      bookingId: bookingId,
      patientId: patientId,
      branchId: branchId,
      patientName: patientName,
      patientPhone: patientPhone ?? existing?.patientPhone,
      doctorId: doctorId,
      doctorName: doctorName,
      specialty: specialty ?? existing?.specialty,
      vitals: vitals,
      triageAt: existing?.triageAt ?? now,
      lastSavedAt: now,
      status: existing?.status ?? VisitStatusEnum.triage,
    );

    return _persistVisitMutation(
      visit: updated,
      operationType: OutboxOperationType.update,
    );
  }

  @override
  Future<Either<Failures, VisitModel>> saveVisitDraft({
    required VisitModel draft,
  }) async {
    if (draft.id == null) {
      return const Left(ServerFailure(errMessage: 'Visit ID is required to save draft.'));
    }

    final existingRec = await localStore.getEntity(
      localId: draft.id!,
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    if (existingRec != null) {
      final existingStatus = existingRec.payload['status']?.toString();
      if (existingStatus == VisitStatusEnum.finalized.value) {
        return const Left(ServerFailure(
          errMessage: 'Finalized clinical visit records are immutable and cannot be overwritten.',
        ));
      }
    }

    final now = DateTime.now();
    final updated = draft.copyWith(
      lastSavedAt: now,
      status: VisitStatusEnum.inProgress,
    );

    return _persistVisitMutation(
      visit: updated,
      operationType: OutboxOperationType.update,
    );
  }

  @override
  Future<Either<Failures, VisitModel>> finalizeVisit({
    required VisitModel finalContent,
  }) async {
    if (finalContent.id == null) {
      return const Left(ServerFailure(errMessage: 'Visit ID is required to finalize visit.'));
    }

    final now = DateTime.now();
    final finalized = finalContent.copyWith(
      status: VisitStatusEnum.finalized,
      finalizedAt: now,
      lastSavedAt: now,
    );

    return _persistVisitMutation(
      visit: finalized,
      operationType: OutboxOperationType.update,
    );
  }

  @override
  Future<Either<Failures, VisitModel>> addVisitAddendum({
    required String visitId,
    required VisitAddendumModel addendum,
  }) async {
    final existingRes = await getVisitById(visitId: visitId);
    VisitModel? existing;
    existingRes.fold((_) {}, (v) => existing = v);

    if (existing == null) {
      return const Left(ServerFailure(errMessage: 'Visit not found to add addendum.'));
    }

    final currentAddenda = List<VisitAddendumModel>.from(existing?.addenda ?? []);
    currentAddenda.add(addendum);

    final updated = existing!.copyWith(
      addenda: currentAddenda,
      lastSavedAt: DateTime.now(),
    );

    return _persistVisitMutation(
      visit: updated,
      operationType: OutboxOperationType.appendAddendum,
    );
  }

  @override
  Future<VisitStatusEnum?> getVisitStatusByBookingId(String bookingId) async {
    final visitRes = await getVisitByBookingId(bookingId: bookingId);
    return visitRes.fold((_) => null, (v) => v?.status);
  }

  Future<Either<Failures, VisitModel>> _persistVisitMutation({
    required VisitModel visit,
    required OutboxOperationType operationType,
  }) async {
    final accountId = getCurrentAccountId();
    final branchId = visit.branchId ?? getCurrentBranchId();
    final localId = visit.id!;
    final now = DateTime.now();
    final isProvisional = !dataModeService.isOnline;
    final operationId = 'op_visit_${localId}_${now.microsecondsSinceEpoch}';

    final dependencies = <String>[];
    if (visit.patientId != null && visit.patientId!.isNotEmpty) {
      dependencies.add('patient:${visit.patientId}');
    }
    if (visit.bookingId != null && visit.bookingId!.isNotEmpty) {
      dependencies.add('booking:${visit.bookingId}');
    }

    try {
      await localStore.runInTransaction((txn) async {
        txn.upsertEntity(
          LocalEntityRecord(
            localId: localId,
            entityType: 'visit',
            accountId: accountId,
            branchId: branchId,
            payload: visit.toJson(),
            localRevision: 1,
            syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
            isProvisional: isProvisional,
            createdAt: visit.startedAt ?? now,
            updatedAt: now,
          ),
        );

        txn.insertOutbox(
          OutboxEntry(
            operationId: operationId,
            entityType: 'visit',
            localId: localId,
            operation: operationType,
            payload: visit.toJson(),
            baseRevision: 1,
            createdAt: now,
            status: OutboxStatus.pending,
            dependencyRefs: dependencies,
          ),
        );
      });

      // Synchronize in-memory remote mock
      try {
        if (visit.status == VisitStatusEnum.finalized) {
          await remoteRepo.finalizeVisit(finalContent: visit);
        } else if (visit.vitals != null && visit.status == VisitStatusEnum.triage) {
          await remoteRepo.recordVitals(
            bookingId: visit.bookingId!,
            patientId: visit.patientId!,
            branchId: branchId,
            patientName: visit.patientName ?? '',
            doctorId: visit.doctorId ?? '',
            doctorName: visit.doctorName ?? '',
            vitals: visit.vitals!,
          );
        } else {
          await remoteRepo.saveVisitDraft(draft: visit);
        }
      } catch (_) {}

      return Right(visit);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'Failed to persist visit locally: $e'));
    }
  }
}
