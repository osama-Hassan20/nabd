import 'dart:async';
import 'dart:convert';
import 'package:eyadty/core/storage/cache_helper.dart';
import '../data_mode_service.dart';
import '../models/conflict_record.dart';
import '../models/local_entity_record.dart';
import '../models/outbox_entry.dart';
import '../models/sync_status.dart';
import 'transactional_local_store.dart';

/// Exception thrown when persistence to underlying storage fails.
class StoragePersistenceException implements Exception {
  final String message;
  final Object? cause;

  const StoragePersistenceException(this.message, [this.cause]);

  @override
  String toString() => 'StoragePersistenceException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Exception thrown when persisted store data is corrupt or unparsable.
class StorageCorruptionException implements Exception {
  final String message;
  final String backupKey;
  final Object? cause;

  const StorageCorruptionException(this.message, {required this.backupKey, this.cause});

  @override
  String toString() => 'StorageCorruptionException: $message (Backup: $backupKey)';
}

typedef StorageWriter = Future<void> Function(String key, String value);
typedef StorageReader = String? Function(String key);
typedef StorageRemover = Future<void> Function(String key);

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
  static const String snapshotKey = 'eyadty_offline_store_v1';
  static const int currentSchemaVersion = 1;

  Map<String, LocalEntityRecord> _entities = {};
  Map<String, OutboxEntry> _outbox = {};
  Map<String, ConflictRecord> _conflicts = {};
  final Map<String, String> _syncCursors = {};

  final DataModeService? dataModeService;
  final bool persistToStorage;

  final StorageWriter _writer;
  final StorageReader _reader;
  final StorageRemover _remover;

  String? lastCorruptionBackupKey;

  InMemoryTransactionalStore({
    this.dataModeService,
    this.persistToStorage = true,
    StorageWriter? storageWriter,
    StorageReader? storageReader,
    StorageRemover? storageRemover,
  })  : _writer = storageWriter ?? _defaultWriter,
        _reader = storageReader ?? _defaultReader,
        _remover = storageRemover ?? _defaultRemover {
    if (persistToStorage) {
      _loadFromPersistence();
    }
  }

  static Future<void> _defaultWriter(String key, String value) async {
    await AppSharedPreferences.setString(key: key, value: value);
  }

