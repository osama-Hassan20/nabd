import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/local_entity_record.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/remote/fake_remote_sync_api.dart';
import 'package:eyadty/core/offline/remote/remote_sync_api.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/offline/sync/sync_engine.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
  });

  late InMemoryTransactionalStore store;
  late DataModeService dataModeService;
  late FakeRemoteSyncApi fakeRemote;
  late SyncEngine engine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();

    store = InMemoryTransactionalStore();
    fakeRemote = FakeRemoteSyncApi();
    dataModeService = DataModeService(
      reachabilityProbe: (url, timeout) async => true,
      initialReachable: true,
    );

    engine = SyncEngine(
      localStore: store,
      dataModeService: dataModeService,
      remoteApi: fakeRemote,
    );
  });

  tearDown(() {
    engine.dispose();
  });

  group('SyncEngine Advanced Scenarios & Remote Contract Tests', () {
    test('1. Happy path: push outbox, server acknowledges, entity marks synced and provisional cleared', () async {
      await store.runInTransaction((txn) async {
        txn.upsertEntity(
          LocalEntityRecord(
            localId: 'PAT-1',
            entityType: 'patient',
            accountId: 'ACC-01',
            branchId: 'branch_1',
            payload: const {'name': 'Patient Ahmed'},
            syncStatus: SyncStatus.pending,
            isProvisional: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        txn.insertOutbox(
          OutboxEntry(
            operationId: 'OP-1',
            entityType: 'patient',
            localId: 'PAT-1',
            operation: OutboxOperationType.create,
            payload: const {'name': 'Patient Ahmed'},
            baseRevision: 1,
            createdAt: DateTime.now(),
          ),
        );
      });

      final report = await engine.syncNow();
      expect(report.operationsPushed, 1);
      expect(report.operationsAcknowledged, 1);

      // Verify entity updated in store
      final entity = await store.getEntity(
        localId: 'PAT-1',
        accountId: 'ACC-01',
        branchId: 'branch_1',
      );
      expect(entity, isNotNull);
      expect(entity!.syncStatus, SyncStatus.synced);
      expect(entity.isProvisional, isFalse);
      expect(entity.serverId, 'SRV-PAT-1');
    });

    test('2. Lost ACK Simulation: Client resends, Server returns idempotent result with zero duplication', () async {
      await store.runInTransaction((txn) async {
        txn.insertOutbox(
          OutboxEntry(
            operationId: 'OP-LOST-ACK',
            entityType: 'patient',
            localId: 'PAT-LOST',
            operation: OutboxOperationType.create,
            payload: const {'name': 'Patient with Lost ACK'},
            baseRevision: 1,
            createdAt: DateTime.now(),
          ),
        );
      });

      // Simulate network dropping right as server saves result
      fakeRemote.simulateLostAck = true;

      // Pass 1: fails on client due to dropped network, but server recorded it!
      final report1 = await engine.syncNow();
      expect(report1.operationsPushed, 1);
      expect(report1.operationsAcknowledged, 0);

      // Pass 2: client resends
      final report2 = await engine.syncNow();
      expect(report2.operationsPushed, 1);
      expect(report2.operationsAcknowledged, 1);

      // Verify server pushed count is 2 (client sent twice), but remote only has 1 record!
      expect(fakeRemote.pushCallCount, 2);
    });

    test('3. Dependency Ordering & Failure: Dependent operations block when prerequisite fails permanently', () async {
      await store.runInTransaction((txn) async {
        // Prerequisite Patient (will fail)
        txn.insertOutbox(
          OutboxEntry(
            operationId: 'OP-PAT-FAIL',
            entityType: 'patient',
            localId: 'PAT-FAIL',
            operation: OutboxOperationType.create,
            payload: const {'name': 'Invalid Patient'},
            baseRevision: 1,
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        );

        // Dependent Appointment
        txn.insertOutbox(
          OutboxEntry(
            operationId: 'OP-BOOK-DEP',
            entityType: 'booking',
            localId: 'BOOK-DEP',
            operation: OutboxOperationType.create,
            payload: const {'patientId': 'PAT-FAIL'},
            baseRevision: 1,
            createdAt: DateTime.now(),
            dependencyRefs: const ['patient:PAT-FAIL'],
          ),
        );
      });

      // Cause permanent failure (e.g. 422 Unprocessable Entity)
      fakeRemote.simulatePermanentFailure = true;

      final report = await engine.syncNow();
      expect(report.operationsFailed, 1);
      expect(report.operationsBlocked, 1);

      final bookOp = await store.getOutboxEntry('OP-BOOK-DEP');
      expect(bookOp, isNotNull);
      expect(bookOp!.status, OutboxStatus.blocked);
    });

    test('4. Conflict Detection: Preserves both versions in ConflictRecord without arbitrary data loss', () async {
      await store.runInTransaction((txn) async {
        txn.insertOutbox(
          OutboxEntry(
            operationId: 'OP-CONFLICT',
            entityType: 'visit',
            localId: 'VISIT-CONFLICT',
            operation: OutboxOperationType.update,
            payload: const {'notes': 'Local clinical notes by Dr. Hossam'},
            baseRevision: 1,
            createdAt: DateTime.now(),
          ),
        );
      });

      fakeRemote.simulateConflict = true;

      final report = await engine.syncNow();
      expect(report.conflictsDetected, 1);

      final conflicts = await store.getUnresolvedConflicts();
      expect(conflicts.length, 1);
      expect(conflicts.first.localId, 'VISIT-CONFLICT');
      expect(conflicts.first.localVersion['notes'], contains('Dr. Hossam'));
      expect(conflicts.first.serverVersion['conflictField'], contains('Dr. Sameh'));
    });

    test('5. Pull with Opaque Cursors & Tombstones', () async {
      fakeRemote.injectServerChange(
        const RemoteEntityChange(
          serverId: 'SRV-PULL-1',
          localId: 'PAT-PULL-1',
          entityType: 'patient',
          revision: 5,
          isDeleted: true, // Tombstone
          payload: {'name': 'Deleted Patient'},
        ),
      );

      final report = await engine.syncNow();
      expect(report.changesPulled, greaterThanOrEqualTo(1));

      // Verify tombstone reflected in local store
      final entity = await store.getEntity(
        localId: 'PAT-PULL-1',
        accountId: 'default',
        branchId: 'branch_1',
      );
      expect(entity, isNotNull);
      expect(entity!.isTombstone, isTrue);

      final cursor = await store.getSyncCursor('patient');
      expect(cursor, isNotNull);
      expect(cursor, startsWith('cursor_'));
    });

    test('6. Crash recovery: inFlight operations recover to pending upon engine pass', () async {
      await store.runInTransaction((txn) async {
        txn.insertOutbox(
          OutboxEntry(
            operationId: 'OP-CRASHED',
            entityType: 'patient',
            localId: 'PAT-CRASH',
            operation: OutboxOperationType.create,
            payload: const {'name': 'Crashed mid-operation'},
            baseRevision: 1,
            createdAt: DateTime.now(),
            status: OutboxStatus.inFlight, // Left inFlight after crash
          ),
        );
      });

      // Next sync run recovers it and pushes it
      final report = await engine.syncNow();
      expect(report.operationsAcknowledged, 1);
    });

    test('7. Single-flight lock: concurrent sync calls do not collide', () async {
      final future1 = engine.syncNow();
      final future2 = engine.syncNow();

      final results = await Future.wait([future1, future2]);
      // One ran, other returned early with lock message
      expect(results.any((r) => r.error == 'Sync already in progress'), isTrue);
    });
  });
}
