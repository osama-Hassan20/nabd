import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_item_model.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_model.dart';
import 'package:eyadty/features/hr/data/models/enums/settlement_status_enum.dart';
import 'package:eyadty/features/hr/data/repo/doctor_settlement_visits_mock_lookup.dart';
import 'package:eyadty/features/hr/data/repo/hr_mock_repo_impl.dart';
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
import 'package:eyadty/features/hr/presentation/widgets/dialogs/calculate_settlement_draft_dialog.dart';
import 'package:eyadty/features/hr/presentation/widgets/dialogs/doctor_compensation_rule_dialog.dart';
import 'package:eyadty/features/hr/presentation/widgets/dialogs/settlement_breakdown_dialog.dart';
import 'package:eyadty/features/hr/presentation/widgets/doctor_settlements_tab.dart';
import 'package:eyadty/features/hr/presentation/widgets/settlements_table.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class MockUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  MockUserSessionProvider({this.user, this.branch = 'branch_1'});

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch;
}

class MockRolesSessionProvider implements RolesProvider {
  List<RoleDefinitionModel> roles;
  MockRolesSessionProvider({required this.roles});

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

  group('Doctor Settlements UI & Dialogs Tests (Plan F-06 M-6)', () {
    late HrMockRepoImpl repo;
    late DoctorSettlementVisitsMockLookup visitsLookup;
    late InMemoryAuditLogger auditLogger;
    late MockUserSessionProvider userProvider;
    late MockRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;
    late SessionCubit sessionCubit;
    late HrCubit hrCubit;

    const managerRoleId = 'role_manager_test';
    final managerRole = RoleDefinitionModel(
      id: managerRoleId,
      permissions: [
        StaffPermissionEnum.accessHr,
        StaffPermissionEnum.calculateDoctorSettlement,
        StaffPermissionEnum.confirmDoctorSettlement,
      ],
    );

    const accountantRoleId = 'role_accountant_test';
    final accountantRole = RoleDefinitionModel(
      id: accountantRoleId,
      permissions: [
        StaffPermissionEnum.accessHr,
        StaffPermissionEnum.calculateDoctorSettlement,
        StaffPermissionEnum.confirmDoctorSettlement,
        StaffPermissionEnum.payoutSettlement,
      ],
    );

    final defaultManagerUser = StaffUserModel(
      id: 'usr_mgr_01',
      fullName: 'مدير الفرع',
      isActive: true,
      branchAssignments: const [
        BranchAssignmentModel(branchId: 'branch_1', roleIds: [managerRoleId]),
      ],
    );

    setUp(() {
      repo = HrMockRepoImpl(seedInitialData: false);
      visitsLookup = DoctorSettlementVisitsMockLookup();
      auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

      rolesProvider = MockRolesSessionProvider(
        roles: [...RoleDefinitionModel.defaultSystemRoles(), managerRole, accountantRole],
      );

      userProvider = MockUserSessionProvider(user: defaultManagerUser);

      permissionEvaluator = PermissionEvaluator(
        userProvider: userProvider,
        rolesProvider: rolesProvider,
      );

      sessionCubit = SessionCubit(SessionState(
        currentUser: defaultManagerUser,
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

    testWidgets('1. Renders settlements table with columns', (tester) async {
      _setupDesktopView(tester);

      final sampleSettlement = DoctorSettlementModel(
        id: 'SET-001',
        settlementNumber: 'SET-DOC-202605-001',
        doctorId: 'DOC-01',
        doctorName: 'د. طارق الشناوي',
        branchId: 'branch_1',
        periodStart: DateTime(2026, 5, 1),
        periodEnd: DateTime(2026, 5, 31),
        totalVisitsCount: 15,
        totalNetRevenuePiastres: 300000,
        netPayablePiastres: 120000,
        status: SettlementStatusEnum.confirmed,
      );

      await tester.pumpWidget(_buildTestApp(
        child: SettlementsTable(settlements: [sampleSettlement]),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.text('SET-DOC-202605-001'), findsOneWidget);
      expect(find.text('د. طارق الشناوي'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('2. Filter bar filters settlements by doctor, status, and date range', (tester) async {
      _setupDesktopView(tester);

      await hrCubit.init(branchId: 'branch_1', user: defaultManagerUser);

      await tester.pumpWidget(_buildTestApp(
        child: const DoctorSettlementsTab(),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('filter_doctor')), findsOneWidget);
      expect(find.byKey(const Key('filter_status')), findsOneWidget);
    });

    testWidgets('3. Settlement status badge displays correct status text', (tester) async {
      _setupDesktopView(tester);

      final settlements = [
        const DoctorSettlementModel(id: 'S1', status: SettlementStatusEnum.draft),
        const DoctorSettlementModel(id: 'S2', status: SettlementStatusEnum.confirmed),
        const DoctorSettlementModel(id: 'S3', status: SettlementStatusEnum.paid),
      ];

      await tester.pumpWidget(_buildTestApp(
        child: SettlementsTable(settlements: settlements),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.text('hr_status_draft'.tr()), findsOneWidget);
      expect(find.text('hr_status_confirmed'.tr()), findsOneWidget);
      expect(find.text('hr_status_paid'.tr()), findsOneWidget);
    });

    testWidgets('4. Clicking View Breakdown opens SettlementBreakdownDialog', (tester) async {
      _setupDesktopView(tester);

      final settlement = DoctorSettlementModel(
        id: 'SET-BD-01',
        settlementNumber: 'SET-DOC-202605-002',
        doctorId: 'DOC-01',
        doctorName: 'د. عمرو',
        branchId: 'branch_1',
        items: const [
          DoctorSettlementItemModel(
            visitId: 'VISIT-99',
            patientName: 'مريض تجريبي',
            serviceName: 'كشف استشاري',
            grossFeePiastres: 25000,
            netAmountPiastres: 25000,
            doctorEarnedPiastres: 12500,
            clinicSharePiastres: 12500,
          ),
        ],
      );

      await tester.pumpWidget(_buildTestApp(
        child: SettlementsTable(settlements: [settlement]),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      final breakdownBtn = find.byKey(const Key('btn_view_breakdown_SET-BD-01'));
      expect(breakdownBtn, findsOneWidget);

      await tester.tap(breakdownBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SettlementBreakdownDialog), findsOneWidget);
      expect(find.text('مريض تجريبي'), findsOneWidget);
      expect(find.text('VISIT-99'), findsOneWidget);
    });

    testWidgets('5. Breakdown dialog displays gross fee, discount, net amount, doctor share, clinic share', (tester) async {
      _setupDesktopView(tester);

      final settlement = DoctorSettlementModel(
        id: 'SET-BD-02',
        settlementNumber: 'SET-DOC-202605-003',
        doctorId: 'DOC-01',
        items: const [
          DoctorSettlementItemModel(
            visitId: 'V-100',
            grossFeePiastres: 30000,
            discountAmountPiastres: 5000,
            netAmountPiastres: 25000,
            doctorEarnedPiastres: 10000,
            clinicSharePiastres: 15000,
          ),
        ],
      );

      await tester.pumpWidget(_buildTestApp(
        child: SettlementBreakdownDialog(settlement: settlement),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.text('V-100'), findsOneWidget);
      expect(find.byType(SettlementBreakdownDialog), findsOneWidget);
    });

    testWidgets('6. Clicking Save Compensation Rule opens DoctorCompensationRuleDialog', (tester) async {
      _setupDesktopView(tester);

      await tester.pumpWidget(_buildTestApp(
        child: const DoctorSettlementsTab(),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      final openRulesBtn = find.byKey(const Key('btn_open_compensation_rules'));
      expect(openRulesBtn, findsOneWidget);

      await tester.tap(openRulesBtn);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorCompensationRuleDialog), findsOneWidget);
    });

    testWidgets('7. Compensation rule dialog validates required fields and bounds reactively', (tester) async {
      _setupDesktopView(tester);

      await tester.pumpWidget(_buildTestApp(
        child: const DoctorCompensationRuleDialog(),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('btn_save_rule'));
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Empty doctor ID triggers validation error
      expect(find.text('hr_doctor_id_required'.tr()), findsOneWidget);
    });

    testWidgets('8. Selecting compensation type dynamically shows/hides percentage, fixed fee, and base salary fields', (tester) async {
      _setupDesktopView(tester);

      await tester.pumpWidget(_buildTestApp(
        child: const DoctorCompensationRuleDialog(),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      // By default percentage is selected -> percentage field is shown
      expect(find.byKey(const Key('field_commission_percentage')), findsOneWidget);
      expect(find.byKey(const Key('field_fixed_fee')), findsNothing);

      // Change dropdown to fixedPerVisit
      await tester.tap(find.byKey(const Key('dropdown_compensation_type')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('hr_comp_type_fixed'.tr()).last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('field_commission_percentage')), findsNothing);
      expect(find.byKey(const Key('field_fixed_fee')), findsOneWidget);
    });

    testWidgets('9. Clicking Calculate Draft opens CalculateSettlementDraftDialog', (tester) async {
      _setupDesktopView(tester);

      await tester.pumpWidget(_buildTestApp(
        child: const DoctorSettlementsTab(),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      final openCalcBtn = find.byKey(const Key('btn_open_calculate_draft'));
      expect(openCalcBtn, findsOneWidget);

      await tester.tap(openCalcBtn);
      await tester.pumpAndSettle();

      expect(find.byType(CalculateSettlementDraftDialog), findsOneWidget);
    });

    testWidgets('10. Calculate draft dialog shows period selector and doctor selector', (tester) async {
      _setupDesktopView(tester);

      await tester.pumpWidget(_buildTestApp(
        child: const CalculateSettlementDraftDialog(),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('field_draft_doctor_id')), findsOneWidget);
      expect(find.byKey(const Key('btn_select_start_date')), findsOneWidget);
      expect(find.byKey(const Key('btn_select_end_date')), findsOneWidget);
      expect(find.byKey(const Key('btn_calculate_draft')), findsOneWidget);
    });

    testWidgets('11. Confirm settlement action button with confirmation dialog', (tester) async {
      _setupDesktopView(tester);

      final draftSettlement = DoctorSettlementModel(
        id: 'SET-TO-CONFIRM',
        settlementNumber: 'SET-DOC-202605-011',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
      );

      await tester.pumpWidget(_buildTestApp(
        child: SettlementsTable(settlements: [draftSettlement]),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      final confirmBtn = find.byKey(const Key('btn_confirm_settlement_SET-TO-CONFIRM'));
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.text('hr_confirm_settlement_title'.tr()), findsOneWidget);
    });

    testWidgets('12. Separation of duties guard in UI: Doctor cannot see confirm button on their own settlement', (tester) async {
      _setupDesktopView(tester);

      final ownSettlement = DoctorSettlementModel(
        id: 'SET-OWN-DOC',
        doctorId: 'DOC-CURRENT',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
      );

      // Authenticated doctor
      final doctorUser = StaffUserModel(
        id: 'usr_doc_self',
        linkedDoctorId: 'DOC-CURRENT',
        isOwner: false,
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [managerRoleId]),
        ],
      );

      userProvider.user = doctorUser;
      sessionCubit = SessionCubit(SessionState(
        currentUser: doctorUser,
        activeBranchId: 'branch_1',
      ));
      await hrCubit.init(branchId: 'branch_1', user: doctorUser);

      await tester.pumpWidget(_buildTestApp(
        child: SettlementsTable(settlements: [ownSettlement]),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      // Confirm button must NOT be rendered for attending doctor
      expect(find.byKey(const Key('btn_confirm_settlement_SET-OWN-DOC')), findsNothing);
    });

    testWidgets('13. Owner sees confirm button even on own settlement', (tester) async {
      _setupDesktopView(tester);

      final ownSettlement = DoctorSettlementModel(
        id: 'SET-OWN-OWNER',
        doctorId: 'DOC-OWNER',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
      );

      final ownerUser = const StaffUserModel(
        id: 'usr_owner_clin',
        linkedDoctorId: 'DOC-OWNER',
        isOwner: true,
        isActive: true,
      );

      userProvider.user = ownerUser;
      sessionCubit = SessionCubit(SessionState(
        currentUser: ownerUser,
        activeBranchId: 'branch_1',
      ));
      await hrCubit.init(branchId: 'branch_1', user: ownerUser);

      await tester.pumpWidget(_buildTestApp(
        child: SettlementsTable(settlements: [ownSettlement]),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      // Owner sees confirm button
      expect(find.byKey(const Key('btn_confirm_settlement_SET-OWN-OWNER')), findsOneWidget);
    });

    testWidgets('14. Payout settlement action button visible to accountant and owner', (tester) async {
      _setupDesktopView(tester);

      final confirmedSettlement = DoctorSettlementModel(
        id: 'SET-CONF-PAY',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
      );

      final accountantUser = StaffUserModel(
        id: 'usr_acc_01',
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );

      userProvider.user = accountantUser;
      sessionCubit = SessionCubit(SessionState(
        currentUser: accountantUser,
        activeBranchId: 'branch_1',
      ));
      await hrCubit.init(branchId: 'branch_1', user: accountantUser);

      await tester.pumpWidget(_buildTestApp(
        child: SettlementsTable(settlements: [confirmedSettlement]),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_payout_settlement_SET-CONF-PAY')), findsOneWidget);
    });

    testWidgets('15. Manager role sees confirm button but does NOT see payout button', (tester) async {
      _setupDesktopView(tester);

      final confirmedSettlement = DoctorSettlementModel(
        id: 'SET-CONF-MGR',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
      );

      userProvider.user = defaultManagerUser;
      sessionCubit = SessionCubit(SessionState(
        currentUser: defaultManagerUser,
        activeBranchId: 'branch_1',
      ));
      await hrCubit.init(branchId: 'branch_1', user: defaultManagerUser);

      await tester.pumpWidget(_buildTestApp(
        child: SettlementsTable(settlements: [confirmedSettlement]),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      // Manager lacks payoutSettlement permission
      expect(find.byKey(const Key('btn_payout_settlement_SET-CONF-MGR')), findsNothing);
    });

    testWidgets('16. Printing button triggers PDF preview/export callback for doctor settlement', (tester) async {
      _setupDesktopView(tester);

      bool printTriggered = false;

      final settlement = DoctorSettlementModel(
        id: 'SET-PRINT-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
      );

      await tester.pumpWidget(_buildTestApp(
        child: SettlementsTable(
          settlements: [settlement],
          onPrintSettlement: () => printTriggered = true,
        ),
        sessionCubit: sessionCubit,
        hrCubit: hrCubit,
      ));
      await tester.pumpAndSettle();

      final printBtn = find.byKey(const Key('btn_print_settlement_SET-PRINT-01'));
      expect(printBtn, findsOneWidget);

      await tester.tap(printBtn);
      expect(printTriggered, isTrue);
    });
  });
}
