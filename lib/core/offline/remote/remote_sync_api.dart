import '../models/outbox_entry.dart';

class SyncPushResult {
  final bool success;
  final String operationId;
  final String? serverId;
  final String? serverCursor;
  final int? confirmedRevision;
  final bool hasConflict;
  final Map<String, dynamic>? serverConflictVersion;
  final String? errorMessage;
  final bool isRetryable;

  const SyncPushResult({
    required this.success,
    required this.operationId,
    this.serverId,
    this.serverCursor,
    this.confirmedRevision,
    this.hasConflict = false,
    this.serverConflictVersion,
    this.errorMessage,
    this.isRetryable = true,
  });
}

class BatchPushResult {
  final bool success;
  final List<SyncPushResult> operationResults;
  final String? errorMessage;

  const BatchPushResult({
    required this.success,
    required this.operationResults,
    this.errorMessage,
  });

  SyncPushResult? getResultFor(String operationId) {
    for (final r in operationResults) {
      if (r.operationId == operationId) return r;
    }
    return null;
  }
}

class RemoteEntityChange {
  final String serverId;
  final String? localId;
  final String entityType;
  final int revision;
  final bool isDeleted;
  final Map<String, dynamic> payload;

  const RemoteEntityChange({
    required this.serverId,
    this.localId,
    required this.entityType,
    required this.revision,
    this.isDeleted = false,
    required this.payload,
  });
}

class SyncPullResult {
  final bool success;
  final String newCursor;
  final List<RemoteEntityChange> changes;
  final String? errorMessage;

  const SyncPullResult({
    required this.success,
    required this.newCursor,
    required this.changes,
    this.errorMessage,
  });
}

abstract class RemoteSyncApi {
  /// Pushes an outbox operation to the remote server.
  /// Server contract requires strict idempotency keyed by [entry.operationId].
  Future<SyncPushResult> pushOperation(OutboxEntry entry);

  /// Pushes a batch of outbox operations in a single round-trip.
  Future<BatchPushResult> pushBatch(List<OutboxEntry> operations);

  /// Pulls incremental changes since [cursor].
  /// [cursor] is an opaque server-issued string, never a wall-clock time.
  Future<SyncPullResult> pullChanges({
    required String entityType,
    String? cursor,
  });
}
