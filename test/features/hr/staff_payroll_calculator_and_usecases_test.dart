import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/hr/data/models/employee_ledger_entry_model.dart';
import 'package:eyadty/features/hr/data/models/enums/employee_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/ledger_entry_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/payroll_status_enum.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_item_model.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_period_model.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_profile_model.dart';
import 'package:eyadty/features/hr/data/repo/hr_mock_repo_impl.dart';
import 'package:eyadty/features/hr/domain/helpers/staff_payroll_calculator.dart';
import 'package:eyadty/features/hr/domain/use_cases/confirm_staff_payroll_period_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/generate_staff_payroll_period_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/payout_staff_payroll_period_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/save_staff_payroll_profile_use_case.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class PayrollTestUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  PayrollTestUserSessionProvider({this.user, this.branch = 'branch_1'});

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch;
}

class PayrollTestRolesSessionProvider implements RolesProvider {
  List<RoleDefinitionModel> roles;
  PayrollTestRolesSessionProvider({required this.roles});

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

void main() {
  group('Staff Payroll Domain Engine Tests (Plan F-06 M-4)', () {
    late HrMockRepoImpl repo;
    late InMemoryAuditLogger auditLogger;
    late PayrollTestUserSessionProvider userProvider;
    late PayrollTestRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;

    late GenerateStaffPayrollPeriodUseCase generateUseCase;
    late SaveStaffPayrollProfileUseCase saveProfileUseCase;
    late ConfirmStaffPayrollPeriodUseCase confirmUseCase;
    late PayoutStaffPayrollPeriodUseCase payoutUseCase;

    const hrRoleId = 'role_hr_payroll_specialist';
    final hrRole = RoleDefinitionModel(
      id: hrRoleId,
      nameAr: 'مسؤول رواتب',
      nameEn: 'Payroll Specialist',
      permissions: [
        StaffPermissionEnum.manageStaffPayroll,
        StaffPermissionEnum.accessHr,
      ],
    );

    setUp(() {
      repo = HrMockRepoImpl(seedInitialData: false);
      auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

      rolesProvider = PayrollTestRolesSessionProvider(
        roles: [...RoleDefinitionModel.defaultSystemRoles(), hrRole],
      );

      // Default authorized user: HR Payroll Specialist
      userProvider = PayrollTestUserSessionProvider(
        user: const StaffUserModel(
          id: 'usr_payroll_admin',
          fullName: 'عمرو رواتب',
          isActive: true,
          branchAssignments: [
            BranchAssignmentModel(branchId: 'branch_1', roleIds: [hrRoleId]),
          ],
        ),
      );

      permissionEvaluator = PermissionEvaluator(
        userProvider: userProvider,
        rolesProvider: rolesProvider,
      );

      generateUseCase = GenerateStaffPayrollPeriodUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
      );

      saveProfileUseCase = SaveStaffPayrollProfileUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
      );

      confirmUseCase = ConfirmStaffPayrollPeriodUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      payoutUseCase = PayoutStaffPayrollPeriodUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );
    });

    test('1. Calculates staff payroll items with base salary, allowances, and statutory deductions', () {
      final profiles = [
        const StaffPayrollProfileModel(
          id: 'PRF-01',
          staffUserId: 'usr_rec_1',
          fullName: 'أحمد استقبال',
          jobTitle: 'استقبال',
          primaryBranchId: 'branch_1',
          baseSalaryPiastres: 600000, // 6,000 EGP
          housingAllowancePiastres: 50000, // 500 EGP
          transportationAllowancePiastres: 50000, // 500 EGP
          insuranceDeductionPiastres: 40000, // 400 EGP
          taxDeductionPiastres: 20000, // 200 EGP
          isActive: true,
        ),
      ];

      final period = StaffPayrollCalculator.calculatePeriod(
        primaryBranchId: 'branch_1',
        month: 5,
        year: 2026,
        activeProfiles: profiles,
        ledgerEntries: [],
      );

      expect(period.totalEmployeesCount, 1);
      final item = period.items!.first;
      expect(item.baseSalaryPiastres, 600000);
      expect(item.totalAllowancesPiastres, 100000);
      expect(item.insuranceDeductionPiastres, 40000);
      expect(item.taxDeductionPiastres, 20000);
      // Net: 600000 + 100000 - 60000 = 640000 (6,400 EGP)
      expect(item.netSalaryPiastres, 640000);
      expect(period.totalNetPayablePiastres, 640000);
    });

