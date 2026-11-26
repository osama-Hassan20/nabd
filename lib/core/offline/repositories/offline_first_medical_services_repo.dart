import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/local_entity_record.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/store/transactional_local_store.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/features/settings/domain/repo/medical_services_repo.dart';

class OfflineFirstMedicalServicesRepo implements MedicalServicesRepo {
  final TransactionalLocalStore localStore;
  final DataModeService dataModeService;
  final MedicalServicesRepo remoteRepo;
  final String Function() getCurrentAccountId;
  final String Function() getCurrentBranchId;

  OfflineFirstMedicalServicesRepo({
    required this.localStore,
    required this.dataModeService,
    required this.remoteRepo,
    required this.getCurrentAccountId,
    required this.getCurrentBranchId,
  });

  @override
  Future<Either<Failures, List<MedicalServiceModel>>> getMedicalServices({
    bool? onlyActive,
    String? doctorId,
    String? query,
  }) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();

    final records = await localStore.getEntities(
      entityType: 'medical_service',
      accountId: accountId,
      branchId: branchId,
    );

    final localServices = <String, MedicalServiceModel>{};
    for (final rec in records) {
      if (!rec.isTombstone) {
        try {
          final srv = MedicalServiceModel.fromJson(rec.payload);
          if (srv.id != null) {
            localServices[srv.id!] = srv;
          }
        } catch (_) {}
      }
    }

    final remoteRes = await remoteRepo.getMedicalServices(
      onlyActive: onlyActive,
      doctorId: doctorId,
      query: query,
    );

    remoteRes.fold((_) {}, (services) {
      for (final s in services) {
        final existing = records.where((r) => r.localId == s.id).firstOrNull;
        if (existing != null && existing.isTombstone) {
          continue;
        }
        if (s.id != null && !localServices.containsKey(s.id!)) {
          localServices[s.id!] = s;
        }
      }
    });

    var result = localServices.values.toList();
    if (onlyActive == true) {
      result = result.where((s) => s.isServiceActive).toList();
    }
    if (doctorId != null && doctorId.isNotEmpty) {
      result = result.where((s) => s.assignedDoctorId == doctorId).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((s) => (s.name ?? '').toLowerCase().contains(q)).toList();
    }

    return Right(result);
  }

  @override
  Future<Either<Failures, MedicalServiceModel>> getMedicalServiceById(String id) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();

    final rec = await localStore.getEntity(
      localId: id,
      accountId: accountId,
      branchId: branchId,
    );

    if (rec != null && !rec.isTombstone) {
      try {
        return Right(MedicalServiceModel.fromJson(rec.payload));
      } catch (_) {}
    }

    return remoteRepo.getMedicalServiceById(id);
  }

  @override
  Future<Either<Failures, MedicalServiceModel>> addMedicalService(
    MedicalServiceModel service,
  ) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();
    final isProvisional = !dataModeService.isOnline;
    final serviceId = service.id ?? 'SRV-${now.millisecondsSinceEpoch}';
    final toSave = service.id == null ? service.copyWith(id: serviceId) : service;

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: serviceId,
          entityType: 'medical_service',
          accountId: accountId,
          branchId: branchId,
          payload: toSave.toJson(),
          localRevision: 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_srv_add_${serviceId}_${now.microsecondsSinceEpoch}',
          entityType: 'medical_service',
          localId: serviceId,
          operation: OutboxOperationType.create,
          payload: toSave.toJson(),
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.addMedicalService(toSave);
    } catch (_) {}

    return Right(toSave);
  }

  @override
  Future<Either<Failures, MedicalServiceModel>> updateMedicalService(
    MedicalServiceModel service,
  ) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();
    final isProvisional = !dataModeService.isOnline;
    final serviceId = service.id ?? 'SRV-${now.millisecondsSinceEpoch}';

    final existing = await localStore.getEntity(
      localId: serviceId,
      accountId: accountId,
      branchId: branchId,
    );
    final baseRev = existing?.localRevision ?? 1;

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: serviceId,
          entityType: 'medical_service',
          accountId: accountId,
          branchId: branchId,
          payload: service.toJson(),
          localRevision: baseRev + 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_srv_upd_${serviceId}_${now.microsecondsSinceEpoch}',
          entityType: 'medical_service',
          localId: serviceId,
          operation: OutboxOperationType.update,
          payload: service.toJson(),
          previousPayload: existing?.payload,
          baseRevision: baseRev,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.updateMedicalService(service);
    } catch (_) {}

    return Right(service);
  }

  @override
  Future<Either<Failures, MedicalServiceModel>> toggleServiceStatus(String id) async {
    final res = await getMedicalServiceById(id);
    return res.fold(
      (failure) => Left(failure),
      (service) {
        final toggled = service.copyWith(isActive: !(service.isActive ?? true));
        return updateMedicalService(toggled);
      },
    );
  }

  @override
  Future<Either<Failures, Unit>> deleteMedicalService(String id) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();

    final existing = await localStore.getEntity(
      localId: id,
      accountId: accountId,
      branchId: branchId,
    );

    await localStore.runInTransaction((txn) async {
      txn.markTombstone(id);

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_srv_del_${id}_${now.microsecondsSinceEpoch}',
          entityType: 'medical_service',
          localId: id,
          operation: OutboxOperationType.delete,
          payload: {'id': id},
          previousPayload: existing?.payload,
          baseRevision: existing?.localRevision ?? 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.deleteMedicalService(id);
    } catch (_) {}

    return const Right(unit);
  }
}
