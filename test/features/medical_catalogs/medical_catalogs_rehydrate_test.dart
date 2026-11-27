import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/repositories/offline_first_medical_catalogs_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/features/medical_catalogs/data/models/enums/medical_catalog_kind_enum.dart';
import 'package:eyadty/features/medical_catalogs/data/models/medical_catalog_entry_model.dart';
import 'package:eyadty/features/medical_catalogs/data/repo/medical_catalogs_repo_impl.dart';

void main() {
  late InMemoryTransactionalStore store;
  late MedicalCatalogsRepoImpl mockRemoteRepo;
  late DataModeService dataModeService;
  late OfflineFirstMedicalCatalogsRepo repo;

  setUp(() {
    store = InMemoryTransactionalStore();
    mockRemoteRepo = MedicalCatalogsRepoImpl(apiConsumer: LocalServerApiConsumer());
    dataModeService = DataModeService();
    repo = OfflineFirstMedicalCatalogsRepo(
      localStore: store,
      remoteRepo: mockRemoteRepo,
      dataModeService: dataModeService,
      getCurrentAccountId: () => 'acc-1',
      getCurrentBranchId: () => 'branch-1',
    );
  });

  group('A4 & A5e: Medical Catalogs Rehydrate & Category Filter', () {
    test('getEntries returns all entries when category is "الكل"', () async {
      final entry = MedicalCatalogEntryModel(
        id: 'CAT-RAD-QA-1',
        name: 'أشعة بانوراما QA',
        code: 'RAD-001',
        kind: MedicalCatalogKindEnum.radiology,
        category: 'بانوراما',
        createdAt: DateTime.now(),
      );

      final addRes = await repo.addEntry(entry);
      expect(addRes.isRight(), isTrue);

      // Fetch with category 'الكل' (which is the default selectedCategory in MedicalCatalogsCubit)
      final fetchRes = await repo.getEntries(
        kind: MedicalCatalogKindEnum.radiology,
        category: 'الكل',
      );

      expect(fetchRes.isRight(), isTrue);
      final items = fetchRes.getOrElse(() => []);
      expect(items.any((e) => e.id == 'CAT-RAD-QA-1'), isTrue,
          reason: 'Item should be returned when category filter is "الكل"');
    });

    test('all 5 catalog kinds return non-empty lists when category is "الكل"', () async {
      for (final kind in MedicalCatalogKindEnum.values) {
        final res = await repo.getEntries(kind: kind, category: 'الكل');
        expect(res.isRight(), isTrue);
        final list = res.getOrElse(() => []);
        expect(list.isNotEmpty, isTrue,
            reason: 'Kind ${kind.name} should return initial items when category is "الكل"');
      }
    });
  });
}
