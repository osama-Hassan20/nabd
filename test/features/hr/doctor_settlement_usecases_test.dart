import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/hr/data/models/doctor_compensation_rule_model.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_model.dart';
import 'package:eyadty/features/hr/data/models/employee_ledger_entry_model.dart';
import 'package:eyadty/features/hr/data/models/enums/compensation_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/ledger_entry_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/settlement_status_enum.dart';
import 'package:eyadty/features/hr/data/repo/doctor_settlement_visits_lookup.dart';
import 'package:eyadty/features/hr/data/repo/hr_repo_impl.dart';
import 'package:eyadty/features/hr/domain/contracts/doctor_settlement_visits_lookup.dart';
import 'package:eyadty/features/hr/domain/use_cases/calculate_doctor_settlement_draft_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/confirm_doctor_settlement_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/payout_doctor_settlement_use_case.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class SettlementTestUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  SettlementTestUserSessionProvider({this.user, this.branch = 'branch_1'});

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch;
}

class SettlementTestRolesSessionProvider implements RolesProvider {
  List<RoleDefinitionModel> roles;
  SettlementTestRolesSessionProvider({required this.roles});

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

void main() {
  group('Doctor Settlement Use Cases Tests (Plan F-06 M-3)', () {
    late HrRepoImpl repo;
    late DoctorSettlementVisitsLookupImpl visitsLookup;
    late InMemoryAuditLogger auditLogger;
    late SettlementTestUserSessionProvider userProvider;
    late SettlementTestRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;

    late CalculateDoctorSettlementDraftUseCase calculateDraftUseCase;
    late ConfirmDoctorSettlementUseCase confirmUseCase;
    late PayoutDoctorSettlementUseCase payoutUseCase;

    const managerRoleId = 'role_branch_manager_custom';
    final managerRole = RoleDefinitionModel(
      id: managerRoleId,
      nameAr: 'مدير فرع',
      nameEn: 'Branch Manager',
      permissions: [
        StaffPermissionEnum.calculateDoctorSettlement,
        StaffPermissionEnum.confirmDoctorSettlement,
        StaffPermissionEnum.accessHr,
      ],
    );

    const accountantRoleId = 'role_accountant_custom';
    final accountantRole = RoleDefinitionModel(
      id: accountantRoleId,
      nameAr: 'محاسب',
      nameEn: 'Accountant',
      permissions: [
        StaffPermissionEnum.calculateDoctorSettlement,
        StaffPermissionEnum.confirmDoctorSettlement,
        StaffPermissionEnum.payoutSettlement,
        StaffPermissionEnum.accessHr,
      ],
    );

    setUp(() {
      repo = HrRepoImpl(seedInitialData: false);
      visitsLookup = DoctorSettlementVisitsLookupImpl();
      auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

      rolesProvider = SettlementTestRolesSessionProvider(
        roles: [...RoleDefinitionModel.defaultSystemRoles(), managerRole, accountantRole],
      );

      // Default authorized user: Branch Manager (can calculate & confirm, but cannot payout)
      userProvider = SettlementTestUserSessionProvider(
        user: const StaffUserModel(
          id: 'usr_manager_01',
          fullName: 'عمرو مدير',
          isActive: true,
          branchAssignments: [
            BranchAssignmentModel(branchId: 'branch_1', roleIds: [managerRoleId]),
          ],
        ),
      );

      permissionEvaluator = PermissionEvaluator(
        userProvider: userProvider,
        rolesProvider: rolesProvider,
      );

      calculateDraftUseCase = CalculateDoctorSettlementDraftUseCase(
        hrRepo: repo,
        visitsLookup: visitsLookup,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      confirmUseCase = ConfirmDoctorSettlementUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      payoutUseCase = PayoutDoctorSettlementUseCase(
        hrRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );
    });

    test('1. Calculate draft settlement successfully from visits and payment transactions', () async {
      final periodStart = DateTime(2026, 5, 1);
      final periodEnd = DateTime(2026, 5, 31, 23, 59, 59);

      // 1. Seed compensation rule for DOC-01: 40%
      await repo.saveCompensationRule(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: DateTime(2026, 1, 1),
      ));

      // 2. Seed visit candidate with payment event
      visitsLookup.addCandidate(SettlementVisitCandidate(
        visitId: 'VISIT-001',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        finalizedAt: DateTime(2026, 5, 10, 10, 0),
        netAmountPiastres: 20000, // 200 EGP
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-001',
            type: 'payment',
            amountPiastres: 20000,
            date: DateTime(2026, 5, 10, 10, 5),
          ),
        ],
      ));

      final res = await calculateDraftUseCase(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      expect(res.isRight(), isTrue);
      final draft = res.getOrElse(() => const DoctorSettlementModel());
      expect(draft.status, SettlementStatusEnum.draft);
      expect(draft.totalVisitsCount, 1);
      expect(draft.totalNetRevenuePiastres, 20000);
      expect(draft.totalDoctorCommissionPiastres, 8000); // 40% of 20000 = 8000
      expect(draft.totalClinicSharePiastres, 12000);
      expect(draft.netPayablePiastres, 8000);
    });

    test('2. Draft settlement includes accurate item snapshot with doctor earned and clinic share', () async {
      final periodStart = DateTime(2026, 5, 1);
      final periodEnd = DateTime(2026, 5, 31, 23, 59, 59);

      await repo.saveCompensationRule(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 50,
        effectiveFrom: DateTime(2026, 1, 1),
      ));

      visitsLookup.addCandidate(SettlementVisitCandidate(
        visitId: 'VISIT-002',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        finalizedAt: DateTime(2026, 5, 12, 11, 0),
        netAmountPiastres: 30000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-002',
            type: 'payment',
            amountPiastres: 30000,
            date: DateTime(2026, 5, 12, 11, 0),
          ),
        ],
      ));

      final res = await calculateDraftUseCase(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      expect(res.isRight(), isTrue);
      final draft = res.getOrElse(() => const DoctorSettlementModel());
      expect(draft.items?.length, 1);
      final item = draft.items!.first;
      expect(item.visitId, 'VISIT-002');
      expect(item.recognizedAmountPiastres, 30000);
      expect(item.doctorEarnedPiastres, 15000);
      expect(item.clinicSharePiastres, 15000);
    });

