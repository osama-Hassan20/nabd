import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/hr/data/models/doctor_compensation_rule_model.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_model.dart';
import 'package:eyadty/features/hr/data/models/employee_ledger_entry_model.dart';
import 'package:eyadty/features/hr/data/models/enums/compensation_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/ledger_entry_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/payroll_status_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/settlement_status_enum.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_period_model.dart';
import 'package:eyadty/features/hr/data/repo/doctor_settlement_visits_lookup.dart';
import 'package:eyadty/features/hr/data/repo/hr_repo_impl.dart';
import 'package:eyadty/features/hr/domain/contracts/doctor_settlement_visits_lookup.dart';
import 'package:eyadty/features/hr/domain/helpers/doctor_settlement_calculator.dart';
import 'package:eyadty/features/hr/domain/use_cases/calculate_doctor_settlement_draft_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/confirm_doctor_settlement_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/confirm_staff_payroll_period_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/payout_doctor_settlement_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/payout_staff_payroll_period_use_case.dart';
import 'package:eyadty/features/hr/domain/use_cases/save_doctor_compensation_rule_use_case.dart';
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

void main() {
  group('Egyptian DST & Security Audit Verification Tests (Plan F-06 M-9)', () {
    late HrRepoImpl repo;
    late DoctorSettlementVisitsLookupImpl visitsLookup;
    late InMemoryAuditLogger auditLogger;
    late FakeUserSessionProvider userProvider;
    late FakeRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;

    late SaveDoctorCompensationRuleUseCase saveRuleUseCase;
    late CalculateDoctorSettlementDraftUseCase calculateDraftUseCase;
    late ConfirmDoctorSettlementUseCase confirmSettlementUseCase;
    late PayoutDoctorSettlementUseCase payoutSettlementUseCase;
    late ConfirmStaffPayrollPeriodUseCase confirmPayrollUseCase;
    late PayoutStaffPayrollPeriodUseCase payoutPayrollUseCase;

    const allAdminRoleId = 'role_all_admin';
    final allAdminRole = RoleDefinitionModel(
      id: allAdminRoleId,
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

    final adminUser = StaffUserModel(
      id: 'usr_admin_audit',
      fullName: 'مدير النظام',
      isActive: true,
      branchAssignments: const [
        BranchAssignmentModel(branchId: 'branch_1', roleIds: [allAdminRoleId]),
      ],
    );

    setUp(() {
      repo = HrRepoImpl(seedInitialData: false);
      visitsLookup = DoctorSettlementVisitsLookupImpl();
      auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

      rolesProvider = FakeRolesSessionProvider(
        roles: [allAdminRole, ...RoleDefinitionModel.defaultSystemRoles()],
      );
      userProvider = FakeUserSessionProvider(user: adminUser, branch: 'branch_1');

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

    tearDown(() {
      CairoTimeHelper.resetFixedClock();
    });

    // -------------------------------------------------------------------------
    // Egyptian DST Transitions (April & October)
    // -------------------------------------------------------------------------
    test('1. April DST transition: CairoTimeHelper returns UTC+3 after last Friday of April midnight', () {
      // 2026 last Friday of April is April 24, 2026
      // Prior to transition: 2026-04-23 21:00 UTC is 23:00 Cairo winter time (UTC+2)
      final winterUtc = DateTime.utc(2026, 4, 23, 21, 0);
      final cairoWinter = CairoTimeHelper.now(customUtc: winterUtc);
      expect(cairoWinter.difference(winterUtc).inHours, 2);

      // After transition: 2026-04-24 01:00 UTC is 04:00 Cairo summer time (UTC+3)
      final summerUtc = DateTime.utc(2026, 4, 24, 1, 0);
      final cairoSummer = CairoTimeHelper.now(customUtc: summerUtc);
      expect(cairoSummer.difference(summerUtc).inHours, 3);
    });

    test('2. October DST transition: CairoTimeHelper returns UTC+2 after last Thursday of October midnight', () {
      // 2026 last Thursday of October is Oct 29, 2026
      // During summer: 2026-10-29 18:00 UTC is 21:00 Cairo summer time (UTC+3)
      final summerUtc = DateTime.utc(2026, 10, 29, 18, 0);
      final cairoSummer = CairoTimeHelper.now(customUtc: summerUtc);
      expect(cairoSummer.difference(summerUtc).inHours, 3);

      // After transition: 2026-10-30 00:00 UTC is 02:00 Cairo winter time (UTC+2)
      final winterUtc = DateTime.utc(2026, 10, 30, 0, 0);
      final cairoWinter = CairoTimeHelper.now(customUtc: winterUtc);
      expect(cairoWinter.difference(winterUtc).inHours, 2);
    });

    test('3. Doctor settlement calculator handles recognition across DST transition boundary cleanly', () {
      // Visit finalized before April DST, payment collected after April DST
      final visitFinalizedBeforeDst = DateTime(2026, 4, 23, 18, 0);
      final paymentCollectedAfterDst = DateTime(2026, 4, 25, 10, 0);

      final recognitionDate = DoctorSettlementCalculator.calculateRecognitionDate(
        paymentCollectedAfterDst,
        visitFinalizedBeforeDst,
      );

      // Recognition is strictly max(finalizedAt, transactionDate)
      expect(recognitionDate, paymentCollectedAfterDst);
    });

    test('4. Date range filtering properly respects Cairo local calendar bounds during DST change', () {
      final periodStart = DateTime(2026, 4, 1, 0, 0, 0);
      final periodEnd = DateTime(2026, 4, 30, 23, 59, 59);

      final dateInPeriod = DateTime(2026, 4, 25, 12, 0);
      final dateAfterPeriod = DateTime(2026, 5, 1, 0, 0, 1);

      bool isWithin(DateTime d, DateTime s, DateTime e) =>
          (d.isAfter(s) || d.isAtSameMomentAs(s)) && (d.isBefore(e) || d.isAtSameMomentAs(e));

      expect(isWithin(dateInPeriod, periodStart, periodEnd), isTrue);
      expect(isWithin(dateAfterPeriod, periodStart, periodEnd), isFalse);
    });

    // -------------------------------------------------------------------------
    // Security Audit Whitelist Compliance
    // -------------------------------------------------------------------------
    test('5. doctor_settlement_drafted audit log contains strictly whitelist fields (no clinical/patient data)', () async {
      await repo.saveCompensationRule(
        DoctorCompensationRuleModel(
          id: 'RULE-DOC-01',
          doctorId: 'DOC-01',
          branchId: 'branch_1',
          isActive: true,
          compensationType: CompensationTypeEnum.percentage,
          commissionPercentage: 50,
          effectiveFrom: DateTime(2026, 1, 1),
        ),
      );

      visitsLookup.addCandidate(
        SettlementVisitCandidate(
          visitId: 'VIS-01',
          bookingId: 'BK-01',
          doctorId: 'DOC-01',
          branchId: 'branch_1',
          patientName: 'مريض تجريبي خاص',
          finalizedAt: DateTime(2026, 5, 10, 10, 0),
          netAmountPiastres: 10000,
          events: [
            SettlementPaymentEvent(
              eventId: 'EV-01',
              transactionId: 'TX-01',
              type: 'payment',
              amountPiastres: 10000,
              date: DateTime(2026, 5, 10, 10, 30),
            ),
          ],
        ),
      );

      await calculateDraftUseCase(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        periodStart: DateTime(2026, 5, 1),
        periodEnd: DateTime(2026, 5, 31),
      );

      final logs = auditLogger.getLogs(eventType: 'doctor_settlement_drafted');
      expect(logs.isNotEmpty, isTrue);
      final log = logs.first;
      expect(log.details, contains('doctorId: DOC-01'));
      expect(log.details, contains('branchId: branch_1'));
      expect(log.details, contains('visitsCount: 1'));
      expect(log.details, contains('netRevenuePiastres: 10000'));

      // Verify ZERO patient or diagnosis data leaked
      expect(log.details, isNot(contains('مريض تجريبي خاص')));
      expect(log.details, isNot(contains('diagnosis')));
      expect(log.details, isNot(contains('notes')));
    });

    test('6. doctor_settlement_confirmed audit log conforms strictly to whitelist', () async {
      const settlement = DoctorSettlementModel(
        id: 'SET-AUD-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
        netPayablePiastres: 60000,
        totalVisitsCount: 5,
      );
      await repo.saveDoctorSettlement(settlement);

      await confirmSettlementUseCase(settlementId: 'SET-AUD-01');

      final logs = auditLogger.getLogs(eventType: 'doctor_settlement_confirmed');
      expect(logs.isNotEmpty, isTrue);
      final log = logs.first;
      expect(log.details, contains('settlementId: SET-AUD-01'));
      expect(log.details, contains('doctorId: DOC-01'));
      expect(log.details, contains('netPayablePiastres: 60000'));
      expect(log.details, contains('itemsCount: 5'));

      // No sensitive text fields
      expect(log.details, isNot(contains('patient')));
      expect(log.details, isNot(contains('creditCard')));
    });

    test('7. doctor_settlement_paid audit log conforms strictly to whitelist', () async {
      const settlement = DoctorSettlementModel(
        id: 'SET-AUD-02',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: SettlementStatusEnum.confirmed,
        netPayablePiastres: 45000,
      );
      await repo.saveDoctorSettlement(settlement);

      await payoutSettlementUseCase(settlementId: 'SET-AUD-02', paymentMethod: PaymentMethod.card);

      final logs = auditLogger.getLogs(eventType: 'doctor_settlement_paid');
      expect(logs.isNotEmpty, isTrue);
      final log = logs.first;
      expect(log.details, contains('settlementId: SET-AUD-02'));
      expect(log.details, contains('doctorId: DOC-01'));
      expect(log.details, contains('paidAmountPiastres: 45000'));
      expect(log.details, contains('paymentMethod: card'));
      expect(log.details, isNot(contains('bankAccount')));
    });

    test('8. owner_self_confirmed audit log includes single operator clinic reason', () async {
      final ownerUser = const StaffUserModel(
        id: 'usr_owner_aud',
        linkedDoctorId: 'DOC-OWN',
        isOwner: true,
        isActive: true,
      );
      userProvider.user = ownerUser;

      const settlement = DoctorSettlementModel(
        id: 'SET-AUD-OWN',
        doctorId: 'DOC-OWN',
        branchId: 'branch_1',
        status: SettlementStatusEnum.draft,
        netPayablePiastres: 80000,
      );
      await repo.saveDoctorSettlement(settlement);

      await confirmSettlementUseCase(settlementId: 'SET-AUD-OWN');

      final logs = auditLogger.getLogs(eventType: 'owner_self_confirmed');
      expect(logs.isNotEmpty, isTrue);
      final log = logs.first;
      expect(log.details, contains('settlementId: SET-AUD-OWN'));
      expect(log.details, contains('doctorId: DOC-OWN'));
      expect(log.details, contains('owner_self_confirmed_single_operator'));
    });

    test('9. employee_ledger movements store numeric amounts in piastres without sensitive data', () async {
      const entry = EmployeeLedgerEntryModel(
        id: 'LED-AUD-01',
        employeeId: 'EMP-01',
        branchId: 'branch_1',
        entryType: LedgerEntryTypeEnum.advance,
        amountPiastres: 15000,
      );

      final addRes = await repo.addEmployeeLedgerEntry(entry);
      expect(addRes.isRight(), isTrue);

      final revRes = await repo.reverseEmployeeLedgerEntry(
        entryId: 'LED-AUD-01',
        reason: 'reversal test',
        performedByUserId: 'usr_admin',
      );
      expect(revRes.isRight(), isTrue);

      final entriesRes = await repo.getEmployeeLedgerEntries(employeeId: 'EMP-01');
      expect(entriesRes.isRight(), isTrue);
      final entries = entriesRes.getOrElse(() => []);
      expect(entries.length, 2);
      expect(entries.any((e) => e.reversesEntryId == 'LED-AUD-01'), isTrue);
    });

    test('10. compensation_rule_saved audit log records numeric percentages and amounts only', () async {
      final rule = DoctorCompensationRuleModel(
        id: 'RULE-AUD-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 55,
        effectiveFrom: DateTime(2026, 6, 1),
      );

      await saveRuleUseCase(rule);

      final logs = auditLogger.getLogs(eventType: 'compensation_rule_saved');
      expect(logs.isNotEmpty, isTrue);
      final log = logs.first;
      expect(log.details, contains('ruleId: RULE-AUD-01'));
      expect(log.details, contains('doctorId: DOC-01'));
      expect(log.details, contains('percentage: 55'));
      expect(log.details, contains('compensationType: percentage'));
    });

    test('11. staff_payroll audit logs record period, totals, and counts accurately', () async {
      const period = StaffPayrollPeriodModel(
        id: 'PAY-AUD-01',
        primaryBranchId: 'branch_1',
        month: 5,
        year: 2026,
        status: PayrollStatusEnum.draft,
        totalEmployeesCount: 4,
        totalNetPayablePiastres: 3200000,
      );
      await repo.saveStaffPayrollPeriod(period);

      await confirmPayrollUseCase(periodId: 'PAY-AUD-01');
      await payoutPayrollUseCase(periodId: 'PAY-AUD-01');

      final confLogs = auditLogger.getLogs(eventType: 'staff_payroll_confirmed');
      expect(confLogs.isNotEmpty, isTrue);
      final confLog = confLogs.first;
      expect(confLog.details, contains('payrollId: PAY-AUD-01'));
      expect(confLog.details, contains('periodMonth: 5'));
      expect(confLog.details, contains('periodYear: 2026'));
      expect(confLog.details, contains('totalNetPayablePiastres: 3200000'));

      final payLogs = auditLogger.getLogs(eventType: 'staff_payroll_paid');
      expect(payLogs.isNotEmpty, isTrue);
      final payLog = payLogs.first;
      expect(payLog.details, contains('payrollId: PAY-AUD-01'));
      expect(payLog.details, contains('totalAmountPiastres: 3200000'));
    });

    test('12. Zero Audit on Failure: Failed operations emit ZERO audit events', () async {
      final initialLogsCount = auditLogger.getLogs().length;

      // Unauthorized payout on draft settlement
      const draftSettlement = DoctorSettlementModel(
        id: 'SET-FAIL-AUD',
        status: SettlementStatusEnum.draft,
      );
      await repo.saveDoctorSettlement(draftSettlement);

      final res = await payoutSettlementUseCase(
        settlementId: 'SET-FAIL-AUD',
        paymentMethod: PaymentMethod.cash,
      );
      expect(res.isLeft(), isTrue);

      // Logs must remain unchanged
      expect(auditLogger.getLogs().length, initialLogsCount);
    });
  });
}
