import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/local_entity_record.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/remote/http_remote_sync_api.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/offline/sync/sync_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalServerApiConsumer localServerApi;
  late HttpRemoteSyncApi syncApi;
  late InMemoryTransactionalStore store;
  late DataModeService dataModeService;
  late SyncEngine engine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    localServerApi = LocalServerApiConsumer();
    syncApi = HttpRemoteSyncApi(apiConsumer: localServerApi);
    store = InMemoryTransactionalStore(persistToStorage: false);
    dataModeService = DataModeService(
      reachabilityProbe: (_, __) async => true,
      initialReachable: true,
    );
    engine = SyncEngine(
      localStore: store,
      dataModeService: dataModeService,
      remoteApi: syncApi,
    );
  });

  tearDown(() {
    engine.dispose();
    dataModeService.dispose();
  });

  group('HttpRemoteSyncApi + SyncLocalHandler Contract Tests', () {
    test('1. Batch push persists entities, issues opaque cursors, and replays idempotently', () async {
      final op1 = OutboxEntry(
        operationId: 'http_op_1',
        entityType: 'patient',
        localId: 'PAT-H1',
        operation: OutboxOperationType.create,
        payload: {'id': 'PAT-H1', 'name': 'أحمد علي'},
        baseRevision: 1,
        createdAt: DateTime(2026, 11, 20),
      );
      final op2 = OutboxEntry(
        operationId: 'http_op_2',
        entityType: 'booking',
        localId: 'BOK-H1',
        operation: OutboxOperationType.create,
        payload: {'id': 'BOK-H1', 'patientId': 'PAT-H1'},
        baseRevision: 1,
        dependencyRefs: ['patient:PAT-H1'],
        createdAt: DateTime(2026, 11, 20, 0, 1),
      );

      final first = await syncApi.pushBatch([op1, op2]);
      expect(first.success, isTrue);
      expect(first.operationResults.length, 2);
      expect(first.operationResults[0].success, isTrue);
      expect(first.operationResults[0].confirmedRevision, 2);
      expect(first.operationResults[0].serverCursor, startsWith('cursor_'));

      // Replay same batch -> identical serverId & cursor
      final replay = await syncApi.pushBatch([op1, op2]);
      expect(replay.operationResults[0].serverId, first.operationResults[0].serverId);
      expect(replay.operationResults[0].serverCursor, first.operationResults[0].serverCursor);
    });

    test('2. Detects baseRevision 409 conflict and skips dependent operations', () async {
      await syncApi.pushBatch([
        OutboxEntry(
          operationId: 'op_seed_rev',
          entityType: 'patient',
          localId: 'PAT-C1',
          operation: OutboxOperationType.create,
          payload: {'id': 'PAT-C1', 'name': 'Server V2'},
          baseRevision: 1,
          createdAt: DateTime(2026, 11, 20),
        ),
      ]);

      final staleOp = OutboxEntry(
        operationId: 'op_stale_update',
        entityType: 'patient',
        localId: 'PAT-C1',
        operation: OutboxOperationType.update,
        payload: {'id': 'PAT-C1', 'name': 'Stale Client'},
        baseRevision: 1, // Server is already at revision 2
        createdAt: DateTime(2026, 11, 20, 0, 2),
      );
      final dependentOp = OutboxEntry(
        operationId: 'op_child_after_conflict',
        entityType: 'booking',
        localId: 'BOK-C1',
        operation: OutboxOperationType.create,
        payload: {'id': 'BOK-C1', 'patientId': 'PAT-C1'},
        baseRevision: 1,
        dependencyRefs: ['patient:PAT-C1'],
        createdAt: DateTime(2026, 11, 20, 0, 3),
      );

      final res = await syncApi.pushBatch([staleOp, dependentOp]);
      expect(res.getResultFor('op_stale_update')?.hasConflict, isTrue);
      expect(res.getResultFor('op_child_after_conflict')?.errorMessage, 'skipped_dependency_failed');
    });

    test('3. Cursor pull returns incremental changes and tombstones', () async {
      await syncApi.pushBatch([
        OutboxEntry(
          operationId: 'op_p1',
          entityType: 'patient',
          localId: 'PAT-T1',
          operation: OutboxOperationType.create,
          payload: {'id': 'PAT-T1', 'name': 'Temp'},
          baseRevision: 1,
          createdAt: DateTime(2026, 11, 20),
        ),
      ]);

      final pull1 = await syncApi.pullChanges(entityType: 'patient');
      expect(pull1.changes.length, 1);
      expect(pull1.changes.first.isDeleted, isFalse);

      await syncApi.pushBatch([
        OutboxEntry(
          operationId: 'op_p1_del',
          entityType: 'patient',
          localId: 'PAT-T1',
          operation: OutboxOperationType.delete,
          payload: {'id': 'PAT-T1'},
          baseRevision: 2,
          createdAt: DateTime(2026, 11, 20, 0, 5),
        ),
      ]);

      final pull2 = await syncApi.pullChanges(entityType: 'patient', cursor: pull1.newCursor);
      expect(pull2.changes.length, 1);
      expect(pull2.changes.first.isDeleted, isTrue);
    });

    test('4. SyncEngine end-to-end syncNow with HttpRemoteSyncApi acknowledges local outbox', () async {
      await store.runInTransaction((txn) async {
        txn.upsertEntity(LocalEntityRecord(
          localId: 'PAT-E2E',
          entityType: 'patient',
          accountId: 'default',
          branchId: 'branch_1',
          payload: {'name': 'E2E'},
          isProvisional: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        txn.insertOutbox(OutboxEntry(
          operationId: 'op_e2e_1',
          entityType: 'patient',
          localId: 'PAT-E2E',
          operation: OutboxOperationType.create,
          payload: {'name': 'E2E'},
          baseRevision: 1,
          createdAt: DateTime.now(),
        ));
      });

      final report = await engine.syncNow();
      expect(report.operationsPushed, 1);
      expect(report.operationsAcknowledged, 1);
      expect(report.conflictsDetected, 0);
    });
  });
}
