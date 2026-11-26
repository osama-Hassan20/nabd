import 'dart:async';
import 'dart:math';
import '../data_mode_service.dart';
import '../models/conflict_record.dart';
import '../models/local_entity_record.dart';
import '../models/outbox_entry.dart';
import '../models/sync_status.dart';
import '../remote/remote_sync_api.dart';
import '../store/transactional_local_store.dart';

class SyncReport {
  final int operationsPushed;
  final int operationsAcknowledged;
  final int operationsFailed;
  final int operationsBlocked;
  final int conflictsDetected;
  final int changesPulled;
  final Duration duration;
  final String? error;

  const SyncReport({
    this.operationsPushed = 0,
    this.operationsAcknowledged = 0,
    this.operationsFailed = 0,
    this.operationsBlocked = 0,
    this.conflictsDetected = 0,
    this.changesPulled = 0,
    this.duration = Duration.zero,
    this.error,
  });
}

class SyncEngine implements InFlightSyncCoordinator {
  final TransactionalLocalStore localStore;
  final DataModeService dataModeService;
  final RemoteSyncApi remoteApi;

  bool _isSyncRunning = false;
  bool _modeSwitchedToLocalMidFlight = false;
  Timer? _periodicSyncTimer;
  StreamSubscription? _dataModeSubscription;

  SyncEngine({
    required this.localStore,
    required this.dataModeService,
    required this.remoteApi,
  }) {
    // Listen to data mode changes: only auto-sync when transition occurs from non-online to online
    DataMode previousMode = dataModeService.currentMode;
    _dataModeSubscription = dataModeService.stream.listen((state) {
      final wasOffline = previousMode != DataMode.online;
      previousMode = state.mode;
      if (wasOffline && state.mode == DataMode.online && !_isSyncRunning) {
        syncNow();
      }
    });
  }

  @override
  bool get isSyncInProgress => _isSyncRunning;

  @override
  Future<void> onModeSwitchedToForcedLocal() async {
    _modeSwitchedToLocalMidFlight = true;
  }

  @override
  void recordAckSafely(String operationId, Map<String, dynamic> ackResponse) {
    localStore.acknowledgeOutboxOperation(
      operationId: operationId,
      serverId: ackResponse['serverId'] as String?,
      serverCursor: ackResponse['serverCursor'] as String?,
      confirmedRevision: ackResponse['confirmedRevision'] as int?,
    );
  }

