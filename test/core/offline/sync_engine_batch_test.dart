import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/local_entity_record.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/remote/fake_remote_sync_api.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/offline/sync/sync_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryTransactionalStore store;
  late DataModeService dataModeService;
  late FakeRemoteSyncApi fakeApi;
  late SyncEngine engine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = InMemoryTransactionalStore(persistToStorage: false);
    dataModeService = DataModeService(
      reachabilityProbe: (_, __) async => true,
      initialReachable: true,
    );
    fakeApi = FakeRemoteSyncApi();
    engine = SyncEngine(
      localStore: store,
      dataModeService: dataModeService,
      remoteApi: fakeApi,
    );
  });

  tearDown(() {
    engine.dispose();
    dataModeService.dispose();
  });

  group('SyncEngine Batch and Section Sync Tests', () {
    test('1. Batch push succeeds and acknowledges multiple operations in one round trip', () async {
      await store.runInTransaction((txn) async {
        txn.upsertEntity(LocalEntityRecord(
          localId: 'PAT-1',
          entityType: 'patient',
          accountId: 'default',
          branchId: 'branch_1',
          payload: {'name': 'Ahmed'},
          isProvisional: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        txn.insertOutbox(OutboxEntry(
          operationId: 'op_pat_1',
          entityType: 'patient',
          localId: 'PAT-1',
          operation: OutboxOperationType.create,
          payload: {'name': 'Ahmed'},
          baseRevision: 1,
          createdAt: DateTime.now(),
        ));
        txn.upsertEntity(LocalEntityRecord(
          localId: 'BOK-1',
          entityType: 'booking',
          accountId: 'default',
          branchId: 'branch_1',
          payload: {'patientId': 'PAT-1'},
          isProvisional: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        txn.insertOutbox(OutboxEntry(
          operationId: 'op_bok_1',
          entityType: 'booking',
          localId: 'BOK-1',
          operation: OutboxOperationType.create,
          payload: {'patientId': 'PAT-1'},
          baseRevision: 1,
          createdAt: DateTime.now(),
        ));
      });

      final report = await engine.syncNow();
      expect(report.operationsPushed, 2);
      expect(report.operationsAcknowledged, 2);
      expect(report.operationsFailed, 0);

      final pat = await store.getEntity(localId: 'PAT-1', accountId: 'default', branchId: 'branch_1');
      expect(pat?.isProvisional, isFalse);
      expect(pat?.syncStatus, SyncStatus.synced);
    });

    test('2. Discard create operation removes outbox entry and deletes local entity', () async {
      await store.runInTransaction((txn) async {
        txn.upsertEntity(LocalEntityRecord(
          localId: 'PAT-NEW',
          entityType: 'patient',
          accountId: 'default',
          branchId: 'branch_1',
          payload: {'name': 'Discard Me'},
          isProvisional: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        txn.insertOutbox(OutboxEntry(
          operationId: 'op_discard_pat',
          entityType: 'patient',
          localId: 'PAT-NEW',
          operation: OutboxOperationType.create,
          payload: {'name': 'Discard Me'},
          baseRevision: 1,
          createdAt: DateTime.now(),
        ));
      });

      await engine.discardOperation('op_discard_pat');

      final pat = await store.getEntity(localId: 'PAT-NEW', accountId: 'default', branchId: 'branch_1');
      expect(pat, isNull);
      final outbox = await store.getOutboxEntry('op_discard_pat');
      expect(outbox, isNull);
    });

    test('3. Discard update operation rolls back local entity to previousPayload', () async {
      await store.runInTransaction((txn) async {
        txn.upsertEntity(LocalEntityRecord(
          localId: 'PAT-UPD',
          entityType: 'patient',
          accountId: 'default',
          branchId: 'branch_1',
          payload: {'name': 'New Ahmed'},
          localRevision: 2,
          isProvisional: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        txn.insertOutbox(OutboxEntry(
          operationId: 'op_update_pat',
          entityType: 'patient',
          localId: 'PAT-UPD',
          operation: OutboxOperationType.update,
          payload: {'name': 'New Ahmed'},
          previousPayload: {'name': 'Old Ahmed'},
          baseRevision: 1,
          createdAt: DateTime.now(),
        ));
      });

      await engine.discardOperation('op_update_pat');

      final pat = await store.getEntity(localId: 'PAT-UPD', accountId: 'default', branchId: 'branch_1');
      expect(pat, isNotNull);
      expect(pat?.payload['name'], 'Old Ahmed');
      expect(pat?.localRevision, 1);
    });

    test('4. Discarding parent operation with dependents discards dependents recursively', () async {
      await store.runInTransaction((txn) async {
        txn.upsertEntity(LocalEntityRecord(
          localId: 'PAT-PARENT',
          entityType: 'patient',
          accountId: 'default',
          branchId: 'branch_1',
          payload: {'name': 'Parent'},
          isProvisional: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        txn.insertOutbox(OutboxEntry(
          operationId: 'op_parent',
          entityType: 'patient',
          localId: 'PAT-PARENT',
          operation: OutboxOperationType.create,
          payload: {'name': 'Parent'},
          baseRevision: 1,
          createdAt: DateTime.now(),
        ));

        txn.upsertEntity(LocalEntityRecord(
          localId: 'BOK-CHILD',
          entityType: 'booking',
          accountId: 'default',
          branchId: 'branch_1',
          payload: {'patientId': 'PAT-PARENT'},
          isProvisional: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        txn.insertOutbox(OutboxEntry(
          operationId: 'op_child',
          entityType: 'booking',
          localId: 'BOK-CHILD',
          operation: OutboxOperationType.create,
          payload: {'patientId': 'PAT-PARENT'},
          baseRevision: 1,
          createdAt: DateTime.now(),
          dependencyRefs: const ['patient:PAT-PARENT'],
        ));
      });

      // Discard parent
      await engine.discardOperation('op_parent', discardDependents: true);

      expect(await store.getEntity(localId: 'PAT-PARENT', accountId: 'default', branchId: 'branch_1'), isNull);
      expect(await store.getEntity(localId: 'BOK-CHILD', accountId: 'default', branchId: 'branch_1'), isNull);
      expect(await store.getOutboxEntry('op_parent'), isNull);
      expect(await store.getOutboxEntry('op_child'), isNull);
    });

    test('5. Section subset sync only pushes operations in selected section', () async {
      await store.runInTransaction((txn) async {
        txn.upsertEntity(LocalEntityRecord(
          localId: 'DRUG-1',
          entityType: 'drug',
          accountId: 'default',
          branchId: 'branch_1',
          payload: {'name': 'Panadol'},
          isProvisional: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        txn.insertOutbox(OutboxEntry(
          operationId: 'op_drug_1',
          entityType: 'drug',
          localId: 'DRUG-1',
          operation: OutboxOperationType.create,
          payload: {'name': 'Panadol'},
          baseRevision: 1,
          createdAt: DateTime.now(),
        ));

        txn.upsertEntity(LocalEntityRecord(
          localId: 'VISIT-1',
          entityType: 'visit',
          accountId: 'default',
          branchId: 'branch_1',
          payload: {'notes': 'Checkup'},
          isProvisional: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        txn.insertOutbox(OutboxEntry(
          operationId: 'op_visit_1',
          entityType: 'visit',
          localId: 'VISIT-1',
          operation: OutboxOperationType.create,
          payload: {'notes': 'Checkup'},
          baseRevision: 1,
          createdAt: DateTime.now(),
        ));
      });

      // Sync only the drug section
      final report = await engine.syncNow(entityTypes: ['drug']);
      expect(report.operationsPushed, 1);
      expect(report.operationsAcknowledged, 1);

      final drugOutbox = await store.getOutboxEntry('op_drug_1');
      expect(drugOutbox?.status, OutboxStatus.acknowledged);

      final visitOutbox = await store.getOutboxEntry('op_visit_1');
      expect(visitOutbox?.status, OutboxStatus.pending);
    });
  });
}
