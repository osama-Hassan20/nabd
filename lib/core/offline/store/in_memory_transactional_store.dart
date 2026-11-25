import 'dart:async';
import 'dart:convert';
import 'package:eyadty/core/storage/cache_helper.dart';
import '../data_mode_service.dart';
import '../models/conflict_record.dart';
import '../models/local_entity_record.dart';
import '../models/outbox_entry.dart';
import '../models/sync_status.dart';
import 'transactional_local_store.dart';

class _InMemoryStoreTransaction implements StoreTransaction {
  final Map<String, LocalEntityRecord> entitySnapshot;
  final Map<String, OutboxEntry> outboxSnapshot;
  final Map<String, ConflictRecord> conflictSnapshot;

  _InMemoryStoreTransaction({
    required this.entitySnapshot,
    required this.outboxSnapshot,
    required this.conflictSnapshot,
  });

  @override
  LocalEntityRecord? getEntity(String localId) => entitySnapshot[localId];

  @override
  void upsertEntity(LocalEntityRecord record) {
    entitySnapshot[record.localId] = record;
  }

  @override
  void insertOutbox(OutboxEntry entry) {
    outboxSnapshot[entry.operationId] = entry;
  }

  @override
  void deleteEntity(String localId) {
    entitySnapshot.remove(localId);
  }

