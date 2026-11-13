import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/cashier/data/models/enums/cash_movement_type_enum.dart';
import 'package:eyadty/features/cashier/data/models/enums/shift_status_enum.dart';
import 'package:eyadty/features/cashier/data/repo/cashier_mock_repo_impl.dart';
import 'package:eyadty/features/cashier/domain/contracts/cashier_policy.dart';
import 'package:eyadty/features/cashier/domain/use_cases/approve_shortage_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/close_shift_drawer_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/force_close_shift_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/get_active_shift_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/open_shift_drawer_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/record_drawer_expense_use_case.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo.dart';

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

class MockStaffUsersRepo implements StaffUsersRepo {
  List<StaffUserModel> users;
  MockStaffUsersRepo({required this.users});

  @override
  Future<Either<Failure, List<StaffUserModel>>> getStaffUsers({
    String? branchId,
    String? roleId,
    bool? isActive,
    String? searchQuery,
  }) async {
    var list = users;
    if (branchId != null) {
      list = list.where((u) {
        if (u.isOwner == true) return true;
        return u.branchAssignments?.any((b) => b.branchId == branchId) ?? false;
      }).toList();
    }
    if (isActive != null) {
      list = list.where((u) => u.isActive == isActive).toList();
    }
    return Right(list);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late CashierMockRepoImpl repo;
  late InMemoryAuditLogger auditLogger;
  late MockUserSessionProvider userProvider;
  late MockRolesSessionProvider rolesProvider;
  late PermissionEvaluator evaluator;
  const policy = CashierPolicy();

  final receptionistUser = StaffUserModel(
    id: 'USER-REC',
    fullName: 'منى إبراهيم',
    isActive: true,
    isOwner: false,
    branchAssignments: const [
      BranchAssignmentModel(
        branchId: 'branch_1',
        isPrimary: true,
        roleIds: [RoleIds.reception],
      ),
    ],
  );

  final managerUser = StaffUserModel(
    id: 'USER-MGR',
    fullName: 'م. أحمد مهران',
    isActive: true,
    isOwner: false,
    branchAssignments: const [
      BranchAssignmentModel(
        branchId: 'branch_1',
        isPrimary: true,
        roleIds: ['role_branch_manager'],
      ),
    ],
  );

  final ownerUser = const StaffUserModel(
    id: 'USER-OWNER',
    fullName: 'د. طارق المنشاوي',
    isActive: true,
    isOwner: true,
  );

  setUp(() {
    repo = CashierMockRepoImpl(seedInitialData: false);
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
    final systemRoles = RoleDefinitionModel.defaultSystemRoles();
    final managerDef = systemRoles.firstWhere((r) => r.id == RoleIds.branchManager);
    final updatedManager = managerDef.copyWith(
      permissions: [
        ...?managerDef.permissions,
        StaffPermissionEnum.manageCashierShifts,
        StaffPermissionEnum.manageDrawerMovements,
      ],
    );
    final testRoles = systemRoles
        .map((r) => r.id == RoleIds.branchManager ? updatedManager : r)
        .toList();

    rolesProvider = MockRolesSessionProvider(roles: testRoles);
    userProvider = MockUserSessionProvider(user: receptionistUser);
    evaluator = PermissionEvaluator(
      userProvider: userProvider,
      rolesProvider: rolesProvider,
    );
  });

  group('Cashier Shift Open & Close Validation', () {
    test('1. Prevents opening shift with negative opening balance', () async {
      final useCase = OpenShiftDrawerUseCase(
        cashierRepo: repo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final result = await useCase(
        branchId: 'branch_1',
        openingBalancePiastres: -500,
      );

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f.errMessage, 'cashier_validation_opening_balance_negative'),
        (_) => fail('Should have failed'),
      );
    });

    test('2. Opens shift successfully with valid opening balance and emits shift_opened audit', () async {
      final useCase = OpenShiftDrawerUseCase(
        cashierRepo: repo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final result = await useCase(
        branchId: 'branch_1',
        openingBalancePiastres: 50000,
      );

      expect(result.isRight(), true);
      final shift = result.getOrElse(() => throw StateError(''));
      expect(shift.status, ShiftStatusEnum.open);
      expect(shift.openingBalancePiastres, 50000);

      // Verify audit
      final logs = auditLogger.getLogs(eventType: 'shift_opened');
      expect(logs.length, 1);
      expect(logs.first.performedByUserId, 'USER-REC');
      expect(logs.first.details?.contains('openingBalancePiastres: 50000'), true);
    });

    test('3. Prevents opening multiple active shifts for same cashier and branch', () async {
      final useCase = OpenShiftDrawerUseCase(
        cashierRepo: repo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      await useCase(branchId: 'branch_1', openingBalancePiastres: 50000);
      final secondTry = await useCase(branchId: 'branch_1', openingBalancePiastres: 30000);

      expect(secondTry.isLeft(), true);
      secondTry.fold(
        (f) => expect(f.errMessage, 'cashier_validation_shift_already_open'),
        (_) => fail('Should not allow duplicate open shift'),
      );
    });

    test('4. Closes shift with zero difference and updates status to closed with audit', () async {
      final openUseCase = OpenShiftDrawerUseCase(
        cashierRepo: repo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );
      final shift = (await openUseCase(branchId: 'branch_1', openingBalancePiastres: 50000))
          .getOrElse(() => throw StateError(''));

      final closeUseCase = CloseShiftDrawerUseCase(
        cashierRepo: repo,
        policy: policy,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final closeRes = await closeUseCase(
        shiftId: shift.id!,
        actualCashCountPiastres: 50000,
      );

      expect(closeRes.isRight(), true);
      final closedShift = closeRes.getOrElse(() => throw StateError(''));
      expect(closedShift.status, ShiftStatusEnum.closed);
      expect(closedShift.cashDifferencePiastres, 0);

      final logs = auditLogger.getLogs(eventType: 'shift_closed');
      expect(logs.length, 1);
      expect(logs.first.details?.contains('differencePiastres: 0'), true);
    });

    test('5. Closes shift with large shortage (> 50 EGP) sets status to closedPendingApproval', () async {
      final openUseCase = OpenShiftDrawerUseCase(
        cashierRepo: repo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );
      final shift = (await openUseCase(branchId: 'branch_1', openingBalancePiastres: 100000))
          .getOrElse(() => throw StateError(''));

      final closeUseCase = CloseShiftDrawerUseCase(
        cashierRepo: repo,
        policy: policy,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      // Actual cash is 900 EGP (100 EGP shortage > 50 EGP max unapproved)
      final closeRes = await closeUseCase(
        shiftId: shift.id!,
        actualCashCountPiastres: 90000,
        shortageReason: 'فارق صرف نقدية',
      );

      expect(closeRes.isRight(), true);
      final pendingShift = closeRes.getOrElse(() => throw StateError(''));
      expect(pendingShift.status, ShiftStatusEnum.closedPendingApproval);
      expect(pendingShift.cashDifferencePiastres, -10000);
    });
  });

  group('Cashier Idempotency and Conflicts', () {
    test('6. Same clientRequestId with same parameters returns existing transaction without duplicate', () async {
      final openRes = await repo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 50000,
      );
      final shift = openRes.getOrElse(() => throw StateError(''));

      final p1 = await repo.recordPayment(
        clientRequestId: 'REQ-12345',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-101',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 30000,
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
      );
      expect(p1.isRight(), true);

      // Repeat with exact same params
      final p2 = await repo.recordPayment(
        clientRequestId: 'REQ-12345',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-101',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 30000,
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
      );
      expect(p2.isRight(), true);
      expect(p2.getOrElse(() => throw StateError('')).id, p1.getOrElse(() => throw StateError('')).id);

      // Verify payments list only has 1 transaction
      final paymentsList = (await repo.getPaymentsForShift(shiftId: shift.id!))
          .getOrElse(() => []);
      expect(paymentsList.length, 1);
    });

    test('7. Same clientRequestId with different parameters rejects with idempotency_conflict', () async {
      final openRes = await repo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 50000,
      );
      final shift = openRes.getOrElse(() => throw StateError(''));

      await repo.recordPayment(
        clientRequestId: 'REQ-CONFLICT-1',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-101',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 30000,
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
      );

      // Repeat with different amount (400 EGP instead of 300)
      final conflictRes = await repo.recordPayment(
        clientRequestId: 'REQ-CONFLICT-1',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-101',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 40000,
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
      );

      expect(conflictRes.isLeft(), true);
      conflictRes.fold(
        (f) => expect(f.errMessage, 'idempotency_conflict'),
        (_) => fail('Should reject conflicting request'),
      );
    });
  });

  group('Approve Shortage Governance & Single Owner Exception', () {
    test('8. Rejects approval if approver is same as shift cashier', () async {
      userProvider.user = managerUser;
      final openRes = await repo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-MGR',
        cashierName: 'م. أحمد مهران',
        openingBalancePiastres: 100000,
      );
      final shift = openRes.getOrElse(() => throw StateError(''));

      final approveUseCase = ApproveShortageUseCase(
        cashierRepo: repo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final result = await approveUseCase(
        shiftId: shift.id!,
        branchId: 'branch_1',
        cashierUserId: 'USER-MGR',
        reason: 'اعتماد العجز',
        approvedByUserId: 'USER-MGR',
      );

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f.errMessage, 'cashier_approver_same_as_cashier'),
        (_) => fail('Should prevent self-approval for manager'),
      );
    });

    test('9. Allows owner self-approval when no other branch manager exists in branch', () async {
      userProvider.user = ownerUser;
      final staffRepo = MockStaffUsersRepo(
        users: [ownerUser, receptionistUser], // No other branch manager
      );

      final openRes = await repo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-OWNER',
        cashierName: 'د. طارق المنشاوي',
        openingBalancePiastres: 100000,
      );
      final shift = openRes.getOrElse(() => throw StateError(''));

      final approveUseCase = ApproveShortageUseCase(
        cashierRepo: repo,
        staffUsersRepo: staffRepo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final result = await approveUseCase(
        shiftId: shift.id!,
        branchId: 'branch_1',
        cashierUserId: 'USER-OWNER',
        reason: 'اعتماد مالك فردي',
        approvedByUserId: 'USER-OWNER',
      );

      expect(result.isRight(), true);
      final approvedShift = result.getOrElse(() => throw StateError(''));
      expect(approvedShift.status, ShiftStatusEnum.closed);
      expect(approvedShift.isOwnerSelfApproved, true);

      // Emits owner_self_approved audit with single operator reason
      final logs = auditLogger.getLogs(eventType: 'owner_self_approved');
      expect(logs.length, 1);
      expect(logs.first.details?.contains('reason: owner_self_approved_single_operator'), true);
    });

    test('10. Rejects owner self-approval when another qualified branch manager exists in branch', () async {
      userProvider.user = ownerUser;
      final staffRepo = MockStaffUsersRepo(
        users: [ownerUser, managerUser, receptionistUser], // Another branch manager exists!
      );

      final openRes = await repo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-OWNER',
        cashierName: 'د. طارق المنشاوي',
        openingBalancePiastres: 100000,
      );
      final shift = openRes.getOrElse(() => throw StateError(''));

      final approveUseCase = ApproveShortageUseCase(
        cashierRepo: repo,
        staffUsersRepo: staffRepo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final result = await approveUseCase(
        shiftId: shift.id!,
        branchId: 'branch_1',
        cashierUserId: 'USER-OWNER',
        reason: 'محاولة اعتماد ذاتي بوجود مدير',
        approvedByUserId: 'USER-OWNER',
      );

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f.errMessage, 'cashier_approver_same_as_cashier'),
        (_) => fail('Owner must not self-approve when manager exists'),
      );
    });

