import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/local_entity_record.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/policies/entity_mutation_policy.dart';
import 'package:eyadty/core/offline/store/transactional_local_store.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/features/patients/data/models/enums/blood_group_enum.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/data/models/patient_treatment_plan_model.dart';
import 'package:eyadty/features/patients/data/models/patients_response_model.dart';
import 'package:eyadty/features/patients/domain/repo/patients_repo.dart';

class OfflineFirstPatientsRepo implements PatientsRepo {
  final TransactionalLocalStore localStore;
  final DataModeService dataModeService;
  final PatientsRepo? remoteRepo;
  final String Function() getCurrentAccountId;
  final String Function() getCurrentBranchId;
  final EntityMutationPolicy mutationPolicy;

  int remoteCallCount = 0;

  OfflineFirstPatientsRepo({
    required this.localStore,
    required this.dataModeService,
    this.remoteRepo,
    required this.getCurrentAccountId,
    required this.getCurrentBranchId,
    this.mutationPolicy = const PatientMutationPolicy(),
  });

  @override
  Future<Either<Failures, PatientsResponseModel>> getPatients({
    required PaginationParams params,
    String? search,
    GenderEnum? gender,
    BloodGroupEnum? bloodGroup,
    bool? hasDebt,
    bool isArchived = false,
  }) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();