  /// Triggers a synchronization pass.
  /// [operationIds]: optional subset of operation IDs to sync.
  /// [entityTypes]: optional subset of sections/entityTypes to sync.
  Future<SyncReport> syncNow({
    List<String>? operationIds,
    List<String>? entityTypes,
  }) async {
    // 1. Guard against concurrent sync runs (Single-flight lock)
    if (_isSyncRunning) {
      return const SyncReport(error: 'Sync already in progress');
    }

    // 2. Offline / Forced Local Guard
    if (dataModeService.currentMode != DataMode.online) {
      return const SyncReport(
        error: 'Sync skipped: App is in offline or forced-local mode',
      );
    }

    _isSyncRunning = true;
    _modeSwitchedToLocalMidFlight = false;
    dataModeService.setSyncInProgress(true);
    final stopwatch = Stopwatch()..start();

    int pushed = 0;
    int acknowledged = 0;
    int failed = 0;
    int blocked = 0;
    int conflicts = 0;
    int pulled = 0;
    String? syncError;

    try {
      // 3. Crash recovery: recover any stale inFlight operations back to pending
      final allPending = await localStore.getPendingOutboxEntries(limit: 200);
      for (final entry in allPending) {
        if (entry.status == OutboxStatus.inFlight) {
          await localStore.updateOutboxStatus(
            operationId: entry.operationId,
            status: OutboxStatus.pending,
          );
        }
      }

      // 4. Retrieve fresh pending outbox entries
      final freshPending = await localStore.getPendingOutboxEntries(limit: 200);

      // Filter by entityTypes or operationIds if specified
      var selectedEntries = freshPending.where((entry) {
        if (operationIds != null && !operationIds.contains(entry.operationId)) {
          return false;
        }
        if (entityTypes != null && !entityTypes.contains(entry.entityType)) {
          return false;
        }
        return true;
      }).toList();

      // Section subset dependency auto-include:
      // If a selected operation depends on an unselected one, auto-include the parent operation
      final selectedOpIds = selectedEntries.map((e) => e.operationId).toSet();
      final selectedEntities = selectedEntries.map((e) => '${e.entityType}:${e.localId}').toSet();

      for (final entry in List<OutboxEntry>.from(selectedEntries)) {
        for (final depRef in entry.dependencyRefs) {
          if (!selectedEntities.contains(depRef)) {
            // Find in freshPending
            final parent = freshPending.where((p) =>
                '${p.entityType}:${p.localId}' == depRef || p.localId == depRef).firstOrNull;
            if (parent != null && !selectedOpIds.contains(parent.operationId)) {
              selectedEntries.add(parent);
              selectedOpIds.add(parent.operationId);
              selectedEntities.add('${parent.entityType}:${parent.localId}');
            }
          }
        }
      }

      selectedEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // 5. Chunk operations (limit 50 per batch)
      const chunkSize = 50;
      for (int i = 0; i < selectedEntries.length; i += chunkSize) {
        if (_modeSwitchedToLocalMidFlight ||
            dataModeService.currentMode != DataMode.online) {
          break;
        }

        final chunk = selectedEntries.sublist(
          i,
          min(i + chunkSize, selectedEntries.length),
        );

        // Mark in-flight
        for (final entry in chunk) {
          await localStore.updateOutboxStatus(
            operationId: entry.operationId,
            status: OutboxStatus.inFlight,
          );
          pushed++;
        }

        try {
          final batchResult = await remoteApi.pushBatch(chunk);

          for (final entry in chunk) {
            final result = batchResult.getResultFor(entry.operationId);
            if (result == null) {
              failed++;
              await localStore.updateOutboxStatus(
                operationId: entry.operationId,
                status: OutboxStatus.pending,
                lastError: 'No result returned from batch push',
              );
              continue;
            }

            if (result.hasConflict) {
              conflicts++;
              await _handleConflict(entry, result.serverConflictVersion ?? {});
              await localStore.updateOutboxStatus(
                operationId: entry.operationId,
                status: OutboxStatus.failed,
                lastError: 'Conflict detected: local and server versions preserved',
              );
            } else if (result.success) {
              acknowledged++;
              await localStore.acknowledgeOutboxOperation(
                operationId: entry.operationId,
                serverId: result.serverId,
                serverCursor: result.serverCursor,
                confirmedRevision: result.confirmedRevision,
              );
            } else if (result.errorMessage == 'skipped_dependency_failed') {
              blocked++;
              await localStore.updateOutboxStatus(
                operationId: entry.operationId,
                status: OutboxStatus.blocked,
                lastError: 'Blocked by failure of dependent operation',
              );
            } else {
              failed++;
              if (!result.isRetryable) {
                await localStore.updateOutboxStatus(
                  operationId: entry.operationId,
                  status: OutboxStatus.failed,
                  lastError: result.errorMessage ?? 'Non-retryable remote error',
                );
              } else {
                final backoffSeconds = min(pow(2, entry.attemptCount).toInt(), 60);
                await localStore.updateOutboxStatus(
                  operationId: entry.operationId,
                  status: OutboxStatus.pending,
                  lastError: 'Retryable error (backoff ${backoffSeconds}s): ${result.errorMessage}',
                );
              }
            }
          }
        } catch (e) {
          failed += chunk.length;
          for (final entry in chunk) {
            await localStore.updateOutboxStatus(
              operationId: entry.operationId,
              status: OutboxStatus.pending,
              lastError: e.toString(),
            );
          }
        }
      }

      // 6. Pull changes from remote using server-issued cursors
      if (!_modeSwitchedToLocalMidFlight &&
          dataModeService.currentMode == DataMode.online) {
        final entityTypes = [
          'patient',
          'booking',
          'visit',
          'payment',
          'drug',
          'doctor',
          'inventory',
          'medical_catalog',
          'settings',
          'staff_user',
          'hr_advance',
          'hr_payroll',
        ];
        for (final type in entityTypes) {
          final cursor = await localStore.getSyncCursor(type);
          try {
            final pullResult = await remoteApi.pullChanges(
              entityType: type,
              cursor: cursor,
            );
            if (pullResult.success) {
              pulled += pullResult.changes.length;
              await _applyRemoteChanges(pullResult.changes);
              await localStore.setSyncCursor(type, pullResult.newCursor);
            }
          } catch (_) {
            // Non-fatal pull error
          }
        }
      }
    } catch (e) {
      syncError = e.toString();
    } finally {
      stopwatch.stop();
      _isSyncRunning = false;
      dataModeService.setSyncInProgress(false);

      // Refresh outbox badge counter
      final remaining = await localStore.getPendingOutboxEntries();
      dataModeService.updatePendingOutboxCount(remaining.length);
    }

    return SyncReport(
      operationsPushed: pushed,
      operationsAcknowledged: acknowledged,
      operationsFailed: failed,
      operationsBlocked: blocked,
      conflictsDetected: conflicts,
      changesPulled: pulled,
      duration: stopwatch.elapsed,
      error: syncError,
    );
  }

