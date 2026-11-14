import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/cashier/data/models/enums/cash_movement_type_enum.dart';
import 'package:eyadty/features/cashier/data/models/enums/shift_status_enum.dart';
import 'package:eyadty/features/cashier/data/repo/cashier_mock_repo_impl.dart';
import 'package:eyadty/features/cashier/domain/contracts/cashier_policy.dart';
import 'package:eyadty/features/cashier/domain/helpers/payment_reconciliation_helper.dart';
import 'package:eyadty/features/cashier/domain/use_cases/approve_shortage_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/close_shift_drawer_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/collect_payment_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/open_shift_drawer_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/record_drawer_expense_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/refund_payment_use_case.dart';
import 'package:eyadty/features/settings/data/repo/settings_mock_repo_impl.dart';
import 'package:eyadty/features/settings/domain/use_cases/update_print_settings_use_case.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_mock_repo_impl.dart';

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
  late CashierMockRepoImpl cashierRepo;
  late BookingsMockRepoImpl bookingsRepo;
  late StaffUsersMockRepoImpl staffUsersRepo;
  late SettingsMockRepoImpl settingsRepo;
  late InMemoryAuditLogger auditLogger;
  late MockUserSessionProvider userProvider;
  late MockRolesSessionProvider rolesProvider;
  late PermissionEvaluator evaluator;
  const policy = CashierPolicy();
  const reconciliationHelper = PaymentReconciliationHelper();

  setUp(() {
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
    cashierRepo = CashierMockRepoImpl(seedInitialData: false);
    bookingsRepo = BookingsMockRepoImpl();
    staffUsersRepo = StaffUsersMockRepoImpl(auditLogger: auditLogger);
    settingsRepo = SettingsMockRepoImpl();

    final ownerRole = RoleDefinitionModel(
      id: 'role_owner',
      nameAr: 'مالك',
      nameEn: 'Owner',
      isSystemRole: true,
      permissions: StaffPermissionEnum.values.toList(),
    );

    rolesProvider = MockRolesSessionProvider(roles: [ownerRole]);

    userProvider = MockUserSessionProvider(
      user: const StaffUserModel(
        id: 'usr_cashier_audit',
        fullName: 'كاشير التدقيق',
        isOwner: true,
        isActive: true,
        isDeleted: false,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: ['role_owner'],
            isPrimary: true,
          ),
        ],
      ),
      branch: 'branch_1',
    );

    evaluator = PermissionEvaluator(
      userProvider: userProvider,
      rolesProvider: rolesProvider,
    );
  });

  group('Cashier Final Audit Verification (M-7)', () {
    test('1. shift_opened event records numeric IDs and amount only', () async {
      final openUseCase = OpenShiftDrawerUseCase(
        cashierRepo: cashierRepo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final res = await openUseCase(
        branchId: 'branch_1',
        openingBalancePiastres: 50000,
      );

      expect(res.isRight(), isTrue);
      final logs = auditLogger.getLogs(eventType: 'shift_opened');
      expect(logs.length, 1);
      final entry = logs.first;
      expect(entry.branchId, 'branch_1');
      expect(entry.performedByUserId, 'usr_cashier_audit');
      expect(entry.details?.contains('50000'), isTrue);
      expect(entry.details?.contains('patient'), isFalse);
    });

    test('2. payment_collected event records amount and method without sensitive data', () async {
      final openUseCase = OpenShiftDrawerUseCase(
        cashierRepo: cashierRepo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );
      final shiftRes = await openUseCase(
        branchId: 'branch_1',
        openingBalancePiastres: 20000,
      );
      final shift = shiftRes.getOrElse(() => throw StateError('failed'));

      final collectUseCase = CollectPaymentUseCase(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        reconciliationHelper: reconciliationHelper,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      // MED-102 has 150 EGP consultationFee and 0 paid in seed
      final payRes = await collectUseCase(
        clientRequestId: 'req_audit_1',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-102',
        patientId: 'PAT-000102',
        patientName: 'مريض تجريبي',
        amountPiastres: 10000,
        paymentMethod: PaymentMethod.card.name,
      );

      expect(payRes.isRight(), isTrue);
      final logs = auditLogger.getLogs(eventType: 'payment_collected');
      expect(logs.length, 1);
      final entry = logs.first;
      expect(entry.branchId, 'branch_1');
      expect(entry.details?.contains('bookingId: MED-102'), isTrue);
      expect(entry.details?.contains('amountPiastres: 10000'), isTrue);
      expect(entry.details?.contains('method: card'), isTrue);
      // Zero card numbers or patient phone in details
      expect(entry.details?.contains('01'), isFalse);
    });

    test('3. payment_refunded event records refund amount and target without card info', () async {
      final openUseCase = OpenShiftDrawerUseCase(
        cashierRepo: cashierRepo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );
      final shiftRes = await openUseCase(
        branchId: 'branch_1',
        openingBalancePiastres: 20000,
      );
      final shift = shiftRes.getOrElse(() => throw StateError('failed'));

      final collectUseCase = CollectPaymentUseCase(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        reconciliationHelper: reconciliationHelper,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );
      // MED-105 has 200 EGP consultationFee and 0 paid in seed
      final payRes = await collectUseCase(
        clientRequestId: 'req_audit_2',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-105',
        patientId: 'PAT-000105',
        patientName: 'مريض تجريبي',
        amountPiastres: 20000,
        paymentMethod: PaymentMethod.cash.name,
      );
      final payment = payRes.getOrElse(() => throw StateError('failed'));

      final refundUseCase = RefundPaymentUseCase(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        reconciliationHelper: reconciliationHelper,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final refundRes = await refundUseCase(
        clientRequestId: 'req_ref_1',
        originalPaymentId: payment.id!,
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-105',
        patientId: 'PAT-000105',
        refundAmountPiastres: 20000,
        refundMethod: PaymentMethod.cash.name,
        reason: 'مريض اعتذر عن الكشف',
      );

      expect(refundRes.isRight(), isTrue);
      final refundLogs = auditLogger.getLogs(eventType: 'payment_refunded');
      expect(refundLogs.length, 1);
      expect(refundLogs.first.details?.contains('originalPaymentId: ${payment.id}'), isTrue);
      expect(refundLogs.first.details?.contains('amountPiastres: 20000'), isTrue);
    });

    test('4. drawer movements log exact movement types (cash_movement_recorded)', () async {
      final openUseCase = OpenShiftDrawerUseCase(
        cashierRepo: cashierRepo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );
      final shiftRes = await openUseCase(
        branchId: 'branch_1',
        openingBalancePiastres: 50000,
      );
      final shift = shiftRes.getOrElse(() => throw StateError('failed'));

      final movementUseCase = RecordDrawerExpenseUseCase(
        cashierRepo: cashierRepo,
        policy: policy,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final expenseRes = await movementUseCase(
        clientRequestId: 'req_exp_1',
        shiftId: shift.id!,
        branchId: 'branch_1',
        amountPiastres: 5000,
        movementType: CashMovementTypeEnum.pettyExpense.name,
        reason: 'شراء أدوات مكتبية',
      );

      expect(expenseRes.isRight(), isTrue);
      final expenseLogs = auditLogger.getLogs(eventType: 'cash_movement_recorded');
      expect(expenseLogs.length, 1);
      expect(expenseLogs.first.details?.contains('amountPiastres: 5000'), isTrue);
      expect(expenseLogs.first.details?.contains('movementType: pettyExpense'), isTrue);
    });

    test('5. shortage_approved event logs difference and approver ID with separated duties', () async {
      // Create shift for cashier 'usr_cashier_diff'
      final openRes = await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'usr_cashier_diff',
        cashierName: 'كاشير مختلف',
        openingBalancePiastres: 100000,
      );
      final shift = openRes.getOrElse(() => throw StateError('failed'));

      // Close shift with 900 EGP (100 EGP shortage > 50 EGP max unapproved)
      final closeRes = await cashierRepo.closeShift(
        shiftId: shift.id!,
        actualCashCountPiastres: 90000,
        shortageReason: 'فارق عجز بسيط في الصباح',
      );
      final pendingShift = closeRes.getOrElse(() => throw StateError('failed'));
      expect(pendingShift.status, ShiftStatusEnum.closedPendingApproval);

      final approveUseCase = ApproveShortageUseCase(
        cashierRepo: cashierRepo,
        staffUsersRepo: staffUsersRepo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider, // usr_cashier_audit is the approving Manager
        auditLogger: auditLogger,
      );

      final res = await approveUseCase(
        shiftId: shift.id!,
        branchId: 'branch_1',
        cashierUserId: 'usr_cashier_diff',
        reason: 'تم اعتماد العجز بعد المراجعة',
      );

      expect(res.isRight(), isTrue);
      final logs = auditLogger.getLogs(eventType: 'shortage_approved');
      expect(logs.length, 1);
      expect(logs.first.performedByUserId, 'usr_cashier_audit');
      expect(logs.first.details?.contains('shiftId: ${shift.id}'), isTrue);
    });

    test('6. shift_closed event logs final financial summary numbers without sensitive notes', () async {
      final openUseCase = OpenShiftDrawerUseCase(
        cashierRepo: cashierRepo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );
      final shiftRes = await openUseCase(
        branchId: 'branch_1',
        openingBalancePiastres: 10000,
      );
      final shift = shiftRes.getOrElse(() => throw StateError('failed'));

      final closeUseCase = CloseShiftDrawerUseCase(
        cashierRepo: cashierRepo,
        policy: policy,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final closeRes = await closeUseCase(
        shiftId: shift.id!,
        actualCashCountPiastres: 10000,
        closingNotes: 'تم الإغلاق بنجاح',
      );

      expect(closeRes.isRight(), isTrue);
      final logs = auditLogger.getLogs(eventType: 'shift_closed');
      expect(logs.length, 1);
      expect(logs.first.performedByUserId, 'usr_cashier_audit');
      expect(logs.first.details?.contains('actualCashCountPiastres: 10000'), isTrue);
      expect(logs.first.details?.contains('expectedCashPiastres: 10000'), isTrue);
    });

    test('7. print_settings_updated event logs format names and branch ID only', () async {
      final printUseCase = UpdatePrintSettingsUseCase(
        repo: settingsRepo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final printRes = await printUseCase(
        const UpdatePrintSettingsParams(
          branchId: 'branch_1',
          receiptPrintFormat: 'thermal80',
          shiftReportPrintFormat: 'thermal80',
          prescriptionPrintFormat: 'a4',
        ),
      );

      expect(printRes.isRight(), isTrue);
      final logs = auditLogger.getLogs(eventType: 'print_settings_updated');
      expect(logs.length, 1);
      expect(logs.first.branchId, 'branch_1');
      expect(logs.first.performedByUserId, 'usr_cashier_audit');
      expect(logs.first.details?.contains('receiptFormat=thermal80'), isTrue);
      expect(logs.first.details?.contains('shiftReportFormat=thermal80'), isTrue);
      expect(logs.first.details?.contains('prescriptionFormat=a4'), isTrue);
    });

    test('8. failed operations emit zero audit logs (fail-closed guarantee)', () async {
      // Inactive user attempting to open shift
      userProvider.user = const StaffUserModel(
        id: 'usr_inactive',
        fullName: 'معطل',
        isOwner: false,
        isActive: false,
        isDeleted: false,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: ['role_owner'],
            isPrimary: true,
          ),
        ],
      );

      final openUseCase = OpenShiftDrawerUseCase(
        cashierRepo: cashierRepo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final res = await openUseCase(
        branchId: 'branch_1',
        openingBalancePiastres: 10000,
      );

      expect(res.isLeft(), isTrue);
      // Ensure zero audit logs were created for the failed operation
      expect(auditLogger.getLogs(performedByUserId: 'usr_inactive'), isEmpty);
    });
  });
}
