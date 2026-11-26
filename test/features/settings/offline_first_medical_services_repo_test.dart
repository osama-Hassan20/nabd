import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/repositories/offline_first_medical_services_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/features/settings/data/repo/medical_services_mock_repo_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DataModeService dataModeService;
  late MedicalServicesMockRepoImpl remoteRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataModeService = DataModeService(
      reachabilityProbe: (_, __) async => true,
      initialReachable: true,
    );
    remoteRepo = MedicalServicesMockRepoImpl();
  });

  tearDown(() {
    dataModeService.dispose();
  });

  group('OfflineFirstMedicalServicesRepo Rehydrate Tests (A2, A5h)', () {
    test('1. Service add survives store rebuild from storage (A2)', () async {
      final sharedStorage = <String, String>{};
      final store1 = InMemoryTransactionalStore(
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo1 = OfflineFirstMedicalServicesRepo(
        localStore: store1,
        dataModeService: dataModeService,
        remoteRepo: remoteRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final newService = const MedicalServiceModel(
        id: 'SRV-QA-100',
        name: 'خدمة QA اختبار',
        consultationFee: 250.0,
        category: 'dental',
        isActive: true,
      );

      final addRes = await repo1.addMedicalService(newService);
      expect(addRes.isRight(), isTrue);

      // Rebuild store from storage
      final store2 = InMemoryTransactionalStore(
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo2 = OfflineFirstMedicalServicesRepo(
        localStore: store2,
        dataModeService: dataModeService,
        remoteRepo: remoteRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final listRes = await repo2.getMedicalServices();
      expect(listRes.isRight(), isTrue);
      final list = listRes.getOrElse(() => []);
      expect(list.any((s) => s.id == 'SRV-QA-100' && s.name == 'خدمة QA اختبار'), isTrue);
    });

    test('2. Service edit survives store rebuild from storage (A5h)', () async {
      final sharedStorage = <String, String>{};
      final store1 = InMemoryTransactionalStore(
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo1 = OfflineFirstMedicalServicesRepo(
        localStore: store1,
        dataModeService: dataModeService,
        remoteRepo: remoteRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      // Add then edit
      final initialService = const MedicalServiceModel(
        id: 'SRV-QA-200',
        name: 'كشف استشاري',
        consultationFee: 300.0,
        isActive: true,
      );
      await repo1.addMedicalService(initialService);

      final updatedService = initialService.copyWith(consultationFee: 320.0);
      final updateRes = await repo1.updateMedicalService(updatedService);
      expect(updateRes.isRight(), isTrue);

      // Rebuild store
      final store2 = InMemoryTransactionalStore(
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo2 = OfflineFirstMedicalServicesRepo(
        localStore: store2,
        dataModeService: dataModeService,
        remoteRepo: remoteRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final srv = (await repo2.getMedicalServiceById('SRV-QA-200')).getOrElse(() => throw 'not found');
      expect(srv.consultationFee, 320.0);
    });
  });
}
