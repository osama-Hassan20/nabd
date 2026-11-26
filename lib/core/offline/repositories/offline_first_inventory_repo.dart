import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/local_entity_record.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/store/transactional_local_store.dart';
import 'package:eyadty/features/inventory/data/models/inventory_item_model.dart';
import 'package:eyadty/features/inventory/domain/repo/inventory_repo.dart';

class OfflineFirstInventoryRepo implements InventoryRepo {
  final TransactionalLocalStore localStore;
  final DataModeService dataModeService;
  final InventoryRepo remoteRepo;
  final String Function() getCurrentAccountId;
  final String Function() getCurrentBranchId;

  OfflineFirstInventoryRepo({
    required this.localStore,
    required this.dataModeService,
    required this.remoteRepo,
    required this.getCurrentAccountId,
    required this.getCurrentBranchId,
  });

  @override
  Future<Either<Failures, List<InventoryItemModel>>> getItems({
    String? query,
    String? category,
    bool onlyLowStock = false,
  }) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();

    final records = await localStore.getEntities(
      entityType: 'inventory',
      accountId: accountId,
      branchId: branchId,
    );

    final localItems = <String, InventoryItemModel>{};
    for (final rec in records) {
      if (!rec.isTombstone) {
        try {
          final item = InventoryItemModel.fromJson(rec.payload);
          localItems[item.id] = item;
        } catch (_) {}
      }
    }

    // Merge with remote / seeded mock items
    final remoteRes = await remoteRepo.getItems(
      query: query,
      category: category,
      onlyLowStock: onlyLowStock,
    );

    remoteRes.fold((_) {}, (items) {
      for (final r in items) {
        final existing = records.where((rec) => rec.localId == r.id).firstOrNull;
        if (existing != null && existing.isTombstone) {
          continue; // Item was deleted locally
        }
        if (!localItems.containsKey(r.id)) {
          localItems[r.id] = r;
        }
      }
    });

    var result = localItems.values.toList();
    if (category != null && category.isNotEmpty && category != 'all') {
      result = result.where((i) => i.category == category).toList();
    }
    if (onlyLowStock) {
      result = result.where((i) => i.isLowStock || i.isOutOfStock).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((i) =>
          i.name.toLowerCase().contains(q) || i.code.toLowerCase().contains(q)).toList();
    }

    return Right(result);
  }

  @override
  Future<Either<Failures, InventoryItemModel>> addItem(InventoryItemModel item) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();
    final isProvisional = !dataModeService.isOnline;

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: item.id,
          entityType: 'inventory',
          accountId: accountId,
          branchId: branchId,
          payload: item.toJson(),
          localRevision: 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_inv_add_${item.id}_${now.microsecondsSinceEpoch}',
          entityType: 'inventory',
          localId: item.id,
          operation: OutboxOperationType.create,
          payload: item.toJson(),
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.addItem(item);
    } catch (_) {}

    return Right(item);
  }

  @override
  Future<Either<Failures, InventoryItemModel>> updateItem(InventoryItemModel item) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();
    final isProvisional = !dataModeService.isOnline;

    final existing = await localStore.getEntity(
      localId: item.id,
      accountId: accountId,
      branchId: branchId,
    );

    final baseRev = existing?.localRevision ?? 1;

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: item.id,
          entityType: 'inventory',
          accountId: accountId,
          branchId: branchId,
          payload: item.toJson(),
          localRevision: baseRev + 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_inv_upd_${item.id}_${now.microsecondsSinceEpoch}',
          entityType: 'inventory',
          localId: item.id,
          operation: OutboxOperationType.update,
          payload: item.toJson(),
          previousPayload: existing?.payload,
          baseRevision: baseRev,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.updateItem(item);
    } catch (_) {}

    return Right(item);
  }

  @override
  Future<Either<Failures, String>> deleteItem(String id) async {
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
          operationId: 'op_inv_del_${id}_${now.microsecondsSinceEpoch}',
          entityType: 'inventory',
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
      await remoteRepo.deleteItem(id);
    } catch (_) {}

    return Right(id);
  }

  @override
  Future<Either<Failures, InventoryItemModel>> recordRestock({
    required String itemId,
    required int quantity,
    required String performedBy,
    String? supplier,
    String? notes,
  }) async {
    // 1. Get current item
    final itemsRes = await getItems();
    InventoryItemModel? currentItem;
    itemsRes.fold((_) {}, (items) {
      currentItem = items.where((i) => i.id == itemId).firstOrNull;
    });

    if (currentItem == null) {
      return const Left(ServerFailure(errMessage: 'item_not_found'));
    }

    final updated = currentItem!.copyWith(
      currentStock: currentItem!.currentStock + quantity,
      lastRestockDate: DateTime.now(),
    );

    return updateItem(updated);
  }

  @override
  Future<Either<Failures, InventoryItemModel>> recordConsumption({
    required String itemId,
    required int quantity,
    required String performedBy,
    String? notes,
  }) async {
    final itemsRes = await getItems();
    InventoryItemModel? currentItem;
    itemsRes.fold((_) {}, (items) {
      currentItem = items.where((i) => i.id == itemId).firstOrNull;
    });

    if (currentItem == null) {
      return const Left(ServerFailure(errMessage: 'item_not_found'));
    }

    final newStock = (currentItem!.currentStock - quantity).clamp(0, 999999);
    final updated = currentItem!.copyWith(
      currentStock: newStock,
      lastConsumedDate: DateTime.now(),
    );

    return updateItem(updated);
  }

  @override
  Future<Either<Failures, List<InventoryTransactionModel>>> getTransactions({
    String? itemId,
  }) =>
      remoteRepo.getTransactions(itemId: itemId);
}
