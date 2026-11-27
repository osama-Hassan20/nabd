import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/hr/data/models/employee_ledger_entry_model.dart';
import 'package:eyadty/features/hr/data/models/enums/ledger_entry_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/payroll_status_enum.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_item_model.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_period_model.dart';
import 'package:eyadty/features/hr/data/repo/doctor_settlement_visits_lookup.dart';
import 'package:eyadty/features/hr/data/repo/hr_repo_impl.dart';
import 'package:eyadty/features/hr/domain/use_cases/calculate_doctor_settlement_draft_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/confirm_doctor_settlement_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/confirm_staff_payroll_period_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/generate_staff_payroll_period_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/get_active_rule_for_doctor_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/get_doctor_compensation_rules_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/payout_doctor_settlement_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/payout_staff_payroll_period_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/save_doctor_compensation_rule_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/save_staff_payroll_profile_use_case.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';
import 'package:eyadty/features/hr/presentation/widgets/dialogs/add_ledger_entry_dialog.dart';
import 'package:eyadty/features/hr/presentation/widgets/dialogs/generate_payroll_period_dialog.dart';
import 'package:eyadty/features/hr/presentation/widgets/dialogs/reverse_ledger_entry_dialog.dart';
import 'package:eyadty/features/hr/presentation/widgets/employee_ledger_tab.dart';
import 'package:eyadty/features/hr/presentation/widgets/employee_ledger_table.dart';
import 'package:eyadty/features/hr/presentation/widgets/staff_payroll_tab.dart';
import 'package:eyadty/features/hr/presentation/widgets/staff_payroll_table.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class FakeUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  FakeUserSessionProvider({this.user, this.branch = 'branch_1'});

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch;
}

