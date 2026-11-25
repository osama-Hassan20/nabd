import '../models/conflict_record.dart';
import '../models/local_entity_record.dart';
import '../models/outbox_entry.dart';
import '../models/sync_status.dart';

abstract class StoreTransaction {
  LocalEntityRecord? getEntity(String localId);
  void upsertEntity(LocalEntityRecord record);
  void insertOutbox(OutboxEntry entry);
  void deleteEntity(String localId);
  void markTombstone(String localId);
  void insertConflict(ConflictRecord conflict);
  void resolveConflict(String conflictId, Map<String, dynamic> resolvedPayload);
}

abstract class TransactionalLocalStore {
  /// Runs [action] within an atomic transaction.
  /// If [action] throws any exception or fails, all writes in the transaction are rolled back
  /// and neither the entity row nor the outbox entry is persisted.
  Future<T> runInTransaction<T>(
    Future<T> Function(StoreTransaction txn) action,
  );

  /// Retrieves an entity by its localId scoped by [accountId] and [branchId].
  Future<LocalEntityRecord?> getEntity({
    required String localId,
    required String accountId,
    required String branchId,
  });

  /// Lists entities of a given [entityType] scoped by [accountId] and [branchId].
  Future<List<LocalEntityRecord>> getEntities({
    required String entityType,
    required String accountId,
    required String branchId,
    bool includeTombstones = false,
  });

  /// Retrieves pending outbox operations, ordered by createdAt, respecting dependencies.
  Future<List<OutboxEntry>> getPendingOutboxEntries({int limit = 50});

  /// Retrieves all outbox operations (including blocked, failed, acknowledged).
  Future<List<OutboxEntry>> getAllOutboxEntries();

  /// Retrieves a specific outbox entry by [operationId].
  Future<OutboxEntry?> getOutboxEntry(String operationId);

  /// Updates status of an outbox entry (e.g. inFlight, acknowledged, failed, blocked).
  Future<void> updateOutboxStatus({
    required String operationId,
    required OutboxStatus status,
    String? lastError,
  });

  /// Marks an outbox entry acknowledged and updates entity syncStatus and serverId/serverCursor.
  Future<void> acknowledgeOutboxOperation({
    required String operationId,
    String? serverId,
    String? serverCursor,
    int? confirmedRevision,
  });

  /// Lists unresolved conflicts.
  Future<List<ConflictRecord>> getUnresolvedConflicts();

  /// Reads/writes sync metadata cursors.
  Future<String?> getSyncCursor(String entityType);
  Future<void> setSyncCursor(String entityType, String cursor);

  /// Clears store (for test resets or account purge).
  Future<void> clear();
}
