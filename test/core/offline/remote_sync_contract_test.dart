import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/remote/fake_remote_sync_api.dart';
import 'package:eyadty/core/offline/remote/remote_sync_api.dart';

void main() {
  group('RemoteSyncApi Contract Suite (Batch, Idempotency, Dependencies, Conflicts)', () {
    late FakeRemoteSyncApi api;

    setUp(() {
      api = FakeRemoteSyncApi();
    });

    OutboxEntry createEntry({
      required String opId,
      required String localId,
      required String entityType,
      int baseRev = 1,
      List<String> deps = const [],
    }) {
      return OutboxEntry(
        operationId: opId,
        entityType: entityType,
        localId: localId,
        operation: OutboxOperationType.create,
        payload: {'id': localId, 'name': 'Item $localId'},
        baseRevision: baseRev,
        createdAt: DateTime.now(),
        dependencyRefs: deps,
      );
    }

    test('1. Idempotency: re-sending the same batch returns identical results without double-mutating', () async {
      final op1 = createEntry(opId: 'batch_op_1', localId: 'P-1', entityType: 'patient');
      final op2 = createEntry(opId: 'batch_op_2', localId: 'B-1', entityType: 'booking');

      final batch = [op1, op2];

      final firstResult = await api.pushBatch(batch);
      expect(firstResult.success, isTrue);
      expect(firstResult.operationResults.length, 2);
      expect(firstResult.operationResults[0].success, isTrue);
      expect(firstResult.operationResults[0].serverId, isNotNull);
      final firstServerId = firstResult.operationResults[0].serverId;
      final firstRev = firstResult.operationResults[0].confirmedRevision;

      // Re-send the exact batch (e.g. after client network timeout)
      final secondResult = await api.pushBatch(batch);
      expect(secondResult.success, isTrue);
      expect(secondResult.operationResults[0].serverId, equals(firstServerId));
      expect(secondResult.operationResults[0].confirmedRevision, equals(firstRev));
    });

    test('2. Per-operation results: failure in one operation does not fail the entire batch', () async {
      final op1 = createEntry(opId: 'batch_valid', localId: 'P-10', entityType: 'patient');
      final op2 = OutboxEntry(
        operationId: 'batch_invalid',
        entityType: 'patient',
        localId: 'P-INVALID',
        operation: OutboxOperationType.create,
        payload: {'invalid': true},
        baseRevision: 1,
        createdAt: DateTime.now(),
      );

      // Force failure on op2
      api.failOperationId('batch_invalid', 'Invalid schema');

      final batchResult = await api.pushBatch([op1, op2]);
      expect(batchResult.success, isTrue); // HTTP 200 equivalent
      final res1 = batchResult.getResultFor('batch_valid');
      final res2 = batchResult.getResultFor('batch_invalid');

      expect(res1?.success, isTrue);
      expect(res2?.success, isFalse);
      expect(res2?.errorMessage, contains('Invalid schema'));
    });

    test('3. Dependency failure skip: dependent operations are marked skipped_dependency_failed', () async {
      final parentOp = createEntry(opId: 'parent_op', localId: 'P-100', entityType: 'patient');
      final dependentOp = createEntry(
        opId: 'child_op',
        localId: 'B-100',
        entityType: 'booking',
        deps: ['patient:P-100'],
      );

      // Force parent to fail
      api.failOperationId('parent_op', 'Duplicate National ID');

      final batchResult = await api.pushBatch([parentOp, dependentOp]);
      expect(batchResult.success, isTrue);

      final parentRes = batchResult.getResultFor('parent_op');
      final childRes = batchResult.getResultFor('child_op');

      expect(parentRes?.success, isFalse);
      expect(childRes?.success, isFalse);
      expect(childRes?.errorMessage, equals('skipped_dependency_failed'));
    });

    test('4. Conflict detection: stale base revision returns hasConflict with server version', () async {
      // First push to server at rev 1 -> becomes rev 2
      final op1 = createEntry(opId: 'op_initial', localId: 'P-200', entityType: 'patient', baseRev: 1);
      await api.pushBatch([op1]);

      // Remote update happens on server -> rev 3
      api.injectServerChange(const RemoteEntityChange(
        serverId: 'SRV-P-200',
        localId: 'P-200',
        entityType: 'patient',
        revision: 3,
        payload: {'name': 'Server Updated Name'},
      ));

      // Client pushes with baseRevision 1 (stale!)
      final staleOp = OutboxEntry(
        operationId: 'op_stale',
        entityType: 'patient',
        localId: 'P-200',
        operation: OutboxOperationType.update,
        payload: {'name': 'Client Name'},
        baseRevision: 1, // Stale!
        createdAt: DateTime.now(),
      );

      final batchResult = await api.pushBatch([staleOp]);
      final staleRes = batchResult.getResultFor('op_stale');

      expect(staleRes?.success, isFalse);
      expect(staleRes?.hasConflict, isTrue);
      expect(staleRes?.serverConflictVersion, isNotNull);
      expect(staleRes?.serverConflictVersion?['revision'], equals(3));
    });
  });
}
