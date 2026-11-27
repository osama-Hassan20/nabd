import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/repositories/offline_first_drugs_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/features/drugs/data/models/drug_model.dart';
import 'package:eyadty/features/drugs/data/repo/drugs_repo_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryTransactionalStore store;
  late DataModeService dataModeService;
  late DrugsRepoImpl mockRemote;
  late OfflineFirstDrugsRepo repo;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
  });

  setUp(() {
    dataModeService = DataModeService(
      reachabilityProbe: (url, timeout) async => false,
      initialReachable: false,
    );

    store = InMemoryTransactionalStore(
      dataModeService: dataModeService,
      persistToStorage: true,
    );

    mockRemote = DrugsRepoImpl(apiConsumer: LocalServerApiConsumer());

    repo = OfflineFirstDrugsRepo(
      localStore: store,
      dataModeService: dataModeService,
      remoteRepo: mockRemote,
      getCurrentAccountId: () => 'acc_test',
      getCurrentBranchId: () => 'branch_test',
    );
  });

  test('Adding a drug while offline stores locally, creates an OutboxEntry, and increments header counter', () async {
    // 1. Initial pending count is 0
    expect(dataModeService.state.pendingOutboxCount, 0);

    // 2. Add a new drug offline
    const newDrug = DrugModel(
      name: 'بانادول اكسترا جديد',
      scientificName: 'Paracetamol + Caffeine',
      concentration: '500mg/65mg',
      defaultDosage: 'قرصين',
    );

    final result = await repo.addDrug(newDrug);
    expect(result.isRight(), isTrue);

    final saved = result.getOrElse(() => throw Exception());
    expect(saved.id, isNotNull);
    expect(saved.name, 'بانادول اكسترا جديد');

    // 3. Outbox count in DataModeService updated to 1
    expect(dataModeService.state.pendingOutboxCount, 1);

    // 4. Inspect store directly
    final pendingOutbox = await store.getPendingOutboxEntries();
    expect(pendingOutbox.length, 1);
    expect(pendingOutbox.first.entityType, 'drug');
    expect(pendingOutbox.first.localId, saved.id);
    expect(pendingOutbox.first.operation, OutboxOperationType.create);

    // 5. Fetch drugs offline: new drug is in the list
    final drugsRes = await repo.getDrugs(query: 'بانادول');
    expect(drugsRes.isRight(), isTrue);
    final drugs = drugsRes.getOrElse(() => []);
    expect(drugs.any((d) => d.id == saved.id), isTrue);
  });

  test('Store persists to SharedPreferences and restores offline outbox across app restarts', () async {
    const drug = DrugModel(
      name: 'اموكسيلين تجريبي',
      concentration: '1000mg',
    );
    await repo.addDrug(drug);
    expect(dataModeService.state.pendingOutboxCount, greaterThan(0));

    // Simulate complete app restart by creating a new store instance with persistence enabled
    final newService = DataModeService();
    final restoredStore = InMemoryTransactionalStore(
      dataModeService: newService,
      persistToStorage: true,
    );

    final restoredOutbox = await restoredStore.getPendingOutboxEntries();
    expect(restoredOutbox.length, greaterThan(0));
    expect(restoredOutbox.any((e) => e.entityType == 'drug'), isTrue);
    expect(newService.state.pendingOutboxCount, restoredOutbox.length);
  });
}
