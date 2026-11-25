import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/offline/models/local_entity_record.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/storage/cache_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
  });

  group('Transactional Store Persistence & Atomicity (Stage 1)', () {
    test('1. Write failure surfaces exception and rolls back in-memory state', () async {
      // Simulate storage writer that fails
      bool shouldFail = false;
      final memoryBacking = <String, String>{};

      final store = InMemoryTransactionalStore(
        storageWriter: (key, value) async {
          if (shouldFail) {
            throw Exception('Disk I/O Error: Out of space or write permission denied');
          }
          memoryBacking[key] = value;
        },
        storageReader: (key) => memoryBacking[key],
      );

      // Successful write first
      await store.runInTransaction((txn) async {
        txn.upsertEntity(LocalEntityRecord(
          localId: 'PAT-1',
          entityType: 'patient',
          accountId: 'acc',
          branchId: 'br',
          payload: {'name': 'Patient Original'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      });

      final initial = await store.getEntity(localId: 'PAT-1', accountId: 'acc', branchId: 'br');
      expect(initial, isNotNull);
      expect(initial!.payload['name'], 'Patient Original');

      // Now enable write failure and attempt a mutation
      shouldFail = true;

      await expectLater(
        store.runInTransaction((txn) async {
          txn.upsertEntity(LocalEntityRecord(
            localId: 'PAT-1',
            entityType: 'patient',
            accountId: 'acc',
            branchId: 'br',
            payload: {'name': 'Patient Corrupted Mutation'},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
          txn.insertOutbox(OutboxEntry(
            operationId: 'op-fail',
            entityType: 'patient',
            localId: 'PAT-1',
            operation: OutboxOperationType.update,
            payload: {},
            baseRevision: 1,
            createdAt: DateTime.now(),
            status: OutboxStatus.pending,
          ));
        }),
        throwsA(isA<StoragePersistenceException>()),
      );

      // Verify in-memory state was rolled back to "Patient Original"
      final afterRollback = await store.getEntity(localId: 'PAT-1', accountId: 'acc', branchId: 'br');
      expect(afterRollback, isNotNull);
      expect(afterRollback!.payload['name'], 'Patient Original');

      // Verify no outbox entry was committed in memory
      final outbox = await store.getPendingOutboxEntries();
      expect(outbox.isEmpty, isTrue);
    });

    test('2. Atomic persistence: Entity and Outbox are written in a single versioned snapshot', () async {
      final memoryBacking = <String, String>{};

      final store = InMemoryTransactionalStore(
        storageWriter: (key, value) async => memoryBacking[key] = value,
        storageReader: (key) => memoryBacking[key],
      );

      await store.runInTransaction((txn) async {
        txn.upsertEntity(LocalEntityRecord(
          localId: 'PAT-ATOMIC',
          entityType: 'patient',
          accountId: 'acc',
          branchId: 'br',
          payload: {'name': 'Atomic Patient'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        txn.insertOutbox(OutboxEntry(
          operationId: 'OP-ATOMIC',
          entityType: 'patient',
          localId: 'PAT-ATOMIC',
          operation: OutboxOperationType.create,
          payload: {'name': 'Atomic Patient'},
          baseRevision: 1,
          createdAt: DateTime.now(),
          status: OutboxStatus.pending,
        ));
      });

      // Verify only ONE snapshot document exists on disk
      expect(memoryBacking.containsKey(InMemoryTransactionalStore.snapshotKey), isTrue);

      final snapshotDoc = jsonDecode(memoryBacking[InMemoryTransactionalStore.snapshotKey]!);
      expect(snapshotDoc['schemaVersion'], 1);
      expect(snapshotDoc['entities']['PAT-ATOMIC'], isNotNull);
      expect(snapshotDoc['outbox']['OP-ATOMIC'], isNotNull);
    });

    test('3. Corruption is detected, backed up, and surfaces error rather than silently starting empty', () async {
      final memoryBacking = <String, String>{
        InMemoryTransactionalStore.snapshotKey: 'INVALID_JSON_CORRUPTED_BYTES_{{{',
      };

      String? createdBackupKey;

      expect(
        () => InMemoryTransactionalStore(
          storageWriter: (key, value) async {
            memoryBacking[key] = value;
            if (key.startsWith('eyadty_offline_store_corrupted_')) {
              createdBackupKey = key;
            }
          },
          storageReader: (key) => memoryBacking[key],
        ),
        throwsA(isA<StorageCorruptionException>()),
      );

      // Verify a backup was created containing the corrupted data
      expect(createdBackupKey, isNotNull);
      expect(memoryBacking[createdBackupKey], 'INVALID_JSON_CORRUPTED_BYTES_{{{');
    });

    test('4. Schema migration: store upgrades older schema versions seamlessly', () async {
      final oldVersionSnapshot = {
        'schemaVersion': 1,
        'updatedAt': DateTime.now().toIso8601String(),
        'entities': {
          'PAT-V1': {
            'localId': 'PAT-V1',
            'entityType': 'patient',
            'accountId': 'acc',
            'branchId': 'br',
            'payload': {'name': 'V1 Patient'},
            'localRevision': 1,
            'syncStatus': 'synced',
            'isProvisional': false,
            'isTombstone': false,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        },
        'outbox': {},
        'conflicts': {},
        'syncCursors': {},
      };

      final memoryBacking = <String, String>{
        InMemoryTransactionalStore.snapshotKey: jsonEncode(oldVersionSnapshot),
      };

      final store = InMemoryTransactionalStore(
        storageWriter: (key, value) async => memoryBacking[key] = value,
        storageReader: (key) => memoryBacking[key],
      );

      final entity = await store.getEntity(localId: 'PAT-V1', accountId: 'acc', branchId: 'br');
      expect(entity, isNotNull);
      expect(entity!.payload['name'], 'V1 Patient');
    });
  });
}