    test('2. Deducts outstanding advances up to net earnings cap per employee', () {
      final profiles = [
        const StaffPayrollProfileModel(
          id: 'PRF-02',
          staffUserId: 'usr_nurse_1',
          fullName: 'هدى تمريض',
          primaryBranchId: 'branch_1',
          baseSalaryPiastres: 500000, // 5,000 EGP
          housingAllowancePiastres: 0,
          transportationAllowancePiastres: 0,
          insuranceDeductionPiastres: 0,
          taxDeductionPiastres: 0,
          isActive: true,
        ),
      ];

      // Outstanding advance of 2000 EGP (200000 piastres)
      final ledger = [
        EmployeeLedgerEntryModel(
          id: 'ADV-STF-01',
          employeeId: 'usr_nurse_1',
          employeeType: EmployeeTypeEnum.staff,
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 200000,
          branchId: 'branch_1',
        ),
      ];

      final period = StaffPayrollCalculator.calculatePeriod(
        primaryBranchId: 'branch_1',
        month: 5,
        year: 2026,
        activeProfiles: profiles,
        ledgerEntries: ledger,
      );

      final item = period.items!.first;
      expect(item.advancesDeductedPiastres, 200000);
      expect(item.netSalaryPiastres, 300000); // 500000 - 200000 = 300000
    });

    test('3. Incorporates ledger bonuses and manual deductions for the period', () {
      final profiles = [
        const StaffPayrollProfileModel(
          id: 'PRF-03',
          staffUserId: 'usr_cleaner_1',
          fullName: 'علي عامل',
          primaryBranchId: 'branch_1',
          baseSalaryPiastres: 400000,
          isActive: true,
        ),
      ];

      final ledger = [
        EmployeeLedgerEntryModel(
          id: 'BON-01',
          employeeId: 'usr_cleaner_1',
          employeeType: EmployeeTypeEnum.staff,
          entryType: LedgerEntryTypeEnum.bonus,
          amountPiastres: 50000, // 500 EGP bonus
          branchId: 'branch_1',
        ),
        EmployeeLedgerEntryModel(
          id: 'DED-01',
          employeeId: 'usr_cleaner_1',
          employeeType: EmployeeTypeEnum.staff,
          entryType: LedgerEntryTypeEnum.deduction,
          amountPiastres: 20000, // 200 EGP deduction
          branchId: 'branch_1',
        ),
      ];

      final period = StaffPayrollCalculator.calculatePeriod(
        primaryBranchId: 'branch_1',
        month: 5,
        year: 2026,
        activeProfiles: profiles,
        ledgerEntries: ledger,
      );

      final item = period.items!.first;
      expect(item.ledgerBonusesPiastres, 50000);
      expect(item.ledgerDeductionsPiastres, 20000);
      // Net: 400000 + 50000 - 20000 = 430000
      expect(item.netSalaryPiastres, 430000);
    });

    test('4. Generates monthly payroll period for target branch, month, and year', () async {
      await repo.saveStaffPayrollProfile(const StaffPayrollProfileModel(
        staffUserId: 'usr_staff_gen',
        fullName: 'عزة إدارية',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 500000,
        isActive: true,
      ));

      final res = await generateUseCase(
        primaryBranchId: 'branch_1',
        month: 6,
        year: 2026,
      );

      expect(res.isRight(), isTrue);
      final period = res.getOrElse(() => const StaffPayrollPeriodModel());
      expect(period.id, isNotNull);
      expect(period.month, 6);
      expect(period.year, 2026);
      expect(period.status, PayrollStatusEnum.draft);
      expect(period.totalEmployeesCount, 1);
    });

    test('5. Rejects duplicate payroll period generation for same branch, month, and year', () async {
      await repo.saveStaffPayrollProfile(const StaffPayrollProfileModel(
        staffUserId: 'usr_staff_dup',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 500000,
        isActive: true,
      ));

      final firstRes = await generateUseCase(
        primaryBranchId: 'branch_1',
        month: 7,
        year: 2026,
      );
      expect(firstRes.isRight(), isTrue);

      // Attempting to generate for same branch_1, month 7, year 2026 must be REJECTED
      final dupRes = await generateUseCase(
        primaryBranchId: 'branch_1',
        month: 7,
        year: 2026,
      );
      expect(dupRes.isLeft(), isTrue);
    });

    test('6. Inactive staff profiles are excluded from payroll period calculation', () async {
      // 1 active profile
      await repo.saveStaffPayrollProfile(const StaffPayrollProfileModel(
        staffUserId: 'usr_active',
        fullName: 'نشط',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 500000,
        isActive: true,
      ));
      // 1 inactive profile
      await repo.saveStaffPayrollProfile(const StaffPayrollProfileModel(
        staffUserId: 'usr_inactive',
        fullName: 'مستقيل',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 500000,
        isActive: false,
      ));

      final res = await generateUseCase(
        primaryBranchId: 'branch_1',
        month: 8,
        year: 2026,
      );

      expect(res.isRight(), isTrue);
      final period = res.getOrElse(() => const StaffPayrollPeriodModel());
      expect(period.totalEmployeesCount, 1);
      expect(period.items!.first.staffUserId, 'usr_active');
    });

