import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import 'package:eyadty/features/cashier/data/models/enums/cash_movement_type_enum.dart';
import 'package:eyadty/features/cashier/data/models/enums/shift_status_enum.dart';
import 'package:eyadty/features/cashier/data/repo/cashier_repo_impl.dart';
import 'package:eyadty/features/cashier/domain/contracts/cashier_policy.dart';
import 'package:eyadty/features/cashier/domain/helpers/cashier_shift_calculator.dart';
import 'package:eyadty/features/cashier/domain/helpers/payment_reconciliation_helper.dart';
import 'package:eyadty/features/cashier/domain/use_cases/approve_shortage_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/close_shift_drawer_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/collect_payment_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/force_close_shift_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/get_active_shift_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/open_shift_drawer_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/record_drawer_expense_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/refund_payment_use_case.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_cubit.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo.dart';

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

class FakeStaffUsersRepo implements StaffUsersRepo {
  List<StaffUserModel> users;
  FakeStaffUsersRepo({required this.users});

  @override
  Future<Either<Failures, List<StaffUserModel>>> getStaffUsers({
    String? branchId,
    String? roleId,
    bool? isActive,
    String? searchQuery,
  }) async {
    return Right(users);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBookingsRepo implements BookingsRepo {
  final Map<String, BookingModel> bookings = {};

  void addBooking(BookingModel b) {
    bookings[b.id!] = b;
  }

  @override
  Future<Either<Failures, BookingModel>> getBookingById(String id) async {
    final b = bookings[id];
    if (b == null) return const Left(ServerFailure(errMessage: 'booking_not_found'));
    return Right(b);
  }

  @override
  Future<Either<Failures, BookingModel>> updateBooking(
    BookingModel booking, {
    DateTime? customNow,
  }) async {
    bookings[booking.id!] = booking;
    return Right(booking);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late CashierRepoImpl cashierRepo;
  late FakeBookingsRepo bookingsRepo;
  late FakeStaffUsersRepo staffUsersRepo;
  late InMemoryAuditLogger auditLogger;
  late FakeUserSessionProvider userProvider;
  late FakeRolesSessionProvider rolesProvider;
  late PermissionEvaluator permissionEvaluator;

  late GetActiveShiftUseCase getActiveShiftUseCase;
  late OpenShiftDrawerUseCase openShiftDrawerUseCase;
  late CloseShiftDrawerUseCase closeShiftDrawerUseCase;
  late CollectPaymentUseCase collectPaymentUseCase;
  late RefundPaymentUseCase refundPaymentUseCase;
  late RecordDrawerExpenseUseCase recordDrawerExpenseUseCase;
  late ApproveShortageUseCase approveShortageUseCase;
  late ForceCloseShiftUseCase forceCloseShiftUseCase;

  late CashierCubit cubit;

  final cashierUser = StaffUserModel(
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
        roleIds: [RoleIds.branchManager],
      ),
    ],
  );

  setUp(() {
    cashierRepo = CashierRepoImpl(seedInitialData: false);
    bookingsRepo = FakeBookingsRepo();
    staffUsersRepo = FakeStaffUsersRepo(users: [cashierUser, managerUser]);
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
    userProvider = FakeUserSessionProvider(user: cashierUser, branch: 'branch_1');

    final systemRoles = RoleDefinitionModel.defaultSystemRoles();
    final updatedRoles = systemRoles.map((r) {
      if (r.id == RoleIds.reception) {
        return r.copyWith(permissions: [
          ...?r.permissions,
          StaffPermissionEnum.accessCashier,
          StaffPermissionEnum.collectPayment,
          StaffPermissionEnum.viewCashierShift,
          StaffPermissionEnum.manageDrawerMovements,
          StaffPermissionEnum.refundPayment,
        ]);
      }
      if (r.id == RoleIds.branchManager) {
        return r.copyWith(permissions: [
          ...?r.permissions,
          StaffPermissionEnum.accessCashier,
          StaffPermissionEnum.manageCashierShifts,
          StaffPermissionEnum.collectPayment,
          StaffPermissionEnum.viewCashierShift,
          StaffPermissionEnum.manageDrawerMovements,
          StaffPermissionEnum.refundPayment,
        ]);
      }
      return r;
    }).toList();

    rolesProvider = FakeRolesSessionProvider(roles: updatedRoles);
    permissionEvaluator = PermissionEvaluator(
      userProvider: userProvider,
      rolesProvider: rolesProvider,
    );

    getActiveShiftUseCase = GetActiveShiftUseCase(
      cashierRepo: cashierRepo,
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userProvider,
    );

    openShiftDrawerUseCase = OpenShiftDrawerUseCase(
      cashierRepo: cashierRepo,
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userProvider,
      auditLogger: auditLogger,
    );

    closeShiftDrawerUseCase = CloseShiftDrawerUseCase(
      cashierRepo: cashierRepo,
      policy: const CashierPolicy(),
      calculator: const CashierShiftCalculator(),
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userProvider,
      auditLogger: auditLogger,
    );

    collectPaymentUseCase = CollectPaymentUseCase(
      cashierRepo: cashierRepo,
      bookingsRepo: bookingsRepo,
      reconciliationHelper: const PaymentReconciliationHelper(),
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userProvider,
      auditLogger: auditLogger,
    );

    refundPaymentUseCase = RefundPaymentUseCase(
      cashierRepo: cashierRepo,
      bookingsRepo: bookingsRepo,
      reconciliationHelper: const PaymentReconciliationHelper(),
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userProvider,
      auditLogger: auditLogger,
    );

    recordDrawerExpenseUseCase = RecordDrawerExpenseUseCase(
      cashierRepo: cashierRepo,
      policy: const CashierPolicy(),
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userProvider,
      auditLogger: auditLogger,
    );

    approveShortageUseCase = ApproveShortageUseCase(
      cashierRepo: cashierRepo,
      staffUsersRepo: staffUsersRepo,
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userProvider,
      auditLogger: auditLogger,
    );

    forceCloseShiftUseCase = ForceCloseShiftUseCase(
      cashierRepo: cashierRepo,
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userProvider,
      auditLogger: auditLogger,
    );

    cubit = CashierCubit(
      cashierRepo: cashierRepo,
      getActiveShiftUseCase: getActiveShiftUseCase,
      openShiftDrawerUseCase: openShiftDrawerUseCase,
      closeShiftDrawerUseCase: closeShiftDrawerUseCase,
      collectPaymentUseCase: collectPaymentUseCase,
      refundPaymentUseCase: refundPaymentUseCase,
      recordDrawerExpenseUseCase: recordDrawerExpenseUseCase,
      approveShortageUseCase: approveShortageUseCase,
      forceCloseShiftUseCase: forceCloseShiftUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('CashierCubit - State Management & Shift Lifecycle', () {
    test('1. Initial state has correct defaults', () {
      expect(cubit.state.status, RequestStatusEnum.initial);
      expect(cubit.state.activeShift, isNull);
      expect(cubit.state.hasActiveShift, isFalse);
      expect(cubit.state.shiftHistory, isEmpty);
      expect(cubit.state.shiftPayments, isEmpty);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.expectedCashPiastres, equals(0));
    });

    test('2. init loads active shift and shift history for current user/branch', () async {
      await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 50000,
      );

      await cubit.init(branchId: 'branch_1', userId: 'USER-REC');

      expect(cubit.state.status, RequestStatusEnum.success);
      expect(cubit.state.hasActiveShift, isTrue);
      expect(cubit.state.activeShift!.branchId, equals('branch_1'));
      expect(cubit.state.activeShift!.cashierUserId, equals('USER-REC'));
      expect(cubit.state.shiftHistory.length, equals(1));
    });

    test('3. openShift emits loading, calls usecase, and updates activeShift on success', () async {
      cubit.emit(cubit.state.copyWith(
        currentBranchId: 'branch_1',
        currentUserId: 'USER-REC',
      ));

      final success = await cubit.openShift(
        branchId: 'branch_1',
        openingBalancePiastres: 50000,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
      );

      expect(success, isTrue);
      expect(cubit.state.hasActiveShift, isTrue);
      expect(cubit.state.activeShift!.openingBalancePiastres, equals(50000));
      expect(cubit.state.expectedCashPiastres, equals(50000));
      expect(cubit.state.successMessage, isNotNull);
      expect(cubit.state.isSubmitting, isFalse);
    });

    test('4. openShift emits error message on failure (e.g. negative opening balance)', () async {
      cubit.emit(cubit.state.copyWith(
        currentBranchId: 'branch_1',
        currentUserId: 'USER-REC',
      ));

      final success = await cubit.openShift(
        branchId: 'branch_1',
        openingBalancePiastres: -100,
      );

      expect(success, isFalse);
      expect(cubit.state.hasActiveShift, isFalse);
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.isSubmitting, isFalse);
    });

    test('5. closeShift computes expected vs counted, emits closed shift on success and clears activeShift', () async {
      cubit.emit(cubit.state.copyWith(
        currentBranchId: 'branch_1',
        currentUserId: 'USER-REC',
      ));
      await cubit.openShift(
        branchId: 'branch_1',
        openingBalancePiastres: 50000,
      );
      final shiftId = cubit.state.activeShift!.id!;

      final closed = await cubit.closeShift(
        shiftId: shiftId,
        actualCashCountPiastres: 50000,
        closingNotes: 'تمام ومطابق',
      );

      expect(closed, isTrue);
      expect(cubit.state.hasActiveShift, isFalse);
      expect(cubit.state.lastClosedShift, isNotNull);
      expect(cubit.state.lastClosedShift!.id, equals(shiftId));
      expect(cubit.state.lastClosedShift!.status, equals(ShiftStatusEnum.closed));
      expect(cubit.state.successMessage, isNotNull);
    });

    test('6. closeShift marks shift closedPendingApproval when shortage occurs, and fails on negative cash', () async {
      cubit.emit(cubit.state.copyWith(
        currentBranchId: 'branch_1',
        currentUserId: 'USER-REC',
      ));
      await cubit.openShift(
        branchId: 'branch_1',
        openingBalancePiastres: 50000,
      );
      final shiftId = cubit.state.activeShift!.id!;

      // 1. Validation failure: negative cash count
      final negativeOk = await cubit.closeShift(
        shiftId: shiftId,
        actualCashCountPiastres: -500,
      );
      expect(negativeOk, isFalse);
      expect(cubit.state.hasActiveShift, isTrue);
      expect(cubit.state.errorMessage, isNotNull);

      // 2. Counted 40,000 when expected 50,000 (100 EGP shortage) -> marks closedPendingApproval
      final closed = await cubit.closeShift(
        shiftId: shiftId,
        actualCashCountPiastres: 40000,
        shortageReason: 'عجز غير معتمد',
      );

      expect(closed, isTrue);
      expect(cubit.state.hasActiveShift, isFalse);
      expect(cubit.state.lastClosedShift, isNotNull);
      expect(cubit.state.lastClosedShift!.status, equals(ShiftStatusEnum.closedPendingApproval));
      expect(cubit.state.successMessage, equals('cashier_shift_closed_pending_approval'));
    });

    test('7. collectPayment calls usecase, updates state with lastPayment and refreshes activeShift', () async {
      cubit.emit(cubit.state.copyWith(
        currentBranchId: 'branch_1',
        currentUserId: 'USER-REC',
      ));
      await cubit.openShift(
        branchId: 'branch_1',
        openingBalancePiastres: 50000,
      );
      final shiftId = cubit.state.activeShift!.id!;

      const booking = BookingModel(
        id: 'MED-CUBIT-01',
        totalPrice: 200,
        paidAmount: 0,
        paymentStatus: PaymentStatusEnum.unpaid,
        patientName: 'أحمد محمود',
      );
      bookingsRepo.addBooking(booking);

      final ok = await cubit.collectPayment(
        clientRequestId: 'req-collect-1',
        shiftId: shiftId,
        branchId: 'branch_1',
        bookingId: 'MED-CUBIT-01',
        patientId: 'PAT-001',
        patientName: 'أحمد محمود',
        amountPiastres: 20000,
        paymentMethod: 'cash',
        notes: 'دفع كاش كامل',
      );

      expect(ok, isTrue);
      expect(cubit.state.lastPayment, isNotNull);
      expect(cubit.state.lastPayment!.amountPiastres, equals(20000));
      expect(cubit.state.activeShift!.totalCashCollectedPiastres, equals(20000));
      expect(cubit.state.expectedCashPiastres, equals(70000)); // 500 + 200 EGP
    });

    test('8. refundPayment calls usecase, updates state with lastRefund', () async {
      cubit.emit(cubit.state.copyWith(
        currentBranchId: 'branch_1',
        currentUserId: 'USER-REC',
      ));
      await cubit.openShift(
        branchId: 'branch_1',
        openingBalancePiastres: 100000,
      );
      final shiftId = cubit.state.activeShift!.id!;

      const booking = BookingModel(
        id: 'MED-CUBIT-02',
        totalPrice: 300,
        paidAmount: 0,
        paymentStatus: PaymentStatusEnum.unpaid,
      );
      bookingsRepo.addBooking(booking);

      await cubit.collectPayment(
        clientRequestId: 'req-collect-2',
        shiftId: shiftId,
        branchId: 'branch_1',
        bookingId: 'MED-CUBIT-02',
        patientId: 'PAT-002',
        patientName: 'سارة علي',
        amountPiastres: 30000,
        paymentMethod: 'cash',
      );

      final originalPayment = cubit.state.lastPayment!;

      final refunded = await cubit.refundPayment(
        clientRequestId: 'req-refund-1',
        originalPaymentId: originalPayment.id!,
        shiftId: shiftId,
        branchId: 'branch_1',
        bookingId: 'MED-CUBIT-02',
        patientId: 'PAT-002',
        refundAmountPiastres: 10000,
        refundMethod: 'cash',
        reason: 'إلغاء إجراء فرعي',
      );

      expect(refunded, isTrue);
      expect(cubit.state.lastRefund, isNotNull);
      expect(cubit.state.lastRefund!.refundAmountPiastres, equals(10000));
      expect(cubit.state.activeShift!.totalRefundsPiastres, equals(10000));
      expect(cubit.state.expectedCashPiastres, equals(120000)); // 1000 + 300 - 100 EGP = 1200 EGP
    });

    test('9. recordExpense updates expected cash and drawer expenses', () async {
      cubit.emit(cubit.state.copyWith(
        currentBranchId: 'branch_1',
        currentUserId: 'USER-REC',
      ));
      await cubit.openShift(
        branchId: 'branch_1',
        openingBalancePiastres: 50000,
      );
      final shiftId = cubit.state.activeShift!.id!;

      final expOk = await cubit.recordDrawerExpense(
        clientRequestId: 'req-exp-1',
        shiftId: shiftId,
        branchId: 'branch_1',
        movementType: CashMovementTypeEnum.pettyExpense.name,
        amountPiastres: 5000,
        reason: 'شراء أدوات مكتبية',
      );

      expect(expOk, isTrue);
      expect(cubit.state.activeShift!.totalExpensesPiastres, equals(5000));
      expect(cubit.state.expectedCashPiastres, equals(45000)); // 500 - 50 EGP = 450 EGP
    });

    test('10. onBranchOrUserChanged clears active shift and payments to prevent cross-branch leakage', () async {
      cubit.emit(cubit.state.copyWith(
        currentBranchId: 'branch_1',
        currentUserId: 'USER-REC',
      ));
      await cubit.openShift(
        branchId: 'branch_1',
        openingBalancePiastres: 50000,
      );
      expect(cubit.state.hasActiveShift, isTrue);

      await cubit.onBranchOrUserChanged(
        newBranchId: 'branch_2',
        newUserId: 'USER-REC',
      );

      expect(cubit.state.currentBranchId, equals('branch_2'));
      expect(cubit.state.hasActiveShift, isFalse);
      expect(cubit.state.shiftPayments, isEmpty);
      expect(cubit.state.selectedShift, isNull);
    });
  });
}