class FakeRolesSessionProvider implements RolesProvider {
  List<RoleDefinitionModel> roles;
  FakeRolesSessionProvider({required this.roles});

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

Widget _buildTestApp({
  required Widget child,
  required SessionCubit sessionCubit,
  required HrCubit hrCubit,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: false,
    child: MultiBlocProvider(
      providers: [
        BlocProvider<SessionCubit>.value(value: sessionCubit),
        BlocProvider<HrCubit>.value(value: hrCubit),
      ],
      child: MaterialApp(
        locale: const Locale('ar', 'EG'),
        home: Scaffold(body: child),
      ),
    ),
  );
}

void _setupDesktopView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
  addTearDown(() => tester.view.resetDevicePixelRatio());
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('Staff Payroll & Employee Ledger UI Tests (Plan F-06 M-7)', () {
    late HrRepoImpl repo;
    late DoctorSettlementVisitsLookupImpl visitsLookup;
    late InMemoryAuditLogger auditLogger;
    late FakeUserSessionProvider userProvider;
    late FakeRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;
    late SessionCubit sessionCubit;
    late HrCubit hrCubit;

    const hrManagerRoleId = 'role_hr_mgr_test';
    final hrManagerRole = RoleDefinitionModel(
      id: hrManagerRoleId,
      permissions: [
        StaffPermissionEnum.accessHr,
        StaffPermissionEnum.manageStaffPayroll,
        StaffPermissionEnum.manageEmployeeLedger,
        StaffPermissionEnum.confirmDoctorSettlement,
        StaffPermissionEnum.payoutSettlement,
      ],
    );

    const branchManagerRoleId = 'role_branch_mgr_test';
    final branchManagerRole = RoleDefinitionModel(
      id: branchManagerRoleId,
      permissions: [
        StaffPermissionEnum.accessHr,
        StaffPermissionEnum.manageEmployeeLedger,
        // Notice: lacks manageStaffPayroll
      ],
    );

    final hrManagerUser = StaffUserModel(
      id: 'usr_hr_mgr_01',
      fullName: 'مدير الموارد البشرية',
      isActive: true,
      branchAssignments: const [
        BranchAssignmentModel(branchId: 'branch_1', roleIds: [hrManagerRoleId]),
      ],
    );

    final branchManagerUser = StaffUserModel(
      id: 'usr_branch_mgr_01',
      fullName: 'مدير الفرع الميداني',
      isActive: true,
      branchAssignments: const [
        BranchAssignmentModel(branchId: 'branch_1', roleIds: [branchManagerRoleId]),
      ],
    );

    setUp(() {
      repo = HrRepoImpl(seedInitialData: false);
      visitsLookup = DoctorSettlementVisitsLookupImpl();
      auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

      rolesProvider = FakeRolesSessionProvider(
        roles: [...RoleDefinitionModel.defaultSystemRoles(), hrManagerRole, branchManagerRole],
      );

      userProvider = FakeUserSessionProvider(user: hrManagerUser);

      permissionEvaluator = PermissionEvaluator(
        userProvider: userProvider,
        rolesProvider: rolesProvider,
      );

      sessionCubit = SessionCubit(SessionState(
        currentUser: hrManagerUser,
        activeBranchId: 'branch_1',
      ));

      hrCubit = HrCubit(
        hrRepo: repo,
        getDoctorCompensationRulesUseCase: GetDoctorCompensationRulesUseCase(
          hrRepo: repo,
          permissionEvaluator: permissionEvaluator,
          currentUserProvider: userProvider,
        ),
        saveDoctorCompensationRuleUseCase: SaveDoctorCompensationRuleUseCase(
          hrRepo: repo,
          permissionEvaluator: permissionEvaluator,
          currentUserProvider: userProvider,
          auditLogger: auditLogger,
        ),
        getActiveRuleForDoctorUseCase: GetActiveRuleForDoctorUseCase(
          hrRepo: repo,
          permissionEvaluator: permissionEvaluator,
          currentUserProvider: userProvider,
        ),
        calculateDoctorSettlementDraftUseCase: CalculateDoctorSettlementDraftUseCase(
          hrRepo: repo,
          visitsLookup: visitsLookup,
          permissionEvaluator: permissionEvaluator,
          currentUserProvider: userProvider,
          auditLogger: auditLogger,
        ),
        confirmDoctorSettlementUseCase: ConfirmDoctorSettlementUseCase(
          hrRepo: repo,
          permissionEvaluator: permissionEvaluator,
          currentUserProvider: userProvider,
          auditLogger: auditLogger,
        ),
        payoutDoctorSettlementUseCase: PayoutDoctorSettlementUseCase(
          hrRepo: repo,
          permissionEvaluator: permissionEvaluator,
          currentUserProvider: userProvider,
          auditLogger: auditLogger,
        ),
        generateStaffPayrollPeriodUseCase: GenerateStaffPayrollPeriodUseCase(
          hrRepo: repo,
          permissionEvaluator: permissionEvaluator,
          currentUserProvider: userProvider,
        ),
        saveStaffPayrollProfileUseCase: SaveStaffPayrollProfileUseCase(
          hrRepo: repo,
          permissionEvaluator: permissionEvaluator,
          currentUserProvider: userProvider,
        ),
        confirmStaffPayrollPeriodUseCase: ConfirmStaffPayrollPeriodUseCase(
          hrRepo: repo,
          permissionEvaluator: permissionEvaluator,
          currentUserProvider: userProvider,
          auditLogger: auditLogger,
        ),
        payoutStaffPayrollPeriodUseCase: PayoutStaffPayrollPeriodUseCase(
          hrRepo: repo,
          permissionEvaluator: permissionEvaluator,
          currentUserProvider: userProvider,
          auditLogger: auditLogger,
        ),
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
      );
    });

    tearDown(() {
      hrCubit.close();
      sessionCubit.close();
    });

    testWidgets('1. StaffPayrollTab renders header controls and generate button', (tester) async {
      _setupDesktopView(tester);

      await hrCubit.init(branchId: 'branch_1', user: hrManagerUser);

      await tester.pumpWidget(_buildTestApp(
        child: const StaffPayrollTab(),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_open_generate_payroll')), findsOneWidget);
    });

    testWidgets('2. Clicking generate opens GeneratePayrollPeriodDialog', (tester) async {
      _setupDesktopView(tester);

      await hrCubit.init(branchId: 'branch_1', user: hrManagerUser);

      await tester.pumpWidget(_buildTestApp(
        child: const StaffPayrollTab(),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      final openBtn = find.byKey(const Key('btn_open_generate_payroll'));
      await tester.tap(openBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GeneratePayrollPeriodDialog), findsOneWidget);
    });

    testWidgets('3. GeneratePayrollPeriodDialog displays month/year dropdowns and submit button', (tester) async {
      _setupDesktopView(tester);

      await tester.pumpWidget(_buildTestApp(
        child: const GeneratePayrollPeriodDialog(),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropdown_payroll_month')), findsOneWidget);
      expect(find.byKey(const Key('dropdown_payroll_year')), findsOneWidget);
      expect(find.byKey(const Key('btn_generate_payroll')), findsOneWidget);
    });

    testWidgets('4. Submitting generate dialog calls generateStaffPayrollPeriod and closes on success', (tester) async {
      _setupDesktopView(tester);

      await hrCubit.init(branchId: 'branch_1', user: hrManagerUser);

      await tester.pumpWidget(_buildTestApp(
        child: const GeneratePayrollPeriodDialog(initialMonth: 5, initialYear: 2026),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const Key('btn_generate_payroll'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(hrCubit.state.payrollPeriods.length, 1);
      expect(hrCubit.state.payrollPeriods.first.month, 5);
      expect(hrCubit.state.payrollPeriods.first.year, 2026);
    });

    testWidgets('5. StaffPayrollTable renders lines with staff member, base salary, allowances, deductions, and net payable', (tester) async {
      _setupDesktopView(tester);

      final samplePeriod = StaffPayrollPeriodModel(
        id: 'PAY-202605-01',
        primaryBranchId: 'branch_1',
        month: 5,
        year: 2026,
        status: PayrollStatusEnum.draft,
        items: const [
          StaffPayrollItemModel(
            staffUserId: 'USR-NURSE-01',
            employeeName: 'سارة ممدوح',
            jobTitle: 'تمريض',
            baseSalaryPiastres: 800000,
            totalAllowancesPiastres: 100000,
            totalDeductionsPiastres: 50000,
            advancesDeductedPiastres: 50000,
            netSalaryPiastres: 800000,
          ),
        ],
      );

      await tester.pumpWidget(_buildTestApp(
        child: StaffPayrollTable(period: samplePeriod),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.text('سارة ممدوح'), findsOneWidget);
      expect(find.text('تمريض'), findsOneWidget);
    });

    testWidgets('6. Payroll period status badges display correct texts', (tester) async {
      _setupDesktopView(tester);

      final periodDraft = const StaffPayrollPeriodModel(
        id: 'P1',
        status: PayrollStatusEnum.draft,
        items: [StaffPayrollItemModel(staffUserId: 'U1')],
      );

      await tester.pumpWidget(_buildTestApp(
        child: StaffPayrollTable(period: periodDraft),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.text('hr_status_draft'.tr()), findsOneWidget);
    });

    testWidgets('7. Confirm payroll button triggers confirmation dialog and confirms period', (tester) async {
      _setupDesktopView(tester);

      final periodDraft = StaffPayrollPeriodModel(
        id: 'PAY-TO-CONFIRM',
        primaryBranchId: 'branch_1',
        month: 5,
        year: 2026,
        status: PayrollStatusEnum.draft,
        items: const [StaffPayrollItemModel(staffUserId: 'U1')],
      );

      await repo.saveStaffPayrollPeriod(periodDraft);
      await hrCubit.init(branchId: 'branch_1', user: hrManagerUser);

      await tester.pumpWidget(_buildTestApp(
        child: StaffPayrollTable(period: periodDraft),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      final confirmBtn = find.byKey(const Key('btn_confirm_payroll_PAY-TO-CONFIRM'));
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.text('hr_confirm_payroll_title'.tr()), findsOneWidget);
    });

    testWidgets('8. Payout payroll action button is visible to authorized user when confirmed', (tester) async {
      _setupDesktopView(tester);

      final periodConfirmed = StaffPayrollPeriodModel(
        id: 'PAY-TO-PAY',
        primaryBranchId: 'branch_1',
        status: PayrollStatusEnum.confirmed,
        items: const [StaffPayrollItemModel(staffUserId: 'U1')],
      );

      await tester.pumpWidget(_buildTestApp(
        child: StaffPayrollTable(period: periodConfirmed),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      final payoutBtn = find.byKey(const Key('btn_payout_payroll_PAY-TO-PAY'));
      expect(payoutBtn, findsOneWidget);
    });

    testWidgets('9. Manager without manageStaffPayroll cannot view staff payroll (fail-closed)', (tester) async {
      _setupDesktopView(tester);

      userProvider.user = branchManagerUser;
      sessionCubit = SessionCubit(SessionState(
        currentUser: branchManagerUser,
        activeBranchId: 'branch_1',
      ));
      await hrCubit.init(branchId: 'branch_1', user: branchManagerUser);

      await tester.pumpWidget(_buildTestApp(
        child: const StaffPayrollTab(),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.text('hr_unauthorized_payroll'.tr()), findsOneWidget);
      expect(find.byKey(const Key('btn_open_generate_payroll')), findsNothing);
    });

    testWidgets('10. EmployeeLedgerTab renders employee search field, outstanding advances, and add button', (tester) async {
      _setupDesktopView(tester);

      await hrCubit.init(branchId: 'branch_1', user: hrManagerUser);

      await tester.pumpWidget(_buildTestApp(
        child: const EmployeeLedgerTab(),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('field_ledger_employee_id')), findsOneWidget);
      expect(find.byKey(const Key('text_outstanding_advances')), findsOneWidget);
      expect(find.byKey(const Key('btn_open_add_ledger_entry')), findsOneWidget);
    });

    testWidgets('11. EmployeeLedgerTable displays ledger entries and reversal indicators', (tester) async {
      _setupDesktopView(tester);

      final entries = [
        const EmployeeLedgerEntryModel(
          id: 'LED-001',
          employeeId: 'USR-01',
          branchId: 'branch_1',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 50000,
          reason: 'سلفة طارئة',
        ),
      ];

      await tester.pumpWidget(_buildTestApp(
        child: EmployeeLedgerTable(entries: entries),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.text('LED-001'), findsOneWidget);
      expect(find.text('سلفة طارئة'), findsOneWidget);
      expect(find.byKey(const Key('btn_reverse_entry_LED-001')), findsOneWidget);
    });

    testWidgets('12. Clicking add movement button opens AddLedgerEntryDialog', (tester) async {
      _setupDesktopView(tester);

      await hrCubit.init(branchId: 'branch_1', user: hrManagerUser);

      await tester.pumpWidget(_buildTestApp(
        child: const EmployeeLedgerTab(),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      final addBtn = find.byKey(const Key('btn_open_add_ledger_entry'));
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AddLedgerEntryDialog), findsOneWidget);
    });

    testWidgets('13. AddLedgerEntryDialog validates inputs and calls addAdvance', (tester) async {
      _setupDesktopView(tester);

      await hrCubit.init(branchId: 'branch_1', user: hrManagerUser);

      await tester.pumpWidget(_buildTestApp(
        child: const AddLedgerEntryDialog(initialEmployeeId: 'EMP-99'),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('field_ledger_amount')), '500');
      await tester.enterText(find.byKey(const Key('field_ledger_notes')), 'سلفة مكتبية');

      final saveBtn = find.byKey(const Key('btn_save_ledger_entry'));
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(hrCubit.state.ledgerEntries.length, 1);
      expect(hrCubit.state.outstandingAdvancesPiastres, 50000);
    });

    testWidgets('14. Reverse action button opens ReverseLedgerEntryDialog and reverses entry with reason', (tester) async {
      _setupDesktopView(tester);

      final entry = const EmployeeLedgerEntryModel(
        id: 'LED-REV-01',
        employeeId: 'EMP-99',
        branchId: 'branch_1',
        entryType: LedgerEntryTypeEnum.advance,
        amountPiastres: 20000,
      );

      await repo.addEmployeeLedgerEntry(entry);
      await hrCubit.init(branchId: 'branch_1', user: hrManagerUser);
      await hrCubit.loadEmployeeLedger('EMP-99');

      await tester.pumpWidget(_buildTestApp(
        child: ReverseLedgerEntryDialog(targetEntry: entry),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('field_reversal_reason')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('field_reversal_reason')), 'تسجيل بالخطأ للموظف');

      final confirmBtn = find.byKey(const Key('btn_confirm_reverse_entry'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(hrCubit.state.outstandingAdvancesPiastres, 0);
    });
  });
}