  /// Discards a specific outbox operation, rolling back its local entity.
  Future<void> discardOperation(
    String operationId, {
    bool discardDependents = true,
  }) async {
    await localStore.discardOutboxOperation(
      operationId,
      discardDependents: discardDependents,
    );
  }

  /// Discards all operations in a specific section.
  Future<void> discardSection(String entityType) async {
    final all = await localStore.getAllOutboxEntries();
    final sectionEntries = all.where((e) => e.entityType == entityType).toList();
    for (final entry in sectionEntries) {
      await localStore.discardOutboxOperation(entry.operationId, discardDependents: true);
    }
  }

  /// Resolves a conflict by keeping local changes (re-push with updated base revision).
  Future<void> resolveConflictKeepMine(ConflictRecord conflict) async {
    final op = await localStore.getOutboxEntry(conflict.conflictId.replaceFirst('CONF-', ''));
    if (op != null) {
      final serverRev = conflict.serverVersion['revision'] as int? ?? op.baseRevision + 1;
      await localStore.runInTransaction((txn) async {
        txn.resolveConflict(conflict.conflictId, op.payload);
        txn.insertOutbox(op.copyWith(
          baseRevision: serverRev,
          status: OutboxStatus.pending,
          lastError: null,
        ));
      });
      await syncNow(operationIds: [op.operationId]);
    }
  }

  /// Resolves a conflict by accepting the server version (discard local).
  Future<void> resolveConflictKeepServer(ConflictRecord conflict) async {
    final opId = conflict.conflictId.replaceFirst('CONF-', '');
    await discardOperation(opId, discardDependents: true);
    final entity = await localStore.getEntity(
      localId: conflict.localId,
      accountId: 'default',
      branchId: 'branch_1',
    );
    if (entity != null && conflict.serverVersion['payload'] != null) {
      final serverPayload = Map<String, dynamic>.from(conflict.serverVersion['payload'] as Map);
      final serverRev = conflict.serverVersion['revision'] as int? ?? entity.localRevision;
      await localStore.runInTransaction((txn) async {
        txn.resolveConflict(conflict.conflictId, serverPayload);
        txn.upsertEntity(entity.copyWith(
          payload: serverPayload,
          localRevision: serverRev,
          syncStatus: SyncStatus.synced,
          isProvisional: false,
          updatedAt: DateTime.now(),
        ));
      });
    }
  }

  Future<void> _handleConflict(
    OutboxEntry entry,
    Map<String, dynamic> serverVersion,
  ) async {
    final conflict = ConflictRecord(
      conflictId: 'CONF-${entry.operationId}',
      entityType: entry.entityType,
      localId: entry.localId,
      localVersion: entry.payload,
      serverVersion: serverVersion,
      detectedAt: DateTime.now(),
    );

    await localStore.runInTransaction((txn) async {
      txn.insertConflict(conflict);
    });
  }

  Future<void> _applyRemoteChanges(List<RemoteEntityChange> changes) async {
    if (changes.isEmpty) return;

    await localStore.runInTransaction((txn) async {
      for (final change in changes) {
        final localId = change.localId ?? change.serverId;
        if (change.isDeleted) {
          txn.markTombstone(localId);
        } else {
          final existing = txn.getEntity(localId);
          txn.upsertEntity(
            LocalEntityRecord(
              localId: localId,
              entityType: change.entityType,
              serverId: change.serverId,
              accountId: existing?.accountId ?? 'ACC-01',
              branchId: existing?.branchId ?? 'branch_1',
              payload: change.payload,
              localRevision: change.revision,
              syncStatus: SyncStatus.synced,
              isProvisional: false,
              isTombstone: false,
              createdAt: existing?.createdAt ?? DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
    });
  }

  void startPeriodicSync({Duration interval = const Duration(seconds: 45)}) {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(interval, (_) {
      if (dataModeService.isOnline && !_isSyncRunning) {
        syncNow();
      }
    });
  }

  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  void dispose() {
    stopPeriodicSync();
    _dataModeSubscription?.cancel();
  }
}
