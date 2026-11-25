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

  /// Triggers an immediate single-flight synchronization pass.
  Future<SyncReport> syncNow() async {
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
      final allPending = await localStore.getPendingOutboxEntries(limit: 100);
      for (final entry in allPending) {
        if (entry.status == OutboxStatus.inFlight) {
          await localStore.updateOutboxStatus(
            operationId: entry.operationId,
            status: OutboxStatus.pending,
          );
        }
      }

      // 4. Retrieve fresh pending outbox entries
      final entriesToSync = await localStore.getPendingOutboxEntries(limit: 50);

      // Track permanently failed operation localIds to block dependents
      final permanentlyFailedOperations = <String>{};

      for (final entry in entriesToSync) {
        // If user activated Forced Local mode while this loop was executing, halt new requests!
        if (_modeSwitchedToLocalMidFlight ||
            dataModeService.currentMode != DataMode.online) {
          break;
        }

        // Dependency Check: patient before appointment before visit before payment
        final isDependencyBlocked = entry.dependencyRefs.any(
          (dep) => permanentlyFailedOperations.contains(dep),
        );

        if (isDependencyBlocked) {
          blocked++;
          await localStore.updateOutboxStatus(
            operationId: entry.operationId,
            status: OutboxStatus.blocked,
            lastError: 'Blocked by failure of dependent operation',
          );
          permanentlyFailedOperations.add('${entry.entityType}:${entry.localId}');
          continue;
        }

        // Mark in-flight
        await localStore.updateOutboxStatus(
          operationId: entry.operationId,
          status: OutboxStatus.inFlight,
        );
        pushed++;

        try {
          final result = await remoteApi.pushOperation(entry);

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
            // Reconcile and record ACK safely (even if mode changed mid-flight)
            await localStore.acknowledgeOutboxOperation(
              operationId: entry.operationId,
              serverId: result.serverId,
              serverCursor: result.serverCursor,
              confirmedRevision: result.confirmedRevision,
            );
          } else {
            failed++;
            if (!result.isRetryable) {
              permanentlyFailedOperations
                  .add('${entry.entityType}:${entry.localId}');
              await localStore.updateOutboxStatus(
                operationId: entry.operationId,
                status: OutboxStatus.failed,
                lastError: result.errorMessage ?? 'Non-retryable remote error',
              );
            } else {
              // Exponential backoff marker
              final backoffSeconds = min(pow(2, entry.attemptCount).toInt(), 60);
              await localStore.updateOutboxStatus(
                operationId: entry.operationId,
                status: OutboxStatus.pending,
                lastError: 'Retryable error (backoff ${backoffSeconds}s): ${result.errorMessage}',
              );
            }
          }
        } catch (e) {
          failed++;
          // Network interruption or timeout: keep pending for retry
          await localStore.updateOutboxStatus(
            operationId: entry.operationId,
            status: OutboxStatus.pending,
            lastError: e.toString(),
          );
        }
      }

      // 5. Pull changes from remote using server-issued cursors
      if (!_modeSwitchedToLocalMidFlight &&
          dataModeService.currentMode == DataMode.online) {
        final entityTypes = ['patient', 'booking', 'visit', 'payment'];
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