    test('11. Rejects shortage approval with empty reason', () async {
      userProvider.user = managerUser;
      final approveUseCase = ApproveShortageUseCase(
        cashierRepo: repo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final result = await approveUseCase(
        shiftId: 'SHIFT-1',
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        reason: '   ', // Empty
      );

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f.errMessage, 'cashier_validation_reason_required'),
        (_) => fail('Must require non-empty reason'),
      );
    });
  });

  group('Force Close Shift Governance', () {
    test('12. Force close shift requires non-empty reason', () async {
      userProvider.user = managerUser;
      final forceCloseUseCase = ForceCloseShiftUseCase(
        cashierRepo: repo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final result = await forceCloseUseCase(
        shiftId: 'SHIFT-1',
        branchId: 'branch_1',
        reason: '',
      );

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f.errMessage, 'cashier_validation_reason_required'),
        (_) => fail('Must require reason'),
      );
    });

    test('13. Force close shift requires manageCashierShifts permission (receptionist fails)', () async {
      userProvider.user = receptionistUser; // Receptionist does not have manageCashierShifts
      final forceCloseUseCase = ForceCloseShiftUseCase(
        cashierRepo: repo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final result = await forceCloseUseCase(
        shiftId: 'SHIFT-1',
        branchId: 'branch_1',
        reason: 'إغلاق وردية متأخرة',
      );

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f.errMessage, 'permission_denied'),
        (_) => fail('Must deny receptionist'),
      );
    });

    test('14. Force close shift successfully closes shift and emits shift_force_closed audit', () async {
      userProvider.user = receptionistUser;
      final shift = (await repo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 50000,
      )).getOrElse(() => throw StateError(''));

      // Switch to Manager
      userProvider.user = managerUser;
      final forceCloseUseCase = ForceCloseShiftUseCase(
        cashierRepo: repo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final result = await forceCloseUseCase(
        shiftId: shift.id!,
        branchId: 'branch_1',
        reason: 'تأخر الكاشير لأكثر من 16 ساعة',
      );

      expect(result.isRight(), true);
      final closed = result.getOrElse(() => throw StateError(''));
      expect(closed.status, ShiftStatusEnum.forceClosed);

      final logs = auditLogger.getLogs(eventType: 'shift_force_closed');
      expect(logs.length, 1);
      expect(logs.first.details?.contains('performedByUserId: USER-MGR'), true);
    });
  });

  group('Drawer Movement & Petty Expense Permissions', () {
    test('15. Allows petty expense <= 200 EGP for receptionist with collectPayment', () async {
      userProvider.user = receptionistUser;
      final shift = (await repo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 50000,
      )).getOrElse(() => throw StateError(''));

      final expenseUseCase = RecordDrawerExpenseUseCase(
        cashierRepo: repo,
        policy: policy,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final result = await expenseUseCase(
        clientRequestId: 'REQ-PETTY-1',
        shiftId: shift.id!,
        branchId: 'branch_1',
        movementType: CashMovementTypeEnum.pettyExpense.name,
        amountPiastres: 15000, // 150 EGP <= 200 EGP
        reason: 'شراء بوفيه واستقبال',
        recipientName: 'عامل الخدمات',
      );

      expect(result.isRight(), true);
      final logs = auditLogger.getLogs(eventType: 'cash_movement_recorded');
      expect(logs.length, 1);
      expect(logs.first.details?.contains('movementType: pettyExpense'), true);
    });

    test('16. Rejects petty expense > 200 EGP for receptionist without manageDrawerMovements', () async {
      userProvider.user = receptionistUser;
      final shift = (await repo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 50000,
      )).getOrElse(() => throw StateError(''));

      final expenseUseCase = RecordDrawerExpenseUseCase(
        cashierRepo: repo,
        policy: policy,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final result = await expenseUseCase(
        clientRequestId: 'REQ-PETTY-2',
        shiftId: shift.id!,
        branchId: 'branch_1',
        movementType: CashMovementTypeEnum.pettyExpense.name,
        amountPiastres: 25000, // 250 EGP > 200 EGP limit
        reason: 'شراء أدوات مكتبية كبيرة',
      );

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f.errMessage, 'permission_denied'),
        (_) => fail('Must require manageDrawerMovements for large expenses'),
      );
    });

    test('17. Allows large expense and capital injection for manager with manageDrawerMovements', () async {
      userProvider.user = managerUser;
      final shift = (await repo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-MGR',
        cashierName: 'م. أحمد مهران',
        openingBalancePiastres: 50000,
      )).getOrElse(() => throw StateError(''));

      final expenseUseCase = RecordDrawerExpenseUseCase(
        cashierRepo: repo,
        policy: policy,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final result = await expenseUseCase(
        clientRequestId: 'REQ-CAPITAL-1',
        shiftId: shift.id!,
        branchId: 'branch_1',
        movementType: CashMovementTypeEnum.capitalInjection.name,
        amountPiastres: 500000, // 5,000 EGP
        reason: 'تغذية الخزينة برأس مال إضافي',
      );

      expect(result.isRight(), true);
      final logs = auditLogger.getLogs(eventType: 'cash_movement_recorded');
      expect(logs.length, 1);
    });

    test('18. Get active shift respects branch isolation and returns correct shift', () async {
      userProvider.user = receptionistUser;
      // Open shift in branch_1
      await repo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 30000,
      );

      final useCase = GetActiveShiftUseCase(
        cashierRepo: repo,
        permissionEvaluator: evaluator,
        currentUserProvider: userProvider,
      );

      // Receptionist querying their assigned branch succeeds
      final shiftBranch1 = await useCase(branchId: 'branch_1');
      expect(shiftBranch1.isRight(), true);
      expect(shiftBranch1.getOrElse(() => null)?.branchId, 'branch_1');

      // Receptionist querying unassigned branch_2 is denied
      final deniedBranch2 = await useCase(branchId: 'branch_2');
      expect(deniedBranch2.isLeft(), true);
      deniedBranch2.fold(
        (f) => expect(f.errMessage, 'permission_denied'),
        (_) => fail('Should deny access to unassigned branch'),
      );

      // Owner (authorized for all branches) querying branch_2 returns null (no active shift in branch 2)
      userProvider.user = ownerUser;
      final shiftBranch2 = await useCase(
        branchId: 'branch_2',
        cashierUserId: 'USER-REC',
      );
      expect(shiftBranch2.isRight(), true);
      expect(shiftBranch2.getOrElse(() => null), isNull);
    });
  });
}
