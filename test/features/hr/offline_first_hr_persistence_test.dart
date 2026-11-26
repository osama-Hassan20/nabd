import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/repositories/offline_first_hr_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/features/hr/data/models/employee_ledger_entry_model.dart';
import 'package:eyadty/features/hr/data/models/enums/ledger_entry_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/payroll_status_enum.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_period_model.dart';
import 'package:eyadty/features/hr/data/repo/hr_mock_repo_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DataModeService dataModeService;
  late HrMockRepoImpl remoteRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataModeService = DataModeService(
      reachabilityProbe: (_, __) async => true,
      initialReachable: true,
    );
    remoteRepo = HrMockRepoImpl();
  });

  tearDown(() {
    dataModeService.dispose();
  });

  group('OfflineFirstHrRepo Rehydrate & Durability Tests (A3, A5b, A5i)', () {
    test('1. HR advance ledger entry survives store rebuild from storage (A3)', () async {
      final sharedStorage = <String, String>{};
      final store1 = InMemoryTransactionalStore(
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo1 = OfflineFirstHrRepo(
        localStore: store1,
        dataModeService: dataModeService,
        remoteRepo: remoteRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final entry = EmployeeLedgerEntryModel(
        id: 'LED-101',
        employeeId: 'USR-001',
        branchId: 'branch_1',
        entryType: LedgerEntryTypeEnum.advance,
        amountPiastres: 15000,
        reason: 'QA advance',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final addRes = await repo1.addEmployeeLedgerEntry(entry);
      expect(addRes.isRight(), isTrue);

      // Rebuild store from storage
      final store2 = InMemoryTransactionalStore(
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo2 = OfflineFirstHrRepo(
        localStore: store2,
        dataModeService: dataModeService,
        remoteRepo: remoteRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final entriesRes = await repo2.getEmployeeLedgerEntries(employeeId: 'USR-001');
      expect(entriesRes.isRight(), isTrue);
      final entries = entriesRes.getOrElse(() => []);
      expect(entries.any((e) => e.id == 'LED-101' && e.amountPiastres == 15000), isTrue);
    });

    test('2. Staff payroll generation and confirmation survive store rebuild (A5b)', () async {
      final sharedStorage = <String, String>{};
      final store1 = InMemoryTransactionalStore(
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo1 = OfflineFirstHrRepo(
        localStore: store1,
        dataModeService: dataModeService,
        remoteRepo: remoteRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final period = StaffPayrollPeriodModel(
        id: 'PAY-11-2026',
        payrollNumber: 'PAY-11-2026',
        month: 11,
        year: 2026,
        status: PayrollStatusEnum.confirmed,
        primaryBranchId: 'branch_1',
        totalNetPayablePiastres: 2400000,
        createdAt: DateTime.now(),
      );

      final saveRes = await repo1.saveStaffPayrollPeriod(period);
      expect(saveRes.isRight(), isTrue);

      // Rebuild store
      final store2 = InMemoryTransactionalStore(
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo2 = OfflineFirstHrRepo(
        localStore: store2,
        dataModeService: dataModeService,
        remoteRepo: remoteRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final periodsRes = await repo2.getStaffPayrollPeriods(primaryBranchId: 'branch_1');
      expect(periodsRes.isRight(), isTrue);
      final periods = periodsRes.getOrElse(() => []);
      expect(periods.any((p) => p.id == 'PAY-11-2026' && p.status == PayrollStatusEnum.confirmed), isTrue);
    });
  });
}