    test('7. Saves staff payroll profile with positive financial bounds validation', () async {
      final res = await saveProfileUseCase(const StaffPayrollProfileModel(
        staffUserId: 'usr_new_01',
        fullName: 'سلمى سكرتيرة',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 450000,
        housingAllowancePiastres: 30000,
        transportationAllowancePiastres: 20000,
        insuranceDeductionPiastres: 25000,
        taxDeductionPiastres: 10000,
      ));

      expect(res.isRight(), isTrue);
      final saved = res.getOrElse(() => const StaffPayrollProfileModel());
      expect(saved.id, isNotNull);
      expect(saved.baseSalaryPiastres, 450000);
    });

    test('8. Rejects negative salary or allowance values when saving profile', () async {
      final negBaseRes = await saveProfileUseCase(const StaffPayrollProfileModel(
        staffUserId: 'usr_neg_1',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: -1000,
      ));
      expect(negBaseRes.isLeft(), isTrue);

      final negAllowanceRes = await saveProfileUseCase(const StaffPayrollProfileModel(
        staffUserId: 'usr_neg_2',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 500000,
        housingAllowancePiastres: -500,
      ));
      expect(negAllowanceRes.isLeft(), isTrue);
    });

    test('9. Staff payroll profile contains zero bank account information', () {
      const profile = StaffPayrollProfileModel(
        id: 'PRF-VERIFY',
        staffUserId: 'usr_001',
        fullName: 'موظف',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 500000,
      );

      final json = profile.toJson();
      expect(json.containsKey('bankAccountNumber'), isFalse);
      expect(json.containsKey('bankName'), isFalse);
      expect(json.containsKey('iban'), isFalse);
    });

    test('10. Confirm staff payroll period transitions status to confirmed and records authorizer', () async {
      final periodRes = await repo.saveStaffPayrollPeriod(const StaffPayrollPeriodModel(
        id: 'PAY-DRAFT-01',
        primaryBranchId: 'branch_1',
        month: 5,
        year: 2026,
        status: PayrollStatusEnum.draft,
        totalNetPayablePiastres: 1500000,
        totalEmployeesCount: 3,
      ));
      expect(periodRes.isRight(), isTrue);

      final confirmRes = await confirmUseCase(periodId: 'PAY-DRAFT-01');
      expect(confirmRes.isRight(), isTrue);
      final confirmed = confirmRes.getOrElse(() => const StaffPayrollPeriodModel());
      expect(confirmed.status, PayrollStatusEnum.confirmed);
      expect(confirmed.confirmedByUserId, 'usr_payroll_admin');
      expect(confirmed.confirmedAt, isNotNull);
    });

    test('11. Cannot confirm an already confirmed or paid staff payroll period', () async {
      await repo.saveStaffPayrollPeriod(const StaffPayrollPeriodModel(
        id: 'PAY-ALREADY-CONF',
        primaryBranchId: 'branch_1',
        month: 5,
        year: 2026,
        status: PayrollStatusEnum.confirmed,
      ));

      final res = await confirmUseCase(periodId: 'PAY-ALREADY-CONF');
      expect(res.isLeft(), isTrue);
    });

    test('12. Payout staff payroll period transitions status to paid and records timestamp', () async {
      await repo.saveStaffPayrollPeriod(const StaffPayrollPeriodModel(
        id: 'PAY-CONF-READY',
        primaryBranchId: 'branch_1',
        month: 5,
        year: 2026,
        status: PayrollStatusEnum.confirmed,
        totalNetPayablePiastres: 1200000,
      ));

      final res = await payoutUseCase(periodId: 'PAY-CONF-READY');
      expect(res.isRight(), isTrue);
      final paid = res.getOrElse(() => const StaffPayrollPeriodModel());
      expect(paid.status, PayrollStatusEnum.paid);
      expect(paid.paidAt, isNotNull);
    });

    test('13. Cannot payout an unconfirmed (draft) staff payroll period', () async {
      await repo.saveStaffPayrollPeriod(const StaffPayrollPeriodModel(
        id: 'PAY-DRAFT-UNCONF',
        primaryBranchId: 'branch_1',
        month: 5,
        year: 2026,
        status: PayrollStatusEnum.draft,
      ));

      final res = await payoutUseCase(periodId: 'PAY-DRAFT-UNCONF');
      expect(res.isLeft(), isTrue);
    });

    test('14. Cannot payout an already paid staff payroll period', () async {
      await repo.saveStaffPayrollPeriod(const StaffPayrollPeriodModel(
        id: 'PAY-PAID-ALREADY',
        primaryBranchId: 'branch_1',
        month: 5,
        year: 2026,
        status: PayrollStatusEnum.paid,
      ));

      final res = await payoutUseCase(periodId: 'PAY-PAID-ALREADY');
      expect(res.isLeft(), isTrue);
    });

