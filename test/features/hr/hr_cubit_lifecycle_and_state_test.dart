import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/hr/data/models/doctor_compensation_rule_model.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_model.dart';
import 'package:eyadty/features/hr/data/models/employee_ledger_entry_model.dart';
import 'package:eyadty/features/hr/data/models/enums/compensation_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/employee_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/ledger_entry_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/settlement_status_enum.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_profile_model.dart';
import 'package:eyadty/features/hr/data/repo/doctor_settlement_visits_mock_lookup.dart';
import 'package:eyadty/features/hr/data/repo/hr_mock_repo_impl.dart';
import 'package:eyadty/features/hr/domain/contracts/doctor_settlement_visits_lookup.dart';
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
import 'package:eyadty/features/hr/presentation/manager/hr_tab_enum.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class CubitTestUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  CubitTestUserSessionProvider({this.user, this.branch = 'branch_1'});

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch;
}

class CubitTestRolesSessionProvider implements RolesProvider {
  List<RoleDefinitionModel> roles;
  CubitTestRolesSessionProvider({required this.roles});

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

void main() {
  group('HrCubit Lifecycle and State Management Tests (Plan F-06 M-5)', () {
    late HrMockRepoImpl repo;
    late DoctorSettlementVisitsMockLookup visitsLookup;
    late InMemoryAuditLogger auditLogger;
    late CubitTestUserSessionProvider userProvider;
    late CubitTestRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;
    late HrCubit hrCubit;

    const hrRoleId = 'role_hr_full';
    final hrRole = RoleDefinitionModel(
      id: hrRoleId,
      nameAr: 'مسؤول HR ومستحقات',
      nameEn: 'HR & Payroll Admin',
      permissions: [
        StaffPermissionEnum.accessHr,
        StaffPermissionEnum.calculateDoctorSettlement,
        StaffPermissionEnum.confirmDoctorSettlement,
        StaffPermissionEnum.payoutSettlement,
        StaffPermissionEnum.manageCompensationRules,
        StaffPermissionEnum.manageEmployeeLedger,
        StaffPermissionEnum.manageStaffPayroll,
      ],
    );

    final defaultAdminUser = StaffUserModel(
      id: 'usr_admin',
      fullName: 'مدير الموارد',
      isActive: true,
      branchAssignments: const [
        BranchAssignmentModel(branchId: 'branch_1', roleIds: [hrRoleId]),
        BranchAssignmentModel(branchId: 'branch_2', roleIds: [hrRoleId]),
      ],
    );

    setUp(() {
      repo = HrMockRepoImpl(seedInitialData: false);
      visitsLookup = DoctorSettlementVisitsMockLookup();
      auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

      rolesProvider = CubitTestRolesSessionProvider(
        roles: [...RoleDefinitionModel.defaultSystemRoles(), hrRole],
      );

      userProvider = CubitTestUserSessionProvider(user: defaultAdminUser);

      permissionEvaluator = PermissionEvaluator(
        userProvider: userProvider,
        rolesProvider: rolesProvider,
      );

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
    });

    test('1. Initial state loads settlements and active branch rules', () async {
      // Seed a rule and settlement for branch_1
      await repo.saveCompensationRule(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: DateTime(2026, 1, 1),
      ));

      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
        netPayablePiastres: 50000,
      ));

      await hrCubit.init(branchId: 'branch_1', user: defaultAdminUser);

      expect(hrCubit.state.status, RequestStatusEnum.success);
      expect(hrCubit.state.currentBranchId, 'branch_1');
      expect(hrCubit.state.settlements.length, 1);
      expect(hrCubit.state.compensationRules.length, 1);
    });

    test('2. Auto-reset clears state when active branch changes', () async {
      await hrCubit.init(branchId: 'branch_1', user: defaultAdminUser);
      expect(hrCubit.state.currentBranchId, 'branch_1');

      // Change branch to branch_2
      await hrCubit.onBranchOrUserChanged(
        newBranchId: 'branch_2',
        newUser: defaultAdminUser,
      );

      expect(hrCubit.state.currentBranchId, 'branch_2');
      // branch_2 has no settlements seeded
      expect(hrCubit.state.settlements, isEmpty);
    });