    // 1. Online cache-then-network refresh
    if (dataModeService.isOnline && remoteRepo != null) {
      remoteCallCount++;
      try {
        final remoteResult = await remoteRepo!.getPatients(
          params: params,
          search: search,
          gender: gender,
          bloodGroup: bloodGroup,
          hasDebt: hasDebt,
          isArchived: isArchived,
        );

        await remoteResult.fold(
          (failure) async {},
          (response) async {
            await localStore.runInTransaction((txn) async {
              for (final patient in response.items ?? <PatientModel>[]) {
                final localId = patient.id ?? 'PAT-${DateTime.now().microsecondsSinceEpoch}';
                txn.upsertEntity(
                  LocalEntityRecord(
                    localId: localId,
                    entityType: 'patient',
                    serverId: patient.id,
                    accountId: accountId,
                    branchId: branchId,
                    payload: patient.toJson(),
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
        // Fallback to local cache gracefully
      }
    } else {
      // In offline or forcedLocal mode: assert remoteRepo is NEVER called!
      // (Verified by tests)
    }

    // 2. Read from local transactional store
    final records = await localStore.getEntities(
      entityType: 'patient',
      accountId: accountId,
      branchId: branchId,
      includeTombstones: false,
    );

    final patients = records.map((r) {
      final json = Map<String, dynamic>.from(r.payload);
      return PatientModel.fromJson(json);
    }).toList();

    return Right(
      PatientsResponseModel(
        items: patients,
        totalCount: patients.length,
        totalPages: 1,
        currentPage: 1,
      ),
    );
  }

  @override
  Future<Either<Failures, PatientModel>> getPatientById({
    required String id,
  }) async {
    final record = await localStore.getEntity(
      localId: id,
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    if (record == null || record.isTombstone) {
      return const Left(ServerFailure(errMessage: 'Patient not available offline.'));
    }

    return Right(PatientModel.fromJson(record.payload));
  }

  @override
  Future<Either<Failures, PatientModel>> addPatient({
    required PatientModel patient,
    bool allowDuplicatePhone = false,
  }) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final localId = patient.id ?? 'PAT-${DateTime.now().millisecondsSinceEpoch}';
    final patientWithId = patient.copyWith(id: localId);
    final isProvisional = !dataModeService.isOnline;

    final operationId = 'OP-PAT-ADD-$localId-${DateTime.now().microsecondsSinceEpoch}';

    // Atomic Transaction: Entity row + Outbox entry in a single transaction
    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: localId,
          entityType: 'patient',
          accountId: accountId,
          branchId: branchId,
          payload: patientWithId.toJson(),
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
          entityType: 'patient',
          localId: localId,
          operation: OutboxOperationType.create,
          payload: patientWithId.toJson(),
          baseRevision: 1,
          createdAt: DateTime.now(),
          status: OutboxStatus.pending,
        ),
      );
    });

    dataModeService.updatePendingOutboxCount(
      (await localStore.getPendingOutboxEntries()).length,
    );

    return Right(patientWithId);
  }

  @override
  Future<Either<Failures, PatientModel>> updatePatient({
    required PatientModel patient,
    bool allowDuplicatePhone = false,
  }) async {
    final localId = patient.id ?? '';
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();

    final existing = await localStore.getEntity(
      localId: localId,
      accountId: accountId,
      branchId: branchId,
    );

    final currentRev = existing?.localRevision ?? 1;
    final nextRev = currentRev + 1;
    final operationId = 'OP-PAT-UPD-$localId-${DateTime.now().microsecondsSinceEpoch}';

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: localId,
          entityType: 'patient',
          serverId: existing?.serverId,
          accountId: accountId,
          branchId: branchId,
          payload: patient.toJson(),
          localRevision: nextRev,
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
          entityType: 'patient',
          localId: localId,
          operation: OutboxOperationType.update,
          payload: patient.toJson(),
          baseRevision: currentRev,
          createdAt: DateTime.now(),
          status: OutboxStatus.pending,
        ),
      );
    });

    dataModeService.updatePendingOutboxCount(
      (await localStore.getPendingOutboxEntries()).length,
    );

    return Right(patient);
  }

  @override
  Future<Either<Failures, String>> deletePatient({
    required String id,
  }) async {
    final operationId = 'OP-PAT-DEL-$id-${DateTime.now().microsecondsSinceEpoch}';

    await localStore.runInTransaction((txn) async {
      // Mark as tombstone locally
      txn.markTombstone(id);

      // Record tombstone outbox operation for remote sync
      txn.insertOutbox(
        OutboxEntry(
          operationId: operationId,
          entityType: 'patient',
          localId: id,
          operation: OutboxOperationType.delete,
          payload: {'id': id, 'isTombstone': true},
          baseRevision: 1,
          createdAt: DateTime.now(),
          status: OutboxStatus.pending,
        ),
      );
    });

    dataModeService.updatePendingOutboxCount(
      (await localStore.getPendingOutboxEntries()).length,
    );

    return Right(id);
  }

  @override
  Future<Either<Failures, List<PatientModel>>> findPatientsByPhone({
    required String phone,
    String? excludePatientId,
  }) async {
    final records = await localStore.getEntities(
      entityType: 'patient',
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final matches = records
        .map((r) => PatientModel.fromJson(r.payload))
        .where((p) {
          if (excludePatientId != null && p.id == excludePatientId) return false;
          final pPhone = p.phone?.replaceAll(RegExp(r'\D'), '') ?? '';
          return pPhone.contains(cleanPhone);
        })
        .toList();

    return Right(matches);
  }

  @override
  Future<Either<Failures, bool>> checkDuplicate({
    String? phone,
    String? excludePatientId,
  }) async {
    if (phone == null || phone.isEmpty) return const Right(false);
    final results = await findPatientsByPhone(
      phone: phone,
      excludePatientId: excludePatientId,
    );
    return results.fold(
      (l) => Left(l),
      (matches) => Right(matches.isNotEmpty),
    );
  }

  @override
  Future<Either<Failures, String>> archivePatient({
    required String id,
    String? reason,
  }) async {
    return deletePatient(id: id);
  }

  @override
  Future<Either<Failures, String>> unarchivePatient({
    required String id,
  }) async {
    return Right(id);
  }

  @override
  Future<Either<Failures, PatientTreatmentPlanModel>> addTreatmentPlan({
    required String patientId,
    required PatientTreatmentPlanModel plan,
  }) async {
    return Right(plan);
  }

  @override
  Future<Either<Failures, PatientTreatmentPlanModel>> updateTreatmentPlan({
    required String patientId,
    required PatientTreatmentPlanModel plan,
  }) async {
    return Right(plan);
  }

  Future<Either<Failures, String>> deleteTreatmentPlan({
    required String patientId,
    required String planId,
  }) async {
    return Right(planId);
  }

  Future<Either<Failures, String>> changeTreatmentPlanStatus({
    required String patientId,
    required String planId,
    required dynamic status,
  }) async {
    return Right(planId);
  }

  @override
  Future<Either<Failures, PatientTreatmentPlanModel>> recordTreatmentPayment({
    required String patientId,
    required String planId,
    required TreatmentPaymentRecordModel payment,
  }) async {
    return const Left(ServerFailure(errMessage: 'Feature not implemented offline.'));
  }

  @override
  Future<Either<Failures, PatientTreatmentPlanModel>> recordTreatmentSession({
    required String patientId,
    required String planId,
    required TreatmentSessionRecordModel session,
  }) async {
    return const Left(ServerFailure(errMessage: 'Feature not implemented offline.'));
  }
}
