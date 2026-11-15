import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/hr/data/models/doctor_compensation_rule_model.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_model.dart';
import 'package:eyadty/features/hr/data/models/enums/compensation_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/payroll_status_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/settlement_status_enum.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_period_model.dart';
import 'package:eyadty/features/hr/data/repo/doctor_settlement_visits_mock_lookup.dart';
import 'package:eyadty/features/hr/data/repo/hr_mock_repo_impl.dart';
import 'package:eyadty/features/hr/domain/use_cases/calculate_doctor_settlement_draft_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/confirm_doctor_settlement_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/confirm_staff_payroll_period_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/generate_staff_payroll_period_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/get_active_rule_for_doctor_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/payout_doctor_settlement_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/payout_staff_payroll_period_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/save_doctor_compensation_rule_use_case.dart';
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

void main() {
  group('HR RBAC & Branch Isolation Tests (Plan F-06 M-9)', () {
    late HrMockRepoImpl repo;
    late DoctorSettlementVisitsMockLookup visitsLookup;
    late InMemoryAuditLogger auditLogger;
    late MockUserSessionProvider userProvider;
    late MockRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;

    late SaveDoctorCompensationRuleUseCase saveRuleUseCase;
    late GetActiveRuleForDoctorUseCase getActiveRuleUseCase;
    late CalculateDoctorSettlementDraftUseCase calculateDraftUseCase;
    late ConfirmDoctorSettlementUseCase confirmSettlementUseCase;
    late PayoutDoctorSettlementUseCase payoutSettlementUseCase;
    late GenerateStaffPayrollPeriodUseCase generatePayrollUseCase;
    late ConfirmStaffPayrollPeriodUseCase confirmPayrollUseCase;
    late PayoutStaffPayrollPeriodUseCase payoutPayrollUseCase;

    const managerRoleId = 'role_manager';
    const doctorRoleId = 'role_doctor';
    const accountantRoleId = 'role_accountant';

    final managerRole = RoleDefinitionModel(
      id: managerRoleId,
      permissions: [
        StaffPermissionEnum.accessHr,
        StaffPermissionEnum.calculateDoctorSettlement,
        StaffPermissionEnum.confirmDoctorSettlement,
        StaffPermissionEnum.manageEmployeeLedger,
      ],
    );

    final doctorRole = RoleDefinitionModel(
      id: doctorRoleId,
      permissions: [
        StaffPermissionEnum.accessHr,
        StaffPermissionEnum.viewOwnDoctorSettlement,
      ],
    );

    final accountantRole = RoleDefinitionModel(
      id: accountantRoleId,
      permissions: [
        StaffPermissionEnum.accessHr,
        StaffPermissionEnum.manageStaffPayroll,
        StaffPermissionEnum.payoutSettlement,
        StaffPermissionEnum.manageEmployeeLedger,
      ],
    );

    setUp(() {
      repo = HrMockRepoImpl(seedInitialData: false);
      visitsLookup = DoctorSettlementVisitsMockLookup();
      auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

      rolesProvider = MockRolesSessionProvider(
        roles: [managerRole, doctorRole, accountantRole, ...RoleDefinitionModel.defaultSystemRoles()],
      );
      userProvider = MockUserSessionProvider();

      permissionEvaluator = PermissionEvaluator(
        userProvider: userProvider,
        rolesProvider: rolesProvider,
      );

      saveRuleUseCase = SaveDoctorCompensationRuleUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      getActiveRuleUseCase = GetActiveRuleForDoctorUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
      );

      calculateDraftUseCase = CalculateDoctorSettlementDraftUseCase(
        hrRepo: repo,
        visitsLookup: visitsLookup,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      confirmSettlementUseCase = ConfirmDoctorSettlementUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      payoutSettlementUseCase = PayoutDoctorSettlementUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      generatePayrollUseCase = GenerateStaffPayrollPeriodUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
      );

      confirmPayrollUseCase = ConfirmStaffPayrollPeriodUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      payoutPayrollUseCase = PayoutStaffPayrollPeriodUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );
    });

    test('1. Branch Manager of Branch A cannot access or calculate settlements for Branch B', () async {
      final managerBranchA = StaffUserModel(
        id: 'usr_mgr_a',
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_a', roleIds: [managerRoleId]),
        ],
      );
      userProvider.user = managerBranchA;
      userProvider.branch = 'branch_a';

      final result = await calculateDraftUseCase(
        doctorId: 'DOC-01',
        branchId: 'branch_b',
        periodStart: DateTime(2026, 5, 1),
        periodEnd: DateTime(2026, 5, 31),
      );

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f.errMessage, (r) => null), 'permission_denied');
    });

    test('2. Separation of duties: Doctor cannot confirm their own settlement', () async {
      final attendingDoctor = StaffUserModel(
        id: 'usr_doc_01',
        linkedDoctorId: 'DOC-01',
        isOwner: false,
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [managerRoleId]),
        ],
      );
      userProvider.user = attendingDoctor;
      userProvider.branch = 'branch_1';

      final settlement = DoctorSettlementModel(
        id: 'SET-OWN-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
        netPayablePiastres: 50000,
      );
      await repo.saveDoctorSettlement(settlement);

      final result = await confirmSettlementUseCase(settlementId: 'SET-OWN-01');

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f.errMessage, (r) => null), 'hr_doctor_cannot_confirm_own_settlement');
    });

    test('3. Single operator exception: Clinic Owner can self-confirm their own settlement', () async {
      final ownerDoctor = const StaffUserModel(
        id: 'usr_owner_01',
        linkedDoctorId: 'DOC-OWNER',
        isOwner: true,
        isActive: true,
      );
      userProvider.user = ownerDoctor;
      userProvider.branch = 'branch_1';

      final settlement = DoctorSettlementModel(
        id: 'SET-OWNER-01',
        doctorId: 'DOC-OWNER',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
        netPayablePiastres: 75000,
      );
      await repo.saveDoctorSettlement(settlement);

      final result = await confirmSettlementUseCase(settlementId: 'SET-OWNER-01');

      expect(result.isRight(), isTrue);
      final logs = auditLogger.getLogs(eventType: 'owner_self_confirmed');
      expect(logs.any((l) => l.eventType == 'owner_self_confirmed'), isTrue);
    });

    test('4. Doctor with viewOwnDoctorSettlement can view only their own active/confirmed settlement', () async {
      await repo.saveCompensationRule(
        DoctorCompensationRuleModel(
          id: 'RULE-MYSELF',
          doctorId: 'DOC-MYSELF',
          branchId: 'branch_1',
          isActive: true,
          compensationType: CompensationTypeEnum.percentage,
          commissionPercentage: 50,
          effectiveFrom: DateTime(2026, 1, 1),
        ),
      );

      final doctorUser = StaffUserModel(
        id: 'usr_doc_view',
        linkedDoctorId: 'DOC-MYSELF',
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [doctorRoleId]),
        ],
      );
      userProvider.user = doctorUser;
      userProvider.branch = 'branch_1';

      // Can view own rule
      final ownRule = await getActiveRuleUseCase(doctorId: 'DOC-MYSELF', branchId: 'branch_1');
      expect(ownRule.isRight(), isTrue);

      // Cannot view another doctor's rule
      final otherRule = await getActiveRuleUseCase(doctorId: 'DOC-OTHER', branchId: 'branch_1');
      expect(otherRule.isLeft(), isTrue);
      expect(otherRule.fold((f) => f.errMessage, (r) => null), 'permission_denied');
    });

    test('5. Manager role cannot payout settlements without payoutSettlement permission', () async {
      final managerUser = StaffUserModel(
        id: 'usr_mgr_nopay',
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [managerRoleId]),
        ],
      );
      userProvider.user = managerUser;
      userProvider.branch = 'branch_1';

      final settlement = DoctorSettlementModel(
        id: 'SET-CONFIRMED-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
        netPayablePiastres: 30000,
      );
      await repo.saveDoctorSettlement(settlement);

      final result = await payoutSettlementUseCase(
        settlementId: 'SET-CONFIRMED-01',
        paymentMethod: PaymentMethod.cash,
      );

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f.errMessage, (r) => null), 'permission_denied');
    });

    test('6. Accountant role with payoutSettlement can payout confirmed settlement', () async {
      final accountantUser = StaffUserModel(
        id: 'usr_acc_pay',
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );
      userProvider.user = accountantUser;
      userProvider.branch = 'branch_1';

      final settlement = DoctorSettlementModel(
        id: 'SET-CONFIRMED-02',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
        netPayablePiastres: 40000,
      );
      await repo.saveDoctorSettlement(settlement);

      final result = await payoutSettlementUseCase(
        settlementId: 'SET-CONFIRMED-02',
        paymentMethod: PaymentMethod.cash,
      );

      expect(result.isRight(), isTrue);
    });

    test('7. Payout is rejected on draft settlement even if user is owner', () async {
      final ownerUser = const StaffUserModel(
        id: 'usr_owner_payout',
        isOwner: true,
        isActive: true,
      );
      userProvider.user = ownerUser;
      userProvider.branch = 'branch_1';

      final draftSettlement = DoctorSettlementModel(
        id: 'SET-DRAFT-FAIL',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
        netPayablePiastres: 20000,
      );
      await repo.saveDoctorSettlement(draftSettlement);

      final result = await payoutSettlementUseCase(
        settlementId: 'SET-DRAFT-FAIL',
        paymentMethod: PaymentMethod.cash,
      );

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f.errMessage, (r) => null), 'hr_settlement_not_confirmed_cannot_payout');
    });

    test('8. Saving compensation rule is rejected for branch manager without manageCompensationRules', () async {
      final managerUser = StaffUserModel(
        id: 'usr_mgr_norule',
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [managerRoleId]),
        ],
      );
      userProvider.user = managerUser;
      userProvider.branch = 'branch_1';

      final rule = DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 50,
        effectiveFrom: DateTime(2026, 6, 1),
      );

      final result = await saveRuleUseCase(rule);

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f.errMessage, (r) => null), 'permission_denied');
    });

    test('9. Clinic owner can save doctor compensation rule directly', () async {
      final ownerUser = const StaffUserModel(id: 'usr_owner_rules', isOwner: true, isActive: true);
      userProvider.user = ownerUser;
      userProvider.branch = 'branch_1';

      final rule = DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 45,
        effectiveFrom: DateTime(2026, 6, 1),
      );

      final result = await saveRuleUseCase(rule);

      expect(result.isRight(), isTrue);
    });

    test('10. Branch manager cannot generate staff payroll period without manageStaffPayroll', () async {
      final managerUser = StaffUserModel(
        id: 'usr_mgr_nopayroll',
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [managerRoleId]),
        ],
      );
      userProvider.user = managerUser;
      userProvider.branch = 'branch_1';

      final result = await generatePayrollUseCase(primaryBranchId: 'branch_1', month: 6, year: 2026);

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f.errMessage, (r) => null), 'permission_denied');
    });

    test('11. Accountant with manageStaffPayroll can generate staff payroll period', () async {
      final accountantUser = StaffUserModel(
        id: 'usr_acc_payroll',
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );
      userProvider.user = accountantUser;
      userProvider.branch = 'branch_1';

      final result = await generatePayrollUseCase(primaryBranchId: 'branch_1', month: 6, year: 2026);

      expect(result.isRight(), isTrue);
    });

    test('12. Confirm staff payroll is rejected for user without permission', () async {
      const draftPeriod = StaffPayrollPeriodModel(
        id: 'PAY-01',
        primaryBranchId: 'branch_1',
        status: PayrollStatusEnum.draft,
      );
      await repo.saveStaffPayrollPeriod(draftPeriod);

      final doctorUser = StaffUserModel(
        id: 'usr_doc_nopayroll',
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [doctorRoleId]),
        ],
      );
      userProvider.user = doctorUser;
      userProvider.branch = 'branch_1';

      final result = await confirmPayrollUseCase(periodId: 'PAY-01');

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f.errMessage, (r) => null), 'permission_denied');
    });

    test('13. Payout staff payroll is rejected if period is not yet confirmed', () async {
      final accountantUser = StaffUserModel(
        id: 'usr_acc_pay_draft',
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );
      userProvider.user = accountantUser;
      userProvider.branch = 'branch_1';

      const draftPeriod = StaffPayrollPeriodModel(
        id: 'PAY-DRAFT-01',
        primaryBranchId: 'branch_1',
        status: PayrollStatusEnum.draft,
      );
      await repo.saveStaffPayrollPeriod(draftPeriod);

      final result = await payoutPayrollUseCase(periodId: 'PAY-DRAFT-01');

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f.errMessage, (r) => null), 'hr_payroll_period_not_confirmed_cannot_payout');
    });

    test('14. Payout staff payroll succeeds for confirmed period by accountant', () async {
      final accountantUser = StaffUserModel(
        id: 'usr_acc_pay_conf',
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );
      userProvider.user = accountantUser;
      userProvider.branch = 'branch_1';

      const confPeriod = StaffPayrollPeriodModel(
        id: 'PAY-CONF-01',
        primaryBranchId: 'branch_1',
        status: PayrollStatusEnum.confirmed,
        totalNetPayablePiastres: 500000,
      );
      await repo.saveStaffPayrollPeriod(confPeriod);

      final result = await payoutPayrollUseCase(periodId: 'PAY-CONF-01');

      expect(result.isRight(), isTrue);
    });

    test('15. Employee ledger movements rejected if user lacks manageEmployeeLedger permission', () async {
      final doctorUser = StaffUserModel(
        id: 'usr_doc_noledger',
        isActive: true,
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [doctorRoleId]),
        ],
      );
      userProvider.user = doctorUser;
      userProvider.branch = 'branch_1';

      final canManage = permissionEvaluator.can(
        StaffPermissionEnum.manageEmployeeLedger,
        branchId: 'branch_1',
      );

      expect(canManage, isFalse);
    });

    test('16. Fail-closed: Null user or unassigned user is rejected across all HR operations', () async {
      userProvider.user = null;
      userProvider.branch = null;

      final calcRes = await calculateDraftUseCase(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: DateTime(2026, 5, 1),
        periodEnd: DateTime(2026, 5, 31),
      );
      expect(calcRes.isLeft(), isTrue);

      final confRes = await confirmSettlementUseCase(settlementId: 'SET-999');
      expect(confRes.isLeft(), isTrue);

      final payRes = await payoutSettlementUseCase(settlementId: 'SET-999', paymentMethod: PaymentMethod.cash);
      expect(payRes.isLeft(), isTrue);

      final genPayRes = await generatePayrollUseCase(primaryBranchId: 'branch_1', month: 5, year: 2026);
      expect(genPayRes.isLeft(), isTrue);
    });
  });
}