  @override
  void markTombstone(String localId) {
    final existing = entitySnapshot[localId];
    if (existing != null) {
      entitySnapshot[localId] = existing.copyWith(
        isTombstone: true,
        syncStatus: SyncStatus.synced,
        updatedAt: DateTime.now(),
      );
    } else {
      entitySnapshot[localId] = LocalEntityRecord(
        localId: localId,
        entityType: 'unknown',
        accountId: 'default',
        branchId: 'branch_1',
        payload: const {},
        isTombstone: true,
        syncStatus: SyncStatus.synced,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  void insertConflict(ConflictRecord conflict) {
    conflictSnapshot[conflict.conflictId] = conflict;
  }

  @override
  void resolveConflict(String conflictId, Map<String, dynamic> resolvedPayload) {
    final existing = conflictSnapshot[conflictId];
    if (existing != null) {
      conflictSnapshot[conflictId] = existing.copyWith(
        isResolved: true,
        resolvedPayload: resolvedPayload,
      );
    }
  }
}

class InMemoryTransactionalStore implements TransactionalLocalStore {
  Map<String, LocalEntityRecord> _entities = {};
  Map<String, OutboxEntry> _outbox = {};
  Map<String, ConflictRecord> _conflicts = {};
  final Map<String, String> _syncCursors = {};

  final DataModeService? dataModeService;
  final bool persistToStorage;

  InMemoryTransactionalStore({
    this.dataModeService,
    this.persistToStorage = true,
  }) {
    if (persistToStorage) {
      _loadFromPersistence();
    }
  }

  void _loadFromPersistence() {
    try {
      final entitiesRaw =
          AppSharedPreferences.getString(key: 'eyadty_offline_entities');
      if (entitiesRaw != null && entitiesRaw.isNotEmpty) {
        final Map decoded = jsonDecode(entitiesRaw) as Map;
        _entities = decoded.map((k, v) => MapEntry(
            k as String,
            LocalEntityRecord.fromJson(
                Map<String, dynamic>.from(v as Map))));
      }

      final outboxRaw =
          AppSharedPreferences.getString(key: 'eyadty_offline_outbox');
      if (outboxRaw != null && outboxRaw.isNotEmpty) {
        final Map decoded = jsonDecode(outboxRaw) as Map;
        _outbox = decoded.map((k, v) => MapEntry(
            k as String,
            OutboxEntry.fromJson(Map<String, dynamic>.from(v as Map))));
      }

      final conflictsRaw =
          AppSharedPreferences.getString(key: 'eyadty_offline_conflicts');
      if (conflictsRaw != null && conflictsRaw.isNotEmpty) {
        final Map decoded = jsonDecode(conflictsRaw) as Map;
        _conflicts = decoded.map((k, v) => MapEntry(
            k as String,
            ConflictRecord.fromJson(
                Map<String, dynamic>.from(v as Map))));
      }

      _notifyOutboxCount();
    } catch (_) {}
  }

  void _saveToPersistence() {
    if (!persistToStorage) {
      _notifyOutboxCount();
      return;
    }
    try {
      final entitiesJson =
          jsonEncode(_entities.map((k, v) => MapEntry(k, v.toJson())));
      AppSharedPreferences.setString(
          key: 'eyadty_offline_entities', value: entitiesJson);

      final outboxJson =
          jsonEncode(_outbox.map((k, v) => MapEntry(k, v.toJson())));
      AppSharedPreferences.setString(
          key: 'eyadty_offline_outbox', value: outboxJson);

      final conflictsJson =
          jsonEncode(_conflicts.map((k, v) => MapEntry(k, v.toJson())));
      AppSharedPreferences.setString(
          key: 'eyadty_offline_conflicts', value: conflictsJson);
    } catch (_) {}

    _notifyOutboxCount();
  }

  void _notifyOutboxCount() {
    final pendingCount = _outbox.values
        .where((e) =>
            e.status == OutboxStatus.pending ||
            e.status == OutboxStatus.inFlight)
        .length;
    dataModeService?.updatePendingOutboxCount(pendingCount);
  }

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(StoreTransaction txn) action,
  ) async {
    // 1. Create a full working snapshot of state
    final entitySnapshot = Map<String, LocalEntityRecord>.from(_entities);
    final outboxSnapshot = Map<String, OutboxEntry>.from(_outbox);
    final conflictSnapshot = Map<String, ConflictRecord>.from(_conflicts);

    final txn = _InMemoryStoreTransaction(
      entitySnapshot: entitySnapshot,
      outboxSnapshot: outboxSnapshot,
      conflictSnapshot: conflictSnapshot,
    );

    try {
      // 2. Execute caller transaction block
      final result = await action(txn);

      // 3. Atomically commit working snapshot
      _entities = entitySnapshot;
      _outbox = outboxSnapshot;
      _conflicts = conflictSnapshot;

      // 4. Persist to storage and notify mode service
      _saveToPersistence();

      return result;
    } catch (e) {
      // Rollback: snapshot is discarded and live state remains unaltered
      rethrow;
    }
  }

  @override
  Future<LocalEntityRecord?> getEntity({
    required String localId,
    required String accountId,
    required String branchId,
  }) async {
    final record = _entities[localId];
    if (record == null) return null;

    // Strict security and isolation check
    if (record.accountId != accountId || record.branchId != branchId) {
      return null;
    }

    return record;
  }

  @override
  Future<List<LocalEntityRecord>> getEntities({
    required String entityType,
    required String accountId,
    required String branchId,
    bool includeTombstones = false,
  }) async {
    return _entities.values.where((r) {
      if (r.entityType != entityType) return false;
      if (r.accountId != accountId) return false;
      if (r.branchId != branchId) return false;
      if (!includeTombstones && r.isTombstone) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<OutboxEntry>> getPendingOutboxEntries({int limit = 50}) async {
    final pending = _outbox.values
        .where((e) =>
            e.status == OutboxStatus.pending || e.status == OutboxStatus.inFlight)
        .toList();

    // Order chronologically
    pending.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (pending.length > limit) {
      return pending.sublist(0, limit);
    }
    return pending;
  }

  @override
  Future<List<OutboxEntry>> getAllOutboxEntries() async {
    final list = _outbox.values.toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<OutboxEntry?> getOutboxEntry(String operationId) async {
    return _outbox[operationId];
  }

  @override
  Future<void> updateOutboxStatus({
    required String operationId,
    required OutboxStatus status,
    String? lastError,
  }) async {
    final entry = _outbox[operationId];
    if (entry != null) {
      _outbox[operationId] = entry.copyWith(
        status: status,
        lastError: lastError,
        attemptCount: entry.attemptCount + 1,
      );
      _saveToPersistence();
    }
  }

  @override
  Future<void> acknowledgeOutboxOperation({
    required String operationId,
    String? serverId,
    String? serverCursor,
    int? confirmedRevision,
  }) async {
    final entry = _outbox[operationId];
    if (entry == null) return;

    // Mark outbox entry as acknowledged
    _outbox[operationId] = entry.copyWith(
      status: OutboxStatus.acknowledged,
    );

    // Update corresponding entity record
    final entity = _entities[entry.localId];
    if (entity != null) {
      _entities[entry.localId] = entity.copyWith(
        serverId: serverId ?? entity.serverId,
        serverCursor: serverCursor ?? entity.serverCursor,
        localRevision: confirmedRevision ?? entity.localRevision,
        syncStatus: SyncStatus.synced,
        isProvisional: false, // Confirmed by server!
        updatedAt: DateTime.now(),
      );
    }
    _saveToPersistence();
  }

  @override
  Future<List<ConflictRecord>> getUnresolvedConflicts() async {
    return _conflicts.values.where((c) => !c.isResolved).toList();
  }

  @override
  Future<String?> getSyncCursor(String entityType) async {
    return _syncCursors[entityType];
  }

  @override
  Future<void> setSyncCursor(String entityType, String cursor) async {
    _syncCursors[entityType] = cursor;
  }

  @override
  Future<void> clear() async {
    _entities.clear();
    _outbox.clear();
    _conflicts.clear();
    _syncCursors.clear();
    _saveToPersistence();
  }
}
