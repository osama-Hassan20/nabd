import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../features/medical_catalogs/data/models/enums/medical_catalog_kind_enum.dart';
import '../../../features/medical_catalogs/data/models/medical_catalog_entry_model.dart';
import '../../../features/medical_catalogs/domain/repo/medical_catalogs_repo.dart';
import '../data_mode_service.dart';
import '../models/local_entity_record.dart';
import '../models/outbox_entry.dart';
import '../models/sync_status.dart';
import '../store/transactional_local_store.dart';

class OfflineFirstMedicalCatalogsRepo implements MedicalCatalogsRepo {
  final TransactionalLocalStore localStore;
  final DataModeService dataModeService;
  final MedicalCatalogsRepo remoteRepo;
  final String Function() getCurrentAccountId;
  final String Function() getCurrentBranchId;

  OfflineFirstMedicalCatalogsRepo({
    required this.localStore,
    required this.dataModeService,
    required this.remoteRepo,
    required this.getCurrentAccountId,
    required this.getCurrentBranchId,
  });

  @override
  Future<Either<Failures, List<MedicalCatalogEntryModel>>> getEntries({
    required MedicalCatalogKindEnum kind,
    String? query,
    String? category,
  }) async {
    final records = await localStore.getEntities(
      entityType: 'medical_catalog_${kind.name}',
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    final localEntries = <String, MedicalCatalogEntryModel>{};
    final tombstoneIds = <String>{};

    for (final rec in records) {
      if (rec.isTombstone) {
        tombstoneIds.add(rec.localId);
      } else {
        try {
          final entry = MedicalCatalogEntryModel.fromJson(rec.payload);
          localEntries[entry.id] = entry;
        } catch (_) {}
      }
    }

    // Remote seeds
    final remoteRes = await remoteRepo.getEntries(
      kind: kind,
      query: null,
      category: null,
    );

    remoteRes.fold((_) {}, (items) {
      for (final item in items) {
        if (!tombstoneIds.contains(item.id) && !localEntries.containsKey(item.id)) {
          localEntries[item.id] = item;
        }
      }
    });

    var results = localEntries.values.toList();

    if (category != null && category.isNotEmpty && category != 'الكل') {
      results = results.where((e) => e.category == category).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results.where((e) {
        final nameMatch = e.name.toLowerCase().contains(q);
        final codeMatch = e.code.toLowerCase().contains(q);
        final catMatch = e.category.toLowerCase().contains(q);
        return nameMatch || codeMatch || catMatch;
      }).toList();
    }

    return Right(results);
  }

  @override
  Future<Either<Failures, MedicalCatalogEntryModel>> addEntry(
    MedicalCatalogEntryModel entry,
  ) async {
    final now = DateTime.now();
    final entryId = entry.id.isNotEmpty
        ? entry.id
        : 'CAT-${entry.kind.name.toUpperCase()}-${now.millisecondsSinceEpoch}';

    final toSave = entry.copyWith(
      id: entryId,
      createdAt: entry.createdAt,
    );

    await _persistEntryAtomic(
      entry: toSave,
      operation: OutboxOperationType.create,
    );

    // Mirror to remote mock
    try {
      await remoteRepo.addEntry(toSave);
    } catch (_) {}

    return Right(toSave);
  }

  @override
  Future<Either<Failures, MedicalCatalogEntryModel>> updateEntry(
    MedicalCatalogEntryModel entry,
  ) async {
    await _persistEntryAtomic(
      entry: entry,
      operation: OutboxOperationType.update,
    );

    try {
      await remoteRepo.updateEntry(entry);
    } catch (_) {}

    return Right(entry);
  }

  @override
  Future<Either<Failures, bool>> deleteEntry(String id) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();

    // Check all kinds or delete tombstone in localStore
    for (final kind in MedicalCatalogKindEnum.values) {
      final entityType = 'medical_catalog_${kind.name}';
      final existing = await localStore.getEntity(
        localId: id,
        accountId: accountId,
        branchId: branchId,
      );
      if (existing != null) {
        await localStore.runInTransaction((txn) async {
          txn.markTombstone(id);
          txn.insertOutbox(
            OutboxEntry(
              operationId: 'op_cat_del_${id}_${now.microsecondsSinceEpoch}',
              entityType: entityType,
              localId: id,
              operation: OutboxOperationType.delete,
              payload: {'id': id},
              baseRevision: 1,
              createdAt: now,
              status: OutboxStatus.pending,
            ),
          );
        });
        break;
      }
    }

    try {
      await remoteRepo.deleteEntry(id);
    } catch (_) {}

    return const Right(true);
  }

  @override
  Future<Either<Failures, MedicalCatalogEntryModel>> toggleActive({
    required String id,
    required bool isActive,
  }) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();

    for (final _ in MedicalCatalogKindEnum.values) {
      final existing = await localStore.getEntity(
        localId: id,
        accountId: accountId,
        branchId: branchId,
      );
      if (existing != null && !existing.isTombstone) {
        final model = MedicalCatalogEntryModel.fromJson(existing.payload);
        final updated = model.copyWith(isActive: isActive);
        await updateEntry(updated);
        return Right(updated);
      }
    }

    // Fallback to remote toggle
    return remoteRepo.toggleActive(id: id, isActive: isActive);
  }

  Future<void> _persistEntryAtomic({
    required MedicalCatalogEntryModel entry,
    required OutboxOperationType operation,
  }) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();
    final isProvisional = !dataModeService.isOnline;
    final entityType = 'medical_catalog_${entry.kind.name}';

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: entry.id,
          entityType: entityType,
          accountId: accountId,
          branchId: branchId,
          payload: entry.toJson(),
          localRevision: 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: entry.createdAt,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_cat_${entry.id}_${now.microsecondsSinceEpoch}',
          entityType: entityType,
          localId: entry.id,
          operation: operation,
          payload: entry.toJson(),
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });
  }
}
