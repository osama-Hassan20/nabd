import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/hr/data/models/doctor_compensation_rule_model.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_model.dart';
import 'package:eyadty/features/hr/data/models/enums/compensation_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/settlement_status_enum.dart';
import 'package:eyadty/features/hr/data/repo/hr_mock_repo_impl.dart';
import 'package:eyadty/features/hr/domain/use_cases/get_active_rule_for_doctor_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/get_doctor_compensation_rules_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/save_doctor_compensation_rule_use_case.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class TestUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  TestUserSessionProvider({this.user, this.branch = 'branch_1'});

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch;
}

class TestRolesSessionProvider implements RolesProvider {
  List<RoleDefinitionModel> roles;
  TestRolesSessionProvider({required this.roles});

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

void main() {
  group('Doctor Compensation Rules Tests (Plan F-06 M-2)', () {
    late HrMockRepoImpl repo;
    late InMemoryAuditLogger auditLogger;
    late TestUserSessionProvider userProvider;
    late TestRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;
    late SaveDoctorCompensationRuleUseCase saveRuleUseCase;
    late GetDoctorCompensationRulesUseCase getRulesUseCase;
    late GetActiveRuleForDoctorUseCase getActiveRuleUseCase;

    const hrRoleId = 'role_hr_manager';
    final hrRole = RoleDefinitionModel(
      id: hrRoleId,
      nameAr: 'مدير موارد بشرية',
      nameEn: 'HR Manager',
      permissions: [StaffPermissionEnum.manageCompensationRules, StaffPermissionEnum.accessHr],
    );

    setUp(() {
      repo = HrMockRepoImpl(seedInitialData: false);
      auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

      rolesProvider = TestRolesSessionProvider(
        roles: [...RoleDefinitionModel.defaultSystemRoles(), hrRole],
      );

      // Default authorized user: HR specialist with manageCompensationRules
      userProvider = TestUserSessionProvider(
        user: const StaffUserModel(
          id: 'usr_hr_specialist',
          fullName: 'عمرو إبراهيم',
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

      saveRuleUseCase = SaveDoctorCompensationRuleUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      getRulesUseCase = GetDoctorCompensationRulesUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
      );

      getActiveRuleUseCase = GetActiveRuleForDoctorUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
      );
    });

    test('1. Validates percentage bounds (0 <= % <= 100)', () async {
      final now = CairoTimeHelper.now();

      // Negative percentage rejected
      final negRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: -5,
        effectiveFrom: now,
      ));
      expect(negRes.isLeft(), isTrue);

      // Greater than 100 percentage rejected
      final overRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 105,
        effectiveFrom: now,
      ));
      expect(overRes.isLeft(), isTrue);

      // Valid bounds (e.g. 40%) accepted
      final validRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: now,
      ));
      expect(validRes.isRight(), isTrue);
    });

    test('2. Validates fixed amount >= 0', () async {
      final now = CairoTimeHelper.now();

      final negRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.fixedPerVisit,
        fixedAmountPerVisitPiastres: -1000,
        effectiveFrom: now,
      ));
      expect(negRes.isLeft(), isTrue);

      final validRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.fixedPerVisit,
        fixedAmountPerVisitPiastres: 10000, // 100 EGP
        effectiveFrom: now,
      ));
      expect(validRes.isRight(), isTrue);
    });

    test('3. Validates base salary >= 0', () async {
      final now = CairoTimeHelper.now();

      final negRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.salaryOnly,
        monthlyBaseSalaryPiastres: -50000,
        effectiveFrom: now,
      ));
      expect(negRes.isLeft(), isTrue);

      final validRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.salaryOnly,
        monthlyBaseSalaryPiastres: 1500000, // 15,000 EGP
        effectiveFrom: now,
      ));
      expect(validRes.isRight(), isTrue);
    });

    test('4. Rejects empty doctorId or branchId', () async {
      final now = CairoTimeHelper.now();

      final noDocRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: '   ',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: now,
      ));
      expect(noDocRes.isLeft(), isTrue);

      final noBranchRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: '',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: now,
      ));
      expect(noBranchRes.isLeft(), isTrue);
    });

    test('5. Rejects missing effectiveFrom', () async {
      final res = await saveRuleUseCase(const DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: null,
      ));
      expect(res.isLeft(), isTrue);
    });

    test('6. Prevents retroactive rule creation within confirmed settlement periods', () async {
      final periodStart = DateTime(2026, 5, 1);
      final periodEnd = DateTime(2026, 5, 31, 23, 59, 59);

      // Save a confirmed settlement for May 2026
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-CONFIRMED-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        status: SettlementStatusEnum.confirmed,
      ));

      // Attempting to define rule effective in the middle of May 2026 must be REJECTED
      final retroRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 50,
        effectiveFrom: DateTime(2026, 5, 15),
      ));
      expect(retroRes.isLeft(), isTrue);

      // Attempting effective date prior to periodEnd also rejected
      final priorRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 50,
        effectiveFrom: DateTime(2026, 4, 1),
      ));
      expect(priorRes.isLeft(), isTrue);
    });

    test('7. Prevents retroactive rule creation within paid settlement periods', () async {
      final periodStart = DateTime(2026, 5, 1);
      final periodEnd = DateTime(2026, 5, 31, 23, 59, 59);

      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-PAID-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        status: SettlementStatusEnum.paid,
      ));

      final retroRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 50,
        effectiveFrom: DateTime(2026, 5, 20),
      ));
      expect(retroRes.isLeft(), isTrue);
    });

    test('8. Allows future and active rule saving after confirmed periods', () async {
      final periodStart = DateTime(2026, 5, 1);
      final periodEnd = DateTime(2026, 5, 31, 23, 59, 59);

      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-PAID-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        status: SettlementStatusEnum.paid,
      ));

      // Effective on June 1st (after May periodEnd) is ALLOWED
      final futureRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 50,
        effectiveFrom: DateTime(2026, 6, 1),
      ));
      expect(futureRes.isRight(), isTrue);
    });

    test('9. Enforces manageCompensationRules permission check (fail-closed)', () async {
      final now = CairoTimeHelper.now();

      // Switch user to Receptionist (who has no manageCompensationRules permission)
      userProvider.user = const StaffUserModel(
        id: 'usr_reception_test',
        fullName: 'أحمد استقبال',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.reception]),
        ],
      );

      final res = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: now,
      ));
      expect(res.isLeft(), isTrue);
    });

    test('10. Owner bypasses permission check', () async {
      final now = CairoTimeHelper.now();

      userProvider.user = const StaffUserModel(
        id: 'usr_owner_clinic',
        fullName: 'المالك د. حسام',
        isOwner: true,
        isActive: true,
      );

      final res = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 45,
        effectiveFrom: now,
      ));
      expect(res.isRight(), isTrue);
    });

    test('11. Doctor can view their own compensation rule', () async {
      final now = CairoTimeHelper.now();

      // Seed rule for DOC-01
      await repo.saveCompensationRule(DoctorCompensationRuleModel(
        id: 'RULE-DOC-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: now.subtract(const Duration(days: 30)),
      ));

      // Authenticated doctor DOC-01
      userProvider.user = const StaffUserModel(
        id: 'usr_doc_01',
        fullName: 'د. طارق',
        linkedDoctorId: 'DOC-01',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.doctor]),
        ],
      );

      final res = await getRulesUseCase(doctorId: 'DOC-01', branchId: 'branch_1');
      expect(res.isRight(), isTrue);
      final rules = res.getOrElse(() => []);
      expect(rules.length, 1);
      expect(rules.first.doctorId, 'DOC-01');
    });

    test('12. Unauthorized staff cannot view other doctors rules', () async {
      final now = CairoTimeHelper.now();

      await repo.saveCompensationRule(DoctorCompensationRuleModel(
        id: 'RULE-DOC-02',
        doctorId: 'DOC-02',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: now.subtract(const Duration(days: 30)),
      ));

      // Doctor DOC-01 attempts to view DOC-02's rules
      userProvider.user = const StaffUserModel(
        id: 'usr_doc_01',
        fullName: 'د. طارق',
        linkedDoctorId: 'DOC-01',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.doctor]),
        ],
      );

      final res = await getRulesUseCase(doctorId: 'DOC-02', branchId: 'branch_1');
      expect(res.isLeft(), isTrue);
    });

    test('13. Emits compensation_rule_saved audit log on success with strict whitelist', () async {
      final now = CairoTimeHelper.now();

      userProvider.user = const StaffUserModel(
        id: 'usr_hr_01',
        fullName: 'نهى المحمدي',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [hrRoleId]),
        ],
      );

      final res = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-05',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 35,
        effectiveFrom: now,
      ));
      expect(res.isRight(), isTrue);

      final logs = auditLogger.getLogs(eventType: 'compensation_rule_saved');
      expect(logs.length, 1);
      final log = logs.first;
      expect(log.performedByUserId, 'usr_hr_01');
      expect(log.branchId, 'branch_1');
      expect(log.details, contains('doctorId: DOC-05'));
      expect(log.details, contains('percentage: 35'));
      expect(log.details, contains('compensationType: percentage'));

      // Check strict privacy: no patient names or sensitive details in audit log
      expect(log.details, isNot(contains('patient')));
    });

    test('14. Emits zero audit logs on validation failure or permission denied', () async {
      final initialLogsCount = auditLogger.getLogs().length;

      // 1. Validation failure: missing doctorId
      final valRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: '',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: CairoTimeHelper.now(),
      ));
      expect(valRes.isLeft(), isTrue);
      expect(auditLogger.getLogs().length, initialLogsCount);

      // 2. Permission failure: receptionist
      userProvider.user = const StaffUserModel(
        id: 'usr_reception_test',
        fullName: 'أحمد استقبال',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.reception]),
        ],
      );

      final permRes = await saveRuleUseCase(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: CairoTimeHelper.now(),
      ));
      expect(permRes.isLeft(), isTrue);
      expect(auditLogger.getLogs().length, initialLogsCount);
    });

    test('15. Active rule retrieval picks correct rule by effective date', () async {
      final date1 = DateTime(2026, 1, 1);
      final date2 = DateTime(2026, 4, 1);
      final date3 = DateTime(2026, 7, 1);

      // Add three rules in chronological order
      await repo.saveCompensationRule(DoctorCompensationRuleModel(
        id: 'RULE-V1',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 30,
        effectiveFrom: date1,
      ));
      await repo.saveCompensationRule(DoctorCompensationRuleModel(
        id: 'RULE-V2',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: date2,
      ));
      await repo.saveCompensationRule(DoctorCompensationRuleModel(
        id: 'RULE-V3',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 50,
        effectiveFrom: date3,
      ));

      // As of March 2026 (between date1 and date2) -> should pick RULE-V1 (30%)
      final marchRes = await getActiveRuleUseCase(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        date: DateTime(2026, 3, 15),
      );
      expect(marchRes.isRight(), isTrue);
      expect(marchRes.getOrElse(() => const DoctorCompensationRuleModel()).commissionPercentage, 30);

      // As of May 2026 (between date2 and date3) -> should pick RULE-V2 (40%)
      final mayRes = await getActiveRuleUseCase(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        date: DateTime(2026, 5, 10),
      );
      expect(mayRes.isRight(), isTrue);
      expect(mayRes.getOrElse(() => const DoctorCompensationRuleModel()).commissionPercentage, 40);

      // As of August 2026 (after date3) -> should pick RULE-V3 (50%)
      final augRes = await getActiveRuleUseCase(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        date: DateTime(2026, 8, 1),
      );
      expect(augRes.isRight(), isTrue);
      expect(augRes.getOrElse(() => const DoctorCompensationRuleModel()).commissionPercentage, 50);
    });
  });
}

