import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/outbox_entry.dart';
import 'remote_sync_api.dart';

/// Fake Remote Sync API
///
/// **DEMO AND TEST ONLY** - Simulates remote server sync behaviors for testing
/// and demonstration in the absence of a real backend.
/// Enforces idempotent replays by [operationId], cursor emission, and failure modes.
class FakeRemoteSyncApi implements RemoteSyncApi {
  // Durable simulated server storage keyed by operationId (Idempotency storage)
  final Map<String, SyncPushResult> _processedOperations = {};

  // Simulated server entities: entityType -> (serverId -> payload)
  final Map<String, Map<String, RemoteEntityChange>> _serverDatabase = {};
  final Map<String, String> _customOperationFailures = {};

  int _cursorSequence = 100;

  // Simulation flags for testing
  bool simulateTimeout = false;
  bool simulateIntermittentFailure = false;
  bool simulateLostAck = false;
  bool simulateConflict = false;
  bool simulatePermanentFailure = false;

  int pushCallCount = 0;
  int pullCallCount = 0;

  @override
  Future<SyncPushResult> pushOperation(OutboxEntry entry) async {
    pushCallCount++;

    if (simulateTimeout) {
      throw TimeoutException('Simulated remote sync timeout');
    }

    if (simulatePermanentFailure) {
      return SyncPushResult(
        success: false,
        operationId: entry.operationId,
        errorMessage: 'Validation failed: Invalid clinical schema (422)',
        isRetryable: false,
      );
    }

    if (simulateIntermittentFailure && pushCallCount.isOdd) {
      return SyncPushResult(
        success: false,
        operationId: entry.operationId,
        errorMessage: 'Temporary gateway 503 error',
        isRetryable: true,
      );
    }

    // 1. Idempotency Check: If already processed, return the exact stored result
    if (_processedOperations.containsKey(entry.operationId)) {
      return _processedOperations[entry.operationId]!;
    }

    // 2. Conflict Simulation
    if (simulateConflict) {
      final conflictResult = SyncPushResult(
        success: false,
        operationId: entry.operationId,
        hasConflict: true,
        serverConflictVersion: {
          'id': entry.localId,
          'version': entry.baseRevision + 5,
          'conflictField': 'Modified on server by Dr. Sameh',
        },
        errorMessage: 'Version conflict: Record was updated remotely',
        isRetryable: false,
      );
      _processedOperations[entry.operationId] = conflictResult;
      return conflictResult;
    }

    // 3. Process operation on simulated server
    final serverId = 'SRV-${entry.localId}';
    final confirmedRevision = entry.baseRevision + 1;
    final serverCursor = 'cursor_${_cursorSequence++}';

    // Store in simulated server database
    _serverDatabase.putIfAbsent(entry.entityType, () => {});
    _serverDatabase[entry.entityType]![serverId] = RemoteEntityChange(
      serverId: serverId,
      localId: entry.localId,
      entityType: entry.entityType,
      revision: confirmedRevision,
      isDeleted: entry.operation.name == 'delete',
      payload: entry.payload,
    );

    final successResult = SyncPushResult(
      success: true,
      operationId: entry.operationId,
      serverId: serverId,
      serverCursor: serverCursor,
      confirmedRevision: confirmedRevision,
    );

    // Persist result durably against operationId
    _processedOperations[entry.operationId] = successResult;

    // 4. Lost ACK Simulation: Server committed change, but connection drops before returning
    if (simulateLostAck) {
      simulateLostAck = false; // Trigger once
      throw Exception('Network connection dropped after server committed operation');
    }

    return successResult;
  }