    test('15. Payout staff payroll period creates individual payout entries in employee ledger', () async {
      await repo.saveStaffPayrollPeriod(const StaffPayrollPeriodModel(
        id: 'PAY-CONF-LEDGER',
        primaryBranchId: 'branch_1',
        month: 5,
        year: 2026,
        status: PayrollStatusEnum.confirmed,
        totalNetPayablePiastres: 1100000,
        items: [
          StaffPayrollItemModel(
            staffUserId: 'usr_staff_led_1',
            netSalaryPiastres: 600000,
          ),
          StaffPayrollItemModel(
            staffUserId: 'usr_staff_led_2',
            netSalaryPiastres: 500000,
          ),
        ],
      ));

      final res = await payoutUseCase(periodId: 'PAY-CONF-LEDGER');
      expect(res.isRight(), isTrue);

      final led1Res = await repo.getEmployeeLedgerEntries(employeeId: 'usr_staff_led_1');
      expect(led1Res.isRight(), isTrue);
      final entries1 = led1Res.getOrElse(() => []).where((e) => e.entryType == LedgerEntryTypeEnum.payout).toList();
      expect(entries1.length, 1);
      expect(entries1.first.amountPiastres, 600000);

      final led2Res = await repo.getEmployeeLedgerEntries(employeeId: 'usr_staff_led_2');
      expect(led2Res.isRight(), isTrue);
      final entries2 = led2Res.getOrElse(() => []).where((e) => e.entryType == LedgerEntryTypeEnum.payout).toList();
      expect(entries2.length, 1);
      expect(entries2.first.amountPiastres, 500000);
    });

    test('16. Unauthorized user cannot manage staff payroll (enforces manageStaffPayroll)', () async {
      // User with receptionist role (no manageStaffPayroll)
      userProvider.user = const StaffUserModel(
        id: 'usr_unauth',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.reception]),
        ],
      );

      final genRes = await generateUseCase(
        primaryBranchId: 'branch_1',
        month: 5,
        year: 2026,
      );
      expect(genRes.isLeft(), isTrue);

      final profRes = await saveProfileUseCase(const StaffPayrollProfileModel(
        staffUserId: 'usr_002',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 500000,
      ));
      expect(profRes.isLeft(), isTrue);
    });

    test('17. Emits staff_payroll_confirmed and staff_payroll_paid audit logs with numeric whitelist', () async {
      await repo.saveStaffPayrollPeriod(const StaffPayrollPeriodModel(
        id: 'PAY-AUDIT-TEST',
        primaryBranchId: 'branch_1',
        month: 5,
        year: 2026,
        status: PayrollStatusEnum.draft,
        totalNetPayablePiastres: 900000,
        totalEmployeesCount: 2,
      ));

      // 1. Confirm
      final confRes = await confirmUseCase(periodId: 'PAY-AUDIT-TEST');
      expect(confRes.isRight(), isTrue);

      final confLogs = auditLogger.getLogs(eventType: 'staff_payroll_confirmed');
      expect(confLogs.length, 1);
      final cLog = confLogs.first;
      expect(cLog.details, contains('periodMonth: 5'));
      expect(cLog.details, contains('periodYear: 2026'));
      expect(cLog.details, contains('totalNetPayablePiastres: 900000'));
      expect(cLog.details, contains('employeesCount: 2'));

      // 2. Payout
      final payRes = await payoutUseCase(periodId: 'PAY-AUDIT-TEST');
      expect(payRes.isRight(), isTrue);

      final payLogs = auditLogger.getLogs(eventType: 'staff_payroll_paid');
      expect(payLogs.length, 1);
      final pLog = payLogs.first;
      expect(pLog.details, contains('totalAmountPiastres: 900000'));
      expect(pLog.details, contains('paidByUserId: usr_payroll_admin'));

      // Strict privacy check
      for (final l in auditLogger.getLogs()) {
        expect(l.details, isNot(contains('patient')));
        expect(l.details, isNot(contains('diagnosis')));
      }
    });

    test('18. Zero audit logs emitted on validation or authorization failure', () async {
      final initialLogsCount = auditLogger.getLogs().length;

      // 1. Non-existent period confirmation
      final nonExistentRes = await confirmUseCase(periodId: 'NON-EXISTENT-PERIOD');
      expect(nonExistentRes.isLeft(), isTrue);
      expect(auditLogger.getLogs().length, initialLogsCount);

      // 2. Unauthorized payout
      userProvider.user = const StaffUserModel(
        id: 'usr_unauth',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.reception]),
        ],
      );

      final unauthPayRes = await payoutUseCase(periodId: 'PAY-AUDIT-TEST');
      expect(unauthPayRes.isLeft(), isTrue);
      expect(auditLogger.getLogs().length, initialLogsCount);
    });
  });
}