    test('3. Auto-reset clears state when user changes', () async {
      await hrCubit.init(branchId: 'branch_1', user: defaultAdminUser);

      final anotherUser = StaffUserModel(
        id: 'usr_new_02',
        fullName: 'مستخدم آخر',
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.doctor]),
        ],
      );

      await hrCubit.onBranchOrUserChanged(
        newBranchId: 'branch_1',
        newUser: anotherUser,
      );

      expect(hrCubit.state.currentUserId, 'usr_new_02');
      expect(hrCubit.state.currentUser?.id, 'usr_new_02');
    });

    test('4. Tab switching updates selected tab in state', () {
      expect(hrCubit.state.selectedTab, HrTabEnum.settlements);

      hrCubit.switchTab(HrTabEnum.staffPayroll);
      expect(hrCubit.state.selectedTab, HrTabEnum.staffPayroll);

      hrCubit.switchTab(HrTabEnum.employeeLedger);
      expect(hrCubit.state.selectedTab, HrTabEnum.employeeLedger);

      hrCubit.switchTab(HrTabEnum.compensationRules);
      expect(hrCubit.state.selectedTab, HrTabEnum.compensationRules);
    });

    test('5. Filter by doctor updates filtered settlements list', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-DOC-1',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
      ));
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-DOC-2',
        doctorId: 'DOC-02',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
      ));

      await hrCubit.init(branchId: 'branch_1', user: defaultAdminUser);
      expect(hrCubit.state.settlements.length, 2);

      hrCubit.setDoctorFilter('DOC-01');
      await pumpEventQueue();

      expect(hrCubit.state.filterDoctorId, 'DOC-01');
      expect(hrCubit.state.settlements.length, 1);
      expect(hrCubit.state.settlements.first.doctorId, 'DOC-01');
    });

    test('6. Filter by date/month updates state', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-MAY',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: DateTime(2026, 5, 1),
        periodEnd: DateTime(2026, 5, 31, 23, 59, 59),
        status: SettlementStatusEnum.confirmed,
      ));
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-JUNE',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: DateTime(2026, 6, 1),
        periodEnd: DateTime(2026, 6, 30, 23, 59, 59),
        status: SettlementStatusEnum.confirmed,
      ));

      await hrCubit.init(branchId: 'branch_1', user: defaultAdminUser);
      expect(hrCubit.state.settlements.length, 2);

      hrCubit.setDateRangeFilter(DateTime(2026, 5, 1), DateTime(2026, 5, 31, 23, 59, 59));
      await pumpEventQueue();

      expect(hrCubit.state.settlements.length, 1);
      expect(hrCubit.state.settlements.first.id, 'SET-MAY');
    });

    test('7. Doctor user can only see their own settlements in state (isolated via linkedDoctorId)', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-D1',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
      ));
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-D2',
        doctorId: 'DOC-02',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
      ));

      // Doctor DOC-01 user
      final doctorUser = StaffUserModel(
        id: 'usr_doc_01',
        fullName: 'د. طارق',
        linkedDoctorId: 'DOC-01',
        isOwner: false,
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.doctor]),
        ],
      );

      await hrCubit.init(branchId: 'branch_1', user: doctorUser);

      // Only DOC-01 settlements are visible
      expect(hrCubit.state.settlements.length, 1);
      expect(hrCubit.state.settlements.first.doctorId, 'DOC-01');
    });

    test('8. Non-HR staff user cannot access staff payroll tab data (fail-closed isolation)', () async {
      await repo.saveStaffPayrollProfile(const StaffPayrollProfileModel(
        staffUserId: 'usr_rec',
        fullName: 'استقبال',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 500000,
        isActive: true,
      ));

      // User with receptionist role (no manageStaffPayroll permission)
      final receptionUser = StaffUserModel(
        id: 'usr_reception_test',
        fullName: 'سارة استقبال',
        isOwner: false,
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.reception]),
        ],
      );

      userProvider.user = receptionUser;

      await hrCubit.init(branchId: 'branch_1', user: receptionUser);

      // Staff payroll data must be strictly empty (fail-closed)
      expect(hrCubit.state.payrollPeriods, isEmpty);
      expect(hrCubit.state.staffProfiles, isEmpty);
    });

    test('9. Load employee ledger entries for selected employee', () async {
      await repo.addEmployeeLedgerEntry(EmployeeLedgerEntryModel(
        id: 'LED-001',
        employeeId: 'DOC-01',
        employeeType: EmployeeTypeEnum.doctor,
        entryType: LedgerEntryTypeEnum.advance,
        amountPiastres: 50000,
        branchId: 'branch_1',
      ));

      await hrCubit.init(branchId: 'branch_1', user: defaultAdminUser);
      await hrCubit.loadEmployeeLedger('DOC-01');

      expect(hrCubit.state.selectedEmployeeId, 'DOC-01');
      expect(hrCubit.state.ledgerEntries.length, 1);
      expect(hrCubit.state.outstandingAdvancesPiastres, 50000);
    });

    test('10. Reverse ledger entry updates ledger list reactively', () async {
      final entryRes = await repo.addEmployeeLedgerEntry(EmployeeLedgerEntryModel(
        id: 'LED-REV-01',
        employeeId: 'DOC-01',
        employeeType: EmployeeTypeEnum.doctor,
        entryType: LedgerEntryTypeEnum.advance,
        amountPiastres: 30000,
        branchId: 'branch_1',
      ));
      expect(entryRes.isRight(), isTrue);

      await hrCubit.init(branchId: 'branch_1', user: defaultAdminUser);
      await hrCubit.loadEmployeeLedger('DOC-01');
      expect(hrCubit.state.outstandingAdvancesPiastres, 30000);

      final success = await hrCubit.reverseLedgerEntry(
        entryId: 'LED-REV-01',
        reason: 'خطأ محاسبي مسجل بمستند رقم 44',
        employeeId: 'DOC-01',
      );

      expect(success, isTrue);
      // Reversal creates a reversal entry and drops active advances to 0
      expect(hrCubit.state.outstandingAdvancesPiastres, 0);
      expect(hrCubit.state.ledgerEntries.length, 2);
    });

    test('11. Add advance updates ledger entries and recalculates active balance', () async {
      await hrCubit.init(branchId: 'branch_1', user: defaultAdminUser);

      final success = await hrCubit.addAdvance(
        employeeId: 'DOC-05',
        employeeType: EmployeeTypeEnum.doctor,
        amountPiastres: 80000,
        reason: 'سلفة سفر',
      );

      expect(success, isTrue);
      expect(hrCubit.state.selectedEmployeeId, 'DOC-05');
      expect(hrCubit.state.outstandingAdvancesPiastres, 80000);
      expect(hrCubit.state.ledgerEntries.length, 1);
    });

    test('12. Calculate draft settlement updates draft in state', () async {
      await repo.saveCompensationRule(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 50,
        effectiveFrom: DateTime(2026, 1, 1),
      ));

      visitsLookup.addCandidate(SettlementVisitCandidate(
        visitId: 'VISIT-CUBIT-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        finalizedAt: DateTime(2026, 5, 10),
        netAmountPiastres: 40000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-CUBIT-01',
            type: 'payment',
            amountPiastres: 40000,
            date: DateTime(2026, 5, 10),
          ),
        ],
      ));

      await hrCubit.init(branchId: 'branch_1', user: defaultAdminUser);

      final success = await hrCubit.calculateDraftSettlement(
        doctorId: 'DOC-01',
        periodStart: DateTime(2026, 5, 1),
        periodEnd: DateTime(2026, 5, 31, 23, 59, 59),
      );

      expect(success, isTrue);
      expect(hrCubit.state.draftSettlement, isNotNull);
      expect(hrCubit.state.draftSettlement?.netPayablePiastres, 20000); // 50% of 40000
    });

    test('13. Confirm settlement updates settlement status reactively', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-CONF-STATE',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
        netPayablePiastres: 25000,
      ));

      await hrCubit.init(branchId: 'branch_1', user: defaultAdminUser);

      final success = await hrCubit.confirmSettlement('SET-CONF-STATE');
      expect(success, isTrue);
      expect(hrCubit.state.selectedSettlement?.status, SettlementStatusEnum.confirmed);
      expect(
        hrCubit.state.settlements.firstWhere((s) => s.id == 'SET-CONF-STATE').status,
        SettlementStatusEnum.confirmed,
      );
    });

    test('14. Payout settlement updates status to paid and updates ledger', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-PAY-STATE',
        settlementNumber: 'SET-DOC-202605-009',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
        netPayablePiastres: 35000,
      ));

      await hrCubit.init(branchId: 'branch_1', user: defaultAdminUser);

      final success = await hrCubit.payoutSettlement(
        settlementId: 'SET-PAY-STATE',
        method: PaymentMethod.cash,
      );

      expect(success, isTrue);
      expect(hrCubit.state.selectedSettlement?.status, SettlementStatusEnum.paid);
      expect(
        hrCubit.state.settlements.firstWhere((s) => s.id == 'SET-PAY-STATE').status,
        SettlementStatusEnum.paid,
      );
    });
  });
}