    test('3. Consumed events and advances are tracked in draft settlement', () async {
      final periodStart = DateTime(2026, 5, 1);
      final periodEnd = DateTime(2026, 5, 31, 23, 59, 59);

      await repo.saveCompensationRule(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 50,
        effectiveFrom: DateTime(2026, 1, 1),
      ));

      // Add advance to ledger
      final advRes = await repo.addEmployeeLedgerEntry(EmployeeLedgerEntryModel(
        id: 'ADV-01',
        employeeId: 'DOC-01',
        branchId: 'branch_1',
        entryType: LedgerEntryTypeEnum.advance,
        amountPiastres: 5000, // 50 EGP advance
        date: DateTime(2026, 5, 5),
      ));
      expect(advRes.isRight(), isTrue);

      visitsLookup.addCandidate(SettlementVisitCandidate(
        visitId: 'VISIT-003',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        finalizedAt: DateTime(2026, 5, 15),
        netAmountPiastres: 20000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-003',
            type: 'payment',
            amountPiastres: 20000,
            date: DateTime(2026, 5, 15),
          ),
        ],
      ));

      final res = await calculateDraftUseCase(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      expect(res.isRight(), isTrue);
      final draft = res.getOrElse(() => const DoctorSettlementModel());
      expect(draft.consumedEventIds, contains('EV-003'));
      expect(draft.consumedAdvanceEntryIds, contains('ADV-01'));
      expect(draft.totalAdvancesDeductedPiastres, 5000);
      expect(draft.netPayablePiastres, 5000); // 10000 earnings - 5000 advance = 5000
    });

    test('4. Overlapping settlement period rejection for same doctor and branch', () async {
      final periodStart = DateTime(2026, 5, 1);
      final periodEnd = DateTime(2026, 5, 31, 23, 59, 59);

      // Seed already confirmed settlement for May 2026
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-CONFIRMED-MAY',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        status: SettlementStatusEnum.confirmed,
      ));

      // Attempting to calculate draft for overlapping period (e.g. May 15 to June 15) must fail
      final res = await calculateDraftUseCase(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: DateTime(2026, 5, 15),
        periodEnd: DateTime(2026, 6, 15),
      );

      expect(res.isLeft(), isTrue);
    });

    test('5. Non-overlapping periods allowed', () async {
      // Confirmed settlement for May
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-CONFIRMED-MAY',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: DateTime(2026, 5, 1),
        periodEnd: DateTime(2026, 5, 31, 23, 59, 59),
        status: SettlementStatusEnum.confirmed,
      ));

      // Rule exists
      await repo.saveCompensationRule(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: DateTime(2026, 1, 1),
      ));

      // Non-overlapping June period must succeed
      final res = await calculateDraftUseCase(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: DateTime(2026, 6, 1),
        periodEnd: DateTime(2026, 6, 30, 23, 59, 59),
      );

      expect(res.isRight(), isTrue);
    });

    test('6. Empty visits period produces zero-item settlement with base salary applied if applicable', () async {
      // Doctor with salary-only rule: 15,000 EGP
      await repo.saveCompensationRule(DoctorCompensationRuleModel(
        doctorId: 'DOC-SAL',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.salaryOnly,
        monthlyBaseSalaryPiastres: 1500000,
        effectiveFrom: DateTime(2026, 1, 1),
      ));

      // Zero visits for the period
      final res = await calculateDraftUseCase(
        doctorId: 'DOC-SAL',
        branchId: 'branch_1',
        periodStart: DateTime(2026, 5, 1),
        periodEnd: DateTime(2026, 5, 31, 23, 59, 59),
      );

      expect(res.isRight(), isTrue);
      final draft = res.getOrElse(() => const DoctorSettlementModel());
      expect(draft.totalVisitsCount, 0);
      expect(draft.baseSalaryPiastres, 1500000);
      expect(draft.netPayablePiastres, 1500000);
    });

    test('7. Confirm settlement locks status to confirmed and records confirmedByUserId and confirmedAt', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-DRAFT-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
        netPayablePiastres: 50000,
      ));

      final res = await confirmUseCase(settlementId: 'SET-DRAFT-01');
      expect(res.isRight(), isTrue);
      final confirmed = res.getOrElse(() => const DoctorSettlementModel());
      expect(confirmed.status, SettlementStatusEnum.confirmed);
      expect(confirmed.confirmedByUserId, 'usr_manager_01');
      expect(confirmed.confirmedAt, isNotNull);
      expect(confirmed.isOwnerSelfConfirmed, isFalse);
    });

    test('8. Confirmation requires non-attending authorizer (separation of duties: approver != doctor)', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-DRAFT-DOC1',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
      ));

      // User who is doctor DOC-01 attempts to confirm their own settlement
      userProvider.user = const StaffUserModel(
        id: 'usr_doc_01',
        fullName: 'د. طارق',
        linkedDoctorId: 'DOC-01',
        isOwner: false,
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [managerRoleId]),
        ],
      );

      final res = await confirmUseCase(settlementId: 'SET-DRAFT-DOC1');
      expect(res.isLeft(), isTrue);
    });

    test('9. Owner self-confirmation exception: single owner can confirm own settlement', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-DRAFT-OWNER',
        doctorId: 'DOC-OWNER',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
        netPayablePiastres: 80000,
      ));

      // Practicing Owner
      userProvider.user = const StaffUserModel(
        id: 'usr_owner_single',
        fullName: 'د. خالد (المالك)',
        linkedDoctorId: 'DOC-OWNER',
        isOwner: true,
        isActive: true,
      );

      final res = await confirmUseCase(settlementId: 'SET-DRAFT-OWNER');
      expect(res.isRight(), isTrue);
      final confirmed = res.getOrElse(() => const DoctorSettlementModel());
      expect(confirmed.status, SettlementStatusEnum.confirmed);
      expect(confirmed.isOwnerSelfConfirmed, isTrue);
    });

    test('10. Owner self-confirmation emits owner_self_confirmed audit log with single operator reason', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-DRAFT-OWNER-AUDIT',
        doctorId: 'DOC-OWNER',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
        netPayablePiastres: 90000,
      ));

      userProvider.user = const StaffUserModel(
        id: 'usr_owner_audit',
        fullName: 'د. خالد المالك',
        linkedDoctorId: 'DOC-OWNER',
        isOwner: true,
        isActive: true,
      );

      final res = await confirmUseCase(settlementId: 'SET-DRAFT-OWNER-AUDIT');
      expect(res.isRight(), isTrue);

      final logs = auditLogger.getLogs(eventType: 'owner_self_confirmed');
      expect(logs.length, 1);
      final log = logs.first;
      expect(log.details, contains('owner_self_confirmed_single_operator'));
      expect(log.details, contains('netPayablePiastres: 90000'));
    });

    test('11. Payout settlement transitions status to paid and sets paidAt, paymentMethod, refNumber', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-CONF-PAYOUT',
        settlementNumber: 'SET-DOC-202605-001',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
        netPayablePiastres: 120000,
      ));

      // User must have payoutSettlement permission (Accountant role)
      userProvider.user = const StaffUserModel(
        id: 'usr_accountant_01',
        fullName: 'محمود محاسب',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );

      final res = await payoutUseCase(
        settlementId: 'SET-CONF-PAYOUT',
        paymentMethod: PaymentMethod.bankTransfer,
        paymentReferenceNumber: 'TRX-BANK-9988',
      );

      expect(res.isRight(), isTrue);
      final paid = res.getOrElse(() => const DoctorSettlementModel());
      expect(paid.status, SettlementStatusEnum.paid);
      expect(paid.paidAt, isNotNull);
      expect(paid.paymentMethod, PaymentMethod.bankTransfer);
      expect(paid.paymentReferenceNumber, 'TRX-BANK-9988');
    });

    test('12. Payout settlement automatically records payout entry in employee ledger', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-CONF-LEDGER',
        settlementNumber: 'SET-DOC-202605-002',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
        netPayablePiastres: 150000,
      ));

      userProvider.user = const StaffUserModel(
        id: 'usr_accountant_01',
        fullName: 'محمود محاسب',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );

      final res = await payoutUseCase(
        settlementId: 'SET-CONF-LEDGER',
        paymentMethod: PaymentMethod.cash,
      );
      expect(res.isRight(), isTrue);

      // Verify ledger has a payout entry
      final ledgerRes = await repo.getEmployeeLedgerEntries(employeeId: 'DOC-01');
      expect(ledgerRes.isRight(), isTrue);
      final entries = ledgerRes.getOrElse(() => []);
      final payoutEntries = entries.where((e) => e.entryType == LedgerEntryTypeEnum.payout).toList();
      expect(payoutEntries.length, 1);
      expect(payoutEntries.first.amountPiastres, 150000);
    });

    test('13. Cannot confirm an already confirmed or paid settlement', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-ALREADY-CONFIRMED',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
      ));

      final res = await confirmUseCase(settlementId: 'SET-ALREADY-CONFIRMED');
      expect(res.isLeft(), isTrue);
    });

    test('14. Cannot payout an unconfirmed (draft) settlement', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-DRAFT-UNCONF',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
      ));

      userProvider.user = const StaffUserModel(
        id: 'usr_accountant_01',
        fullName: 'محمود محاسب',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );

      final res = await payoutUseCase(
        settlementId: 'SET-DRAFT-UNCONF',
        paymentMethod: PaymentMethod.cash,
      );
      expect(res.isLeft(), isTrue);
    });

    test('15. Cannot payout an already paid settlement', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-ALREADY-PAID',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.paid,
      ));

      userProvider.user = const StaffUserModel(
        id: 'usr_accountant_01',
        fullName: 'محمود محاسب',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );

      final res = await payoutUseCase(
        settlementId: 'SET-ALREADY-PAID',
        paymentMethod: PaymentMethod.cash,
      );
      expect(res.isLeft(), isTrue);
    });

    test('16. Unauthorized user cannot calculate draft settlement (enforces calculateDoctorSettlement)', () async {
      // User with Receptionist role only (no calculateDoctorSettlement)
      userProvider.user = const StaffUserModel(
        id: 'usr_reception_only',
        fullName: 'سالي استقبال',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.reception]),
        ],
      );

      final res = await calculateDraftUseCase(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: DateTime(2026, 5, 1),
        periodEnd: DateTime(2026, 5, 31, 23, 59, 59),
      );

      expect(res.isLeft(), isTrue);
    });

    test('17. Unauthorized user cannot confirm settlement (enforces confirmDoctorSettlement)', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-DRAFT-NO-PERM',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
      ));

      // User with Doctor role only (no confirmDoctorSettlement)
      userProvider.user = const StaffUserModel(
        id: 'usr_other_doc',
        fullName: 'د. سامح',
        linkedDoctorId: 'DOC-99',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.doctor]),
        ],
      );

      final res = await confirmUseCase(settlementId: 'SET-DRAFT-NO-PERM');
      expect(res.isLeft(), isTrue);
    });

    test('18. Unauthorized user cannot payout settlement (enforces payoutSettlement - manager rejected)', () async {
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-CONF-NO-PAY-PERM',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
        netPayablePiastres: 50000,
      ));

      // Branch Manager has calculate & confirm, but lacks payoutSettlement
      userProvider.user = const StaffUserModel(
        id: 'usr_manager_01',
        fullName: 'عمرو مدير',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [managerRoleId]),
        ],
      );

      final res = await payoutUseCase(
        settlementId: 'SET-CONF-NO-PAY-PERM',
        paymentMethod: PaymentMethod.cash,
      );
      expect(res.isLeft(), isTrue);
    });

    test('19. Emits security audit logs for draft, confirmation, and payout with strict numeric whitelist', () async {
      final periodStart = DateTime(2026, 5, 1);
      final periodEnd = DateTime(2026, 5, 31, 23, 59, 59);

      await repo.saveCompensationRule(DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 50,
        effectiveFrom: DateTime(2026, 1, 1),
      ));

      visitsLookup.addCandidate(SettlementVisitCandidate(
        visitId: 'VISIT-AUD-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        finalizedAt: DateTime(2026, 5, 10),
        netAmountPiastres: 10000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-AUD-01',
            type: 'payment',
            amountPiastres: 10000,
            date: DateTime(2026, 5, 10),
          ),
        ],
      ));

      // 1. Draft
      final draftRes = await calculateDraftUseCase(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      expect(draftRes.isRight(), isTrue);
      final draft = draftRes.getOrElse(() => const DoctorSettlementModel());

      final draftLogs = auditLogger.getLogs(eventType: 'doctor_settlement_drafted');
      expect(draftLogs.length, 1);
      expect(draftLogs.first.details, contains('doctorId: DOC-01'));
      expect(draftLogs.first.details, contains('commissionPiastres: 5000'));

      // 2. Confirm
      final confirmRes = await confirmUseCase(settlementId: draft.id!);
      expect(confirmRes.isRight(), isTrue);

      final confLogs = auditLogger.getLogs(eventType: 'doctor_settlement_confirmed');
      expect(confLogs.length, 1);
      expect(confLogs.first.details, contains('netPayablePiastres: 5000'));

      // 3. Payout
      userProvider.user = const StaffUserModel(
        id: 'usr_accountant_01',
        fullName: 'محمود محاسب',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );

      final payRes = await payoutUseCase(
        settlementId: draft.id!,
        paymentMethod: PaymentMethod.cash,
      );
      expect(payRes.isRight(), isTrue);

      final payLogs = auditLogger.getLogs(eventType: 'doctor_settlement_paid');
      expect(payLogs.length, 1);
      expect(payLogs.first.details, contains('paidAmountPiastres: 5000'));
      expect(payLogs.first.details, contains('paymentMethod: cash'));

      // Strict privacy check: zero clinical/patient names in details
      for (final log in auditLogger.getLogs()) {
        expect(log.details, isNot(contains('patient')));
        expect(log.details, isNot(contains('diagnosis')));
      }
    });

    test('20. Zero audit logs emitted on any failure or authorization denial', () async {
      final initialLogsCount = auditLogger.getLogs().length;

      // Calculation authorization failure
      userProvider.user = const StaffUserModel(
        id: 'usr_reception_only',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.reception]),
        ],
      );
      await calculateDraftUseCase(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: DateTime(2026, 5, 1),
        periodEnd: DateTime(2026, 5, 31),
      );
      expect(auditLogger.getLogs().length, initialLogsCount);

      // Confirmation failure on non-existent settlement
      await confirmUseCase(settlementId: 'NON-EXISTENT');
      expect(auditLogger.getLogs().length, initialLogsCount);

      // Payout failure on unconfirmed
      await repo.saveDoctorSettlement(DoctorSettlementModel(
        id: 'SET-DRAFT-FAIL',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
      ));
      await payoutUseCase(
        settlementId: 'SET-DRAFT-FAIL',
        paymentMethod: PaymentMethod.cash,
      );
      expect(auditLogger.getLogs().length, initialLogsCount);
    });
  });
}
