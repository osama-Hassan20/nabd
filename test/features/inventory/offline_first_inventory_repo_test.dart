import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/repositories/offline_first_inventory_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/features/inventory/data/models/inventory_item_model.dart';
import 'package:eyadty/features/inventory/data/repo/inventory_repo_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DataModeService dataModeService;
  late InventoryRepoImpl remoteRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataModeService = DataModeService(
      reachabilityProbe: (_, __) async => true,
      initialReachable: true,
    );
    remoteRepo = InventoryRepoImpl(apiConsumer: LocalServerApiConsumer());
  });

  tearDown(() {
    dataModeService.dispose();
  });

  group('OfflineFirstInventoryRepo Rehydrate & Durability Tests (A1)', () {
    test('1. Stock-in / Restock survives store rebuild from storage', () async {
      final sharedStorage = <String, String>{};
      final store1 = InMemoryTransactionalStore(
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo1 = OfflineFirstInventoryRepo(
        localStore: store1,
        dataModeService: dataModeService,
        remoteRepo: remoteRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      // Seed initial or restock item 'INV-DEN-01' (Articaine)
      final restockRes = await repo1.recordRestock(
        itemId: 'INV-DEN-01',
        quantity: 10,
        performedBy: 'USR-001',
        supplier: 'Medical Supplies Co',
      );
      expect(restockRes.isRight(), isTrue);

      // Rebuild store from storage (Simulating app restart)
      final store2 = InMemoryTransactionalStore(
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo2 = OfflineFirstInventoryRepo(
        localStore: store2,
        dataModeService: dataModeService,
        remoteRepo: remoteRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final itemsRes = await repo2.getItems();
      expect(itemsRes.isRight(), isTrue);
      final items = itemsRes.getOrElse(() => []);
      final item = items.firstWhere((i) => i.id == 'INV-DEN-01');
      // Stock increased from 8 to 18 and persisted
      expect(item.currentStock, 18);

      // Verify outbox entry exists
      final outbox = await store2.getAllOutboxEntries();
      expect(outbox.any((o) => o.entityType == 'inventory' && o.localId == 'INV-DEN-01'), isTrue);
    });

    test('2. Add new item survives store rebuild from storage', () async {
      final sharedStorage = <String, String>{};
      final store1 = InMemoryTransactionalStore(
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo1 = OfflineFirstInventoryRepo(
        localStore: store1,
        dataModeService: dataModeService,
        remoteRepo: remoteRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final newItem = const InventoryItemModel(
        id: 'INV-QA-1',
        name: 'Articaine 4%',
        code: 'ART-04',
        category: 'anesthesia',
        currentStock: 25,
        minStockAlert: 5,
        unit: 'box',
        unitCost: 13.0,
      );

      final addRes = await repo1.addItem(newItem);
      expect(addRes.isRight(), isTrue);

      // Rebuild store
      final store2 = InMemoryTransactionalStore(
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo2 = OfflineFirstInventoryRepo(
        localStore: store2,
        dataModeService: dataModeService,
        remoteRepo: remoteRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final items = (await repo2.getItems()).getOrElse(() => []);
      expect(items.any((i) => i.id == 'INV-QA-1' && i.unitCost == 13.0), isTrue);
    });
  });
}