  static String? _defaultReader(String key) {
    try {
      return AppSharedPreferences.getString(key: key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _defaultRemover(String key) async {
    try {
      await AppSharedPreferences.remove(key: key);
    } catch (_) {}
  }

  /// Reloads from storage. Can be called by tests or after a re-initialization.
  void reloadFromPersistence() {
    _loadFromPersistence();
  }

  void _loadFromPersistence() {
    final raw = _reader(snapshotKey);
    if (raw == null || raw.trim().isEmpty) {
      _tryMigrateLegacyStorage();
      _notifyOutboxCount();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw FormatException('Snapshot root must be a JSON Map, got ${decoded.runtimeType}');
      }
      final map = Map<String, dynamic>.from(decoded);

      final version = map['schemaVersion'] as int? ?? 1;
      final migratedMap = _migrateStore(map, version, currentSchemaVersion);

      final entitiesMap = migratedMap['entities'] as Map? ?? {};
      final outboxMap = migratedMap['outbox'] as Map? ?? {};
      final conflictsMap = migratedMap['conflicts'] as Map? ?? {};
      final cursorsMap = migratedMap['syncCursors'] as Map? ?? {};

      _entities = entitiesMap.map((k, v) => MapEntry(
            k as String,
            LocalEntityRecord.fromJson(Map<String, dynamic>.from(v as Map)),
          ));

      _outbox = outboxMap.map((k, v) => MapEntry(
            k as String,
            OutboxEntry.fromJson(Map<String, dynamic>.from(v as Map)),
          ));

      _conflicts = conflictsMap.map((k, v) => MapEntry(
            k as String,
            ConflictRecord.fromJson(Map<String, dynamic>.from(v as Map)),
          ));

      _syncCursors.clear();
      cursorsMap.forEach((k, v) {
        if (v != null) _syncCursors[k.toString()] = v.toString();
      });

      _notifyOutboxCount();
    } catch (e) {
      // Create backup of corrupted store data
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupKey = 'eyadty_offline_store_corrupted_$timestamp';
      try {
        _writer(backupKey, raw);
      } catch (_) {}

      lastCorruptionBackupKey = backupKey;
      throw StorageCorruptionException(
        'Corrupted offline store detected. A backup was saved to "$backupKey". Reason: $e',
        backupKey: backupKey,
        cause: e,
      );
    }
  }

  void _tryMigrateLegacyStorage() {
    try {
      final legacyEntitiesRaw = _reader('eyadty_offline_entities');
      final legacyOutboxRaw = _reader('eyadty_offline_outbox');
      final legacyConflictsRaw = _reader('eyadty_offline_conflicts');

      bool foundLegacy = false;

      if (legacyEntitiesRaw != null && legacyEntitiesRaw.isNotEmpty) {
        final decoded = jsonDecode(legacyEntitiesRaw);
        if (decoded is Map) {
          _entities = decoded.map((k, v) => MapEntry(
                k as String,
                LocalEntityRecord.fromJson(Map<String, dynamic>.from(v as Map)),
              ));
          foundLegacy = true;
        }
      }

      if (legacyOutboxRaw != null && legacyOutboxRaw.isNotEmpty) {
        final decoded = jsonDecode(legacyOutboxRaw);
        if (decoded is Map) {
          _outbox = decoded.map((k, v) => MapEntry(
                k as String,
                OutboxEntry.fromJson(Map<String, dynamic>.from(v as Map)),
              ));
          foundLegacy = true;
        }
      }

      if (legacyConflictsRaw != null && legacyConflictsRaw.isNotEmpty) {
        final decoded = jsonDecode(legacyConflictsRaw);
        if (decoded is Map) {
          _conflicts = decoded.map((k, v) => MapEntry(
                k as String,
                ConflictRecord.fromJson(Map<String, dynamic>.from(v as Map)),
              ));
          foundLegacy = true;
        }
      }

      if (foundLegacy) {
        // Upgrade to single atomic snapshot
        _saveToPersistence();
        // Remove legacy keys
        _remover('eyadty_offline_entities');
        _remover('eyadty_offline_outbox');
        _remover('eyadty_offline_conflicts');
      }
    } catch (_) {}
  }

  Map<String, dynamic> _migrateStore(
    Map<String, dynamic> doc,
    int fromVersion,
    int toVersion,
  ) {
    final migrated = Map<String, dynamic>.from(doc);
    for (int v = fromVersion; v < toVersion; v++) {
      // Incremental migration steps if future versions are added
      if (v == 1) {
        // Example: future migration from 1 to 2
      }
    }
    migrated['schemaVersion'] = toVersion;
    return migrated;
  }

  Future<void> _saveToPersistence() async {
    if (!persistToStorage) {
      _notifyOutboxCount();
      return;
    }

    final doc = {
      'schemaVersion': currentSchemaVersion,
      'updatedAt': DateTime.now().toIso8601String(),
      'entities': _entities.map((k, v) => MapEntry(k, v.toJson())),
      'outbox': _outbox.map((k, v) => MapEntry(k, v.toJson())),
      'conflicts': _conflicts.map((k, v) => MapEntry(k, v.toJson())),
      'syncCursors': _syncCursors,
    };

    final serialized = jsonEncode(doc);
    await _writer(snapshotKey, serialized);
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
    // 1. Snapshot live state before transaction
    final previousEntities = Map<String, LocalEntityRecord>.from(_entities);
    final previousOutbox = Map<String, OutboxEntry>.from(_outbox);
    final previousConflicts = Map<String, ConflictRecord>.from(_conflicts);

    // 2. Working copy for transaction action
    final workingEntities = Map<String, LocalEntityRecord>.from(_entities);
    final workingOutbox = Map<String, OutboxEntry>.from(_outbox);
    final workingConflicts = Map<String, ConflictRecord>.from(_conflicts);

    final txn = _InMemoryStoreTransaction(
      entitySnapshot: workingEntities,
      outboxSnapshot: workingOutbox,
      conflictSnapshot: workingConflicts,
    );

    final T result;
    try {
      result = await action(txn);
    } catch (e) {
      // Action threw: discard working copies, state remains unchanged
      rethrow;
    }

    // 3. Tentatively update in-memory state
    _entities = workingEntities;
    _outbox = workingOutbox;
    _conflicts = workingConflicts;

    // 4. Atomically persist to storage BEFORE reporting success
    try {
      await _saveToPersistence();
    } catch (storageError) {
      // Storage failed: ROLLBACK in-memory state to exact previous state!
      _entities = previousEntities;
      _outbox = previousOutbox;
      _conflicts = previousConflicts;
      _notifyOutboxCount();

      throw StoragePersistenceException(
        'Transaction failed during persistence: $storageError',
        storageError,
      );
    }

    return result;
  }

  @override
  Future<LocalEntityRecord?> getEntity({
    required String localId,
    required String accountId,
    required String branchId,
  }) async {
    final record = _entities[localId];
    if (record == null) return null;

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
            e.status == OutboxStatus.pending ||
            e.status == OutboxStatus.inFlight)
        .toList();

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
      await _saveToPersistence();
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

    _outbox[operationId] = entry.copyWith(
      status: OutboxStatus.acknowledged,
    );

    final entity = _entities[entry.localId];
    if (entity != null) {
      _entities[entry.localId] = entity.copyWith(
        serverId: serverId ?? entity.serverId,
        serverCursor: serverCursor ?? entity.serverCursor,
        localRevision: confirmedRevision ?? entity.localRevision,
        syncStatus: SyncStatus.synced,
        isProvisional: false,
        updatedAt: DateTime.now(),
      );
    }
    await _saveToPersistence();
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
    await _saveToPersistence();
  }

  @override
  Future<void> clear() async {
    _entities.clear();
    _outbox.clear();
    _conflicts.clear();
    _syncCursors.clear();
    await _saveToPersistence();
  }
}
