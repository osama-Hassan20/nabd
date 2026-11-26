import 'package:dartz/dartz.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/local_entity_record.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/store/transactional_local_store.dart';
import 'package:eyadty/features/specialty_records/data/models/specialty_record_entry_model.dart';

class OfflineFirstSpecialtyRecordsRepo {
  final TransactionalLocalStore localStore;
  final DataModeService dataModeService;
  final String Function() getCurrentAccountId;
  final String Function() getCurrentBranchId;

  OfflineFirstSpecialtyRecordsRepo({
    required this.localStore,
    required this.dataModeService,
    required this.getCurrentAccountId,
    required this.getCurrentBranchId,
  });

  static const String entityTypeName = 'specialty_record_entry';

  Future<Either<Failures, List<SpecialtyRecordEntryModel>>> getEntriesForPatient({
    required String patientId,
    MedicalSpecialty? specialty,
  }) async {
    final records = await localStore.getEntities(
      entityType: entityTypeName,
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    final list = <SpecialtyRecordEntryModel>[];
    for (final rec in records) {
      if (rec.isTombstone) continue;
      final model = SpecialtyRecordEntryModel.fromJson(rec.payload);
      if (model.patientId != patientId) continue;
      if (specialty != null && model.specialty != specialty) continue;
      list.add(model);
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Right(list);
  }

  Future<Either<Failures, SpecialtyRecordEntryModel>> saveEntry(
    SpecialtyRecordEntryModel entry,
  ) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();
    final id = entry.id.isNotEmpty
        ? entry.id
        : 'SRE-${now.microsecondsSinceEpoch}';

    final existing = await localStore.getEntity(
      localId: id,
      accountId: accountId,
      branchId: branchId,
    );
    final isCreate = existing == null || existing.isTombstone;
    final nextRevision = isCreate ? 1 : existing.localRevision + 1;
    final toSave = entry.copyWith(id: id, revision: nextRevision);

    final deps = <String>['patient:${toSave.patientId}'];
    if (toSave.visitId != null && toSave.visitId!.isNotEmpty) {
      deps.add('visit:${toSave.visitId}');
    }

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: id,
          entityType: entityTypeName,
          serverId: existing?.serverId,
          accountId: accountId,
          branchId: branchId,
          payload: toSave.toJson(),
          localRevision: nextRevision,
          syncStatus: SyncStatus.pending,
          isProvisional: !dataModeService.isOnline,
          isTombstone: false,
          createdAt: existing?.createdAt ?? toSave.createdAt,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_sre_${id}_${now.microsecondsSinceEpoch}',
          entityType: entityTypeName,
          localId: id,
          operation: isCreate
              ? OutboxOperationType.create
              : OutboxOperationType.update,
          payload: toSave.toJson(),
          previousPayload: isCreate ? null : existing.payload,
          baseRevision: existing?.localRevision ?? 1,
          dependencyRefs: deps,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    dataModeService.updatePendingOutboxCount(
      (await localStore.getPendingOutboxEntries()).length,
    );

    return Right(toSave);
  }

  Future<Either<Failures, Unit>> deleteEntry(String id) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();
    final existing = await localStore.getEntity(
      localId: id,
      accountId: accountId,
      branchId: branchId,
    );
    if (existing == null || existing.isTombstone) {
      return const Right(unit);
    }

    await localStore.runInTransaction((txn) async {
      txn.markTombstone(id);
      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_sre_del_${id}_${now.microsecondsSinceEpoch}',
          entityType: entityTypeName,
          localId: id,
          operation: OutboxOperationType.delete,
          payload: {'id': id, 'isTombstone': true},
          previousPayload: existing.payload,
          baseRevision: existing.localRevision,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    dataModeService.updatePendingOutboxCount(
      (await localStore.getPendingOutboxEntries()).length,
    );

    return const Right(unit);
  }
}