  @override
  Future<BatchPushResult> pushBatch(List<OutboxEntry> operations) async {
    pushCallCount++;

    if (simulateTimeout) {
      throw TimeoutException('Simulated remote sync timeout during batch push');
    }

    final results = <SyncPushResult>[];
    final failedEntitiesInBatch = <String>{};

    for (final entry in operations) {
      // 1. Idempotency Check: return stored result if already processed
      if (_processedOperations.containsKey(entry.operationId)) {
        results.add(_processedOperations[entry.operationId]!);
        continue;
      }

      // 2. Dependency Check: if any prerequisite failed, skip with 'skipped_dependency_failed'
      final hasFailedDependency = entry.dependencyRefs.any(
        (dep) => failedEntitiesInBatch.contains(dep),
      );

      if (hasFailedDependency) {
        final skipResult = SyncPushResult(
          success: false,
          operationId: entry.operationId,
          errorMessage: 'skipped_dependency_failed',
          isRetryable: false,
        );
        _processedOperations[entry.operationId] = skipResult;
        failedEntitiesInBatch.add('${entry.entityType}:${entry.localId}');
        results.add(skipResult);
        continue;
      }

      // 3. Custom simulated failure
      if (_customOperationFailures.containsKey(entry.operationId)) {
        final failResult = SyncPushResult(
          success: false,
          operationId: entry.operationId,
          errorMessage: _customOperationFailures[entry.operationId],
          isRetryable: false,
        );
        _processedOperations[entry.operationId] = failResult;
        failedEntitiesInBatch.add('${entry.entityType}:${entry.localId}');
        results.add(failResult);
        continue;
      }

      // 4. Permanent failure simulation
      if (simulatePermanentFailure) {
        final permFailResult = SyncPushResult(
          success: false,
          operationId: entry.operationId,
          errorMessage: 'Validation failed: Invalid clinical schema (422)',
          isRetryable: false,
        );
        _processedOperations[entry.operationId] = permFailResult;
        failedEntitiesInBatch.add('${entry.entityType}:${entry.localId}');
        results.add(permFailResult);
        continue;
      }

      // 5. Conflict Simulation / Base revision check
      final serverTable = _serverDatabase[entry.entityType];
      RemoteEntityChange? existingServerEntity;
      if (serverTable != null) {
        for (final item in serverTable.values) {
          if (item.localId == entry.localId || item.serverId == entry.localId || item.serverId == 'SRV-${entry.localId}') {
            existingServerEntity = item;
            break;
          }
        }
      }

      if (simulateConflict ||
          (existingServerEntity != null && existingServerEntity.revision > entry.baseRevision)) {
        final conflictResult = SyncPushResult(
          success: false,
          operationId: entry.operationId,
          hasConflict: true,
          serverConflictVersion: existingServerEntity != null
              ? {
                  'id': existingServerEntity.serverId,
                  'revision': existingServerEntity.revision,
                  'payload': existingServerEntity.payload,
                  'conflictField': 'Modified on server by Dr. Sameh',
                }
              : {
                  'id': entry.localId,
                  'version': entry.baseRevision + 5,
                  'conflictField': 'Modified on server by Dr. Sameh',
                },
          errorMessage: 'Version conflict: Record was updated remotely',
          isRetryable: false,
        );
        _processedOperations[entry.operationId] = conflictResult;
        results.add(conflictResult);
        continue;
      }

      // 6. Success: apply operation to simulated server database
      final serverId = 'SRV-${entry.localId}';
      final confirmedRevision = entry.baseRevision + 1;
      final serverCursor = 'cursor_${_cursorSequence++}';

      _serverDatabase.putIfAbsent(entry.entityType, () => {});
      _serverDatabase[entry.entityType]![serverId] = RemoteEntityChange(
        serverId: serverId,
        localId: entry.localId,
        entityType: entry.entityType,
        revision: confirmedRevision,
        isDeleted: entry.operation.name == 'delete',
        payload: entry.payload,
      );

      final successResult = SyncPushResult(
        success: true,
        operationId: entry.operationId,
        serverId: serverId,
        serverCursor: serverCursor,
        confirmedRevision: confirmedRevision,
      );

      _processedOperations[entry.operationId] = successResult;
      results.add(successResult);
    }

    if (simulateLostAck) {
      simulateLostAck = false;
      throw Exception('Network connection dropped after server committed batch operations');
    }

    return BatchPushResult(
      success: true,
      operationResults: results,
    );
  }

  @visibleForTesting
  void failOperationId(String opId, String error) {
    _customOperationFailures[opId] = error;
  }

  @override
  Future<SyncPullResult> pullChanges({
    required String entityType,
    String? cursor,
  }) async {
    pullCallCount++;

    if (simulateTimeout) {
      throw TimeoutException('Simulated remote sync timeout during pull');
    }

    final entityChanges = _serverDatabase[entityType]?.values.toList() ?? [];
    final newCursor = 'cursor_${_cursorSequence++}';

    return SyncPullResult(
      success: true,
      newCursor: newCursor,
      changes: entityChanges,
    );
  }

  @visibleForTesting
  void injectServerChange(RemoteEntityChange change) {
    _serverDatabase.putIfAbsent(change.entityType, () => {});
    _serverDatabase[change.entityType]![change.serverId] = change;
  }

  @visibleForTesting
  void reset() {
    _processedOperations.clear();
    _serverDatabase.clear();
    _customOperationFailures.clear();
    _cursorSequence = 100;
    simulateTimeout = false;
    simulateIntermittentFailure = false;
    simulateLostAck = false;
    simulateConflict = false;
    simulatePermanentFailure = false;
    pushCallCount = 0;
    pullCallCount = 0;
  }
}
