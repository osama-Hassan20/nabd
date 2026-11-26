import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/repositories/offline_first_cashier_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_doctors_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_hr_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_medical_catalogs_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_settings_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_staff_users_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/features/cashier/data/repo/cashier_mock_repo_impl.dart';
import 'package:eyadty/features/cashier/domain/repo/cashier_repo.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/data/repo/doctors_mock_repo_impl.dart';
import 'package:eyadty/features/doctors/domain/repo/doctors_repo.dart';
import 'package:eyadty/features/hr/data/models/doctor_compensation_rule_model.dart';
import 'package:eyadty/features/hr/data/repo/hr_mock_repo_impl.dart';
import 'package:eyadty/features/hr/domain/repo/hr_repo.dart';
import 'package:eyadty/features/medical_catalogs/data/models/enums/medical_catalog_kind_enum.dart';
import 'package:eyadty/features/medical_catalogs/data/models/medical_catalog_entry_model.dart';
import 'package:eyadty/features/medical_catalogs/data/repo/medical_catalogs_mock_repo_impl.dart';
import 'package:eyadty/features/medical_catalogs/domain/repo/medical_catalogs_repo.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/enums/clinic_type_enum.dart';
import 'package:eyadty/features/settings/data/repo/settings_mock_repo_impl.dart';
import 'package:eyadty/features/settings/domain/repo/settings_repo.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_mock_repo_impl.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryTransactionalStore store;
  late DataModeService dataModeService;

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
  });

  group('Offline Cashier Durability & Idempotency', () {
    test('Cashier open shift, payment with idempotency, and reload durability', () async {
      final mockCashier = CashierMockRepoImpl(seedInitialData: false);
      final cashierRepo = OfflineFirstCashierRepo(
        localStore: store,
        dataModeService: dataModeService,
        remoteRepo: mockCashier,
        getCurrentAccountId: () => 'acc_test',
        getCurrentBranchId: () => 'branch_1',
      );

      // 1. Open shift
      final openRes = await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-001',
        cashierName: 'أحمد الصراف',
        openingBalancePiastres: 50000,
      );
      expect(openRes.isRight(), isTrue);
      final shift = openRes.getOrElse(() => throw Exception());
      expect(shift.openingBalancePiastres, 50000);

      // 2. Record payment with idempotency key
      final payRes1 = await cashierRepo.recordPayment(
        clientRequestId: 'REQ-IDEMP-001',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'BOOKING-100',
        patientId: 'PAT-100',
        patientName: 'محمد سعيد',
        amountPiastres: 25000,
        paymentMethod: 'cash',
        cashierUserId: 'USER-001',
        cashierName: 'أحمد الصراف',
      );
      expect(payRes1.isRight(), isTrue);
      final payment1 = payRes1.getOrElse(() => throw Exception());
      expect(payment1.amountPiastres, 25000);

      // 3. Duplicate payment call with SAME clientRequestId must return cached without second charge
      final payResDuplicate = await cashierRepo.recordPayment(
        clientRequestId: 'REQ-IDEMP-001',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'BOOKING-100',
        patientId: 'PAT-100',
        patientName: 'محمد سعيد',
        amountPiastres: 25000,
        paymentMethod: 'cash',
        cashierUserId: 'USER-001',
        cashierName: 'أحمد الصراف',
      );
      expect(payResDuplicate.isRight(), isTrue);
      final paymentDup = payResDuplicate.getOrElse(() => throw Exception());
      expect(paymentDup.id, payment1.id);

      // 4. Verify outbox contains shift and payment
      final pendingOutbox = await store.getPendingOutboxEntries();
      expect(pendingOutbox.any((e) => e.entityType == 'cashier_shift'), isTrue);
      expect(pendingOutbox.any((e) => e.entityType == 'cashier_payment'), isTrue);

      // 5. Reload store to simulate browser restart
      final restartedStore = InMemoryTransactionalStore(
        dataModeService: DataModeService(initialReachable: false),
        persistToStorage: true,
      );
      final restartedRepo = OfflineFirstCashierRepo(
        localStore: restartedStore,
        dataModeService: DataModeService(initialReachable: false),
        remoteRepo: CashierMockRepoImpl(seedInitialData: false),
        getCurrentAccountId: () => 'acc_test',
        getCurrentBranchId: () => 'branch_1',
      );

      final restoredPayments = await restartedRepo.getPaymentsForShift(shiftId: shift.id!);
      expect(restoredPayments.isRight(), isTrue);
      expect(restoredPayments.getOrElse(() => []).length, 1);
      expect(restoredPayments.getOrElse(() => []).first.clientRequestId, 'REQ-IDEMP-001');
    });
  });

  group('Offline Medical Catalogs Durability', () {
    test('Add, search, delete, and reload catalogs', () async {
      final mockCatalogs = MedicalCatalogsMockRepoImpl();
      final catalogsRepo = OfflineFirstMedicalCatalogsRepo(
        localStore: store,
        dataModeService: dataModeService,
        remoteRepo: mockCatalogs,
        getCurrentAccountId: () => 'acc_test',
        getCurrentBranchId: () => 'branch_1',
      );

      // 1. Add custom radiology entry offline
      final entry = MedicalCatalogEntryModel(
        id: 'RAD-CUSTOM-001',
        name: 'أشعة رنين مغناطيسي متقدمة على الكاحل',
        code: 'MRI-ANKLE',
        kind: MedicalCatalogKindEnum.radiology,
        category: 'رنين مغناطيسي (MRI)',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final addRes = await catalogsRepo.addEntry(entry);
      expect(addRes.isRight(), isTrue);

      // 2. Query catalogs
      final listRes = await catalogsRepo.getEntries(
        kind: MedicalCatalogKindEnum.radiology,
        query: 'الكاحل',
      );
      expect(listRes.isRight(), isTrue);
      expect(listRes.getOrElse(() => []).any((e) => e.id == 'RAD-CUSTOM-001'), isTrue);

      // 3. Reload store and verify persistence
      final restartedStore = InMemoryTransactionalStore(
        dataModeService: DataModeService(initialReachable: false),
        persistToStorage: true,
      );
      final restartedRepo = OfflineFirstMedicalCatalogsRepo(
        localStore: restartedStore,
        dataModeService: DataModeService(initialReachable: false),
        remoteRepo: MedicalCatalogsMockRepoImpl(),
        getCurrentAccountId: () => 'acc_test',
        getCurrentBranchId: () => 'branch_1',
      );

      final restoredList = await restartedRepo.getEntries(
        kind: MedicalCatalogKindEnum.radiology,
        query: 'الكاحل',
      );
      expect(restoredList.isRight(), isTrue);
      expect(restoredList.getOrElse(() => []).any((e) => e.id == 'RAD-CUSTOM-001'), isTrue);
    });
  });

  group('Offline Settings & HR Durability', () {
    test('Company settings update survives reload', () async {
      final settingsRepo = OfflineFirstSettingsRepo(
        localStore: store,
        dataModeService: dataModeService,
        remoteRepo: SettingsMockRepoImpl(),
        getCurrentAccountId: () => 'acc_test',
        getCurrentBranchId: () => 'branch_1',
      );

      final updatedSettings = CompanySettingsModel(
        id: 'SETT-001',
        companyName: 'مجمع عيادتي التخصصي المتطور',
        clinicType: ClinicTypeEnum.polyclinic,
        defaultHourlyRate: 350,
      );

      final saveRes = await settingsRepo.updateCompanySettings(updatedSettings);
      expect(saveRes.isRight(), isTrue);

      // Reload
      final restartedStore = InMemoryTransactionalStore(
        dataModeService: DataModeService(initialReachable: false),
        persistToStorage: true,
      );
      final restartedSettings = OfflineFirstSettingsRepo(
        localStore: restartedStore,
        dataModeService: DataModeService(initialReachable: false),
        remoteRepo: SettingsMockRepoImpl(),
        getCurrentAccountId: () => 'acc_test',
        getCurrentBranchId: () => 'branch_1',
      );

      final loaded = await restartedSettings.getCompanySettings();
      expect(loaded.isRight(), isTrue);
      expect(loaded.getOrElse(() => throw Exception()).companyName, 'مجمع عيادتي التخصصي المتطور');
    });

    test('HR compensation rule survives reload', () async {
      final hrRepo = OfflineFirstHrRepo(
        localStore: store,
        dataModeService: dataModeService,
        remoteRepo: HrMockRepoImpl(seedInitialData: false),
        getCurrentAccountId: () => 'acc_test',
        getCurrentBranchId: () => 'branch_1',
      );

      final rule = DoctorCompensationRuleModel(
        id: 'RULE-DOC-99',
        doctorId: 'DOC-99',
        branchId: 'branch_1',
        commissionPercentage: 60,
        isActive: true,
      );

      final saveRes = await hrRepo.saveCompensationRule(rule);
      expect(saveRes.isRight(), isTrue);

      // Reload
      final restartedStore = InMemoryTransactionalStore(
        dataModeService: DataModeService(initialReachable: false),
        persistToStorage: true,
      );
      final restartedHr = OfflineFirstHrRepo(
        localStore: restartedStore,
        dataModeService: DataModeService(initialReachable: false),
        remoteRepo: HrMockRepoImpl(seedInitialData: false),
        getCurrentAccountId: () => 'acc_test',
        getCurrentBranchId: () => 'branch_1',
      );

      final loadedRule = await restartedHr.getCompensationRuleById('RULE-DOC-99');
      expect(loadedRule.isRight(), isTrue);
      expect(loadedRule.getOrElse(() => throw Exception()).commissionPercentage, 60);
    });
  });

  group('DI Integrity for All Offline Repos', () {
    setUp(() async {
      await getIt.reset();
      await setupGetIt();
    });

    tearDown(() async {
      await getIt.reset();
    });

    test('All core repositories resolve to OfflineFirst implementations', () {
      expect(getIt<CashierRepo>(), isA<OfflineFirstCashierRepo>());
      expect(getIt<MedicalCatalogsRepo>(), isA<OfflineFirstMedicalCatalogsRepo>());
      expect(getIt<SettingsRepo>(), isA<OfflineFirstSettingsRepo>());
      expect(getIt<HrRepo>(), isA<OfflineFirstHrRepo>());
      expect(getIt<DoctorsRepo>(), isA<OfflineFirstDoctorsRepo>());
      expect(getIt<StaffUsersRepo>(), isA<OfflineFirstStaffUsersRepo>());
    });
  });
}
