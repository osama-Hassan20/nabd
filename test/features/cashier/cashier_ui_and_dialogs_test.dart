import 'package:toastification/toastification.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import 'package:eyadty/features/cashier/data/models/cashier_shift_model.dart';
import 'package:eyadty/features/cashier/data/models/cashier_summary_metrics_model.dart';
import 'package:eyadty/features/cashier/data/models/enums/shift_status_enum.dart';
import 'package:eyadty/features/cashier/data/models/payment_transaction_model.dart';
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
import 'package:eyadty/features/cashier/presentation/widgets/active_shift_bar.dart';
import 'package:eyadty/features/cashier/presentation/widgets/cashier_metrics_section.dart';
import 'package:eyadty/features/cashier/presentation/widgets/dialogs/close_shift_dialog.dart';
import 'package:eyadty/features/cashier/presentation/widgets/dialogs/collect_payment_dialog.dart';
import 'package:eyadty/features/cashier/presentation/widgets/dialogs/open_shift_dialog.dart';
import 'package:eyadty/features/cashier/presentation/widgets/dialogs/record_drawer_expense_dialog.dart';
import 'package:eyadty/features/cashier/presentation/widgets/dialogs/refund_payment_dialog.dart';
import 'package:eyadty/features/cashier/presentation/widgets/payments_history_table.dart';
import 'package:eyadty/features/cashier/presentation/widgets/shift_history_table.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo.dart';
import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';

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
  @override
  Future<Either<Failures, List<StaffUserModel>>> getStaffUsers({
    String? branchId,
    String? roleId,
    bool? isActive,
    String? searchQuery,
  }) async =>
      const Right([]);

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

Widget _buildTestApp({
  required Widget child,
  required SessionCubit sessionCubit,
  required CashierCubit cashierCubit,
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
        BlocProvider<CashierCubit>.value(value: cashierCubit),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  late CashierCubit cashierCubit;
  late SessionCubit sessionCubit;

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

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('ar', null);
  });

  setUp(() {
    cashierRepo = CashierRepoImpl(seedInitialData: false);
    bookingsRepo = FakeBookingsRepo();
    staffUsersRepo = FakeStaffUsersRepo();
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
    userProvider = FakeUserSessionProvider(user: cashierUser, branch: 'branch_1');

    final systemRoles = RoleDefinitionModel.defaultSystemRoles();
    final updatedRoles = systemRoles.map((r) {
      return r.copyWith(permissions: [
        ...?r.permissions,
        StaffPermissionEnum.accessCashier,
        StaffPermissionEnum.collectPayment,
        StaffPermissionEnum.viewCashierShift,
        StaffPermissionEnum.manageDrawerMovements,
        StaffPermissionEnum.refundPayment,
        StaffPermissionEnum.manageCashierShifts,
      ]);
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

    cashierCubit = CashierCubit(
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

    sessionCubit = SessionCubit(
      SessionState.initial().copyWith(
        currentUser: cashierUser,
        activeBranchId: 'branch_1',
      ),
    );
  });

  tearDown(() {
    toastification.dismissAll();
    cashierCubit.close();
    sessionCubit.close();
  });

  group('Cashier UI & Dialogs - M-4 Tests', () {
    testWidgets('1. ActiveShiftBar renders banner with open shift button when shift is null',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestApp(
          child: const ActiveShiftBar(activeShift: null),
          sessionCubit: sessionCubit,
          cashierCubit: cashierCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cashier_no_active_shift'.tr()), findsOneWidget);
      expect(find.text('cashier_open_shift_btn'.tr()), findsOneWidget);
    });

    testWidgets('2. ActiveShiftBar renders shift details, expected cash, and action buttons when shift is active',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final activeShift = CashierShiftModel(
        id: 'SHIFT-001',
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        status: ShiftStatusEnum.open,
        openingBalancePiastres: 50000,
        expectedCashPiastres: 75000,
        openedAt: DateTime(2026, 11, 14, 10, 0),
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: ActiveShiftBar(activeShift: activeShift),
          sessionCubit: sessionCubit,
          cashierCubit: cashierCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cashier_active_shift_title'.tr()), findsOneWidget);
      expect(find.text('منى إبراهيم'), findsOneWidget);
      expect(find.text('750.00 ج.م'), findsOneWidget);
      expect(find.text('cashier_record_movement_btn'.tr()), findsOneWidget);
      expect(find.text('cashier_close_shift_btn'.tr()), findsOneWidget);
    });

    testWidgets('3. CashierMetricsSection renders all 6 metric cards with correct formatted values',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const summary = CashierSummaryMetricsModel(
        expectedCashPiastres: 120000,
        cashCollectedPiastres: 80000,
        cardCollectedPiastres: 40000,
        bankTransferPiastres: 10000,
        totalExpensesPiastres: 5000,
        totalRefundsPiastres: 2000,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const CashierMetricsSection(summaryMetrics: summary),
          sessionCubit: sessionCubit,
          cashierCubit: cashierCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cashier_expected_cash'.tr()), findsOneWidget);
      expect(find.text('1200.00 ج.م'), findsOneWidget);
      expect(find.text('800.00 ج.م'), findsOneWidget);
      expect(find.text('400.00 ج.م'), findsOneWidget);
      expect(find.text('100.00 ج.م'), findsOneWidget);
      expect(find.text('50.00 ج.م'), findsOneWidget);
      expect(find.text('20.00 ج.م'), findsOneWidget);
    });

    testWidgets('4. PaymentsHistoryTable displays transactions with patient, receipt, and status',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final payments = [
        PaymentTransactionModel(
          id: 'PAY-101',
          bookingId: 'BK-001',
          patientName: 'أحمد محمود',
          amountPiastres: 25000,
          paymentMethod: PaymentMethod.cash,
          createdAt: DateTime(2026, 11, 14, 11, 30),
          isRefunded: false,
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: PaymentsHistoryTable(payments: payments),
          sessionCubit: sessionCubit,
          cashierCubit: cashierCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PAY-101'), findsOneWidget);
      expect(find.text('BK-001'), findsOneWidget);
      expect(find.text('أحمد محمود'), findsOneWidget);
      expect(find.text('250.00 ج.م'), findsOneWidget);
      expect(find.text('مسدد'), findsOneWidget);
      expect(find.text('cashier_refund_btn'.tr()), findsOneWidget);
    });

    testWidgets('5. ShiftHistoryTable displays past shifts with discrepancy indicators and badges',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final shifts = [
        CashierShiftModel(
          id: 'SHIFT-PAST-01',
          cashierName: 'منى إبراهيم',
          openingBalancePiastres: 50000,
          totalCashCollectedPiastres: 30000,
          expectedCashPiastres: 80000,
          cashDifferencePiastres: -5000,
          status: ShiftStatusEnum.closedPendingApproval,
          openedAt: DateTime(2026, 11, 13, 9, 0),
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          child: ShiftHistoryTable(shifts: shifts),
          sessionCubit: sessionCubit,
          cashierCubit: cashierCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SHIFT-PAST-01'), findsOneWidget);
      expect(find.text('-50.00 ج.م'), findsOneWidget);
      expect(find.text('cashier_status_pending_approval'.tr()), findsOneWidget);
      expect(find.text('اعتماد'), findsOneWidget);
    });

    testWidgets('6. OpenShiftDialog opens, accepts input, and submits opening balance to cubit',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestApp(
          child: const OpenShiftDialog(),
          sessionCubit: sessionCubit,
          cashierCubit: cashierCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cashier_open_dialog_title'.tr()), findsOneWidget);

      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.first, '500');
      await tester.pump();

      final openBtn = find.text('cashier_open_shift_btn'.tr());
      await tester.tap(openBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      expect(cashierCubit.state.hasActiveShift, isTrue);
      expect(cashierCubit.state.activeShift!.openingBalancePiastres, equals(50000));
    });

    testWidgets('7. CloseShiftDialog calculates discrepancy dynamically and displays warning on shortage',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 50000,
      );
      await cashierCubit.init(branchId: 'branch_1', userId: 'USER-REC');
      final shift = cashierCubit.state.activeShift!;

      await tester.pumpWidget(
        _buildTestApp(
          child: CloseShiftDialog(shift: shift),
          sessionCubit: sessionCubit,
          cashierCubit: cashierCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cashier_close_dialog_title'.tr()), findsOneWidget);
      expect(find.text('500.00 ج.م'), findsOneWidget);

      // Enter cash less than expected -> 400 EGP (100 EGP shortage)
      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.first, '400');
      await tester.pump();

      expect(find.textContaining('cashier_shortage_warning'.tr()), findsOneWidget);
      expect(find.text('cashier_shortage_reason_label'.tr()), findsWidgets);
    });

    testWidgets('8. CollectPaymentDialog renders booking summary, accepts amount, and submits collection',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 50000,
      );
      await cashierCubit.init(branchId: 'branch_1', userId: 'USER-REC');
      final shift = cashierCubit.state.activeShift!;

      bookingsRepo.addBooking(const BookingModel(
        id: 'BK-COLLECT-01',
        totalPrice: 400,
        paidAmount: 100,
        paymentStatus: PaymentStatusEnum.partiallyPaid,
        patientName: 'خالد سليم',
      ));

      await tester.pumpWidget(
        _buildTestApp(
          child: CollectPaymentDialog(
            bookingId: 'BK-COLLECT-01',
            patientId: 'PAT-01',
            patientName: 'خالد سليم',
            totalPrice: 400,
            paidAmount: 100,
            shiftId: shift.id!,
            branchId: 'branch_1',
          ),
          sessionCubit: sessionCubit,
          cashierCubit: cashierCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cashier_collect_dialog_title'.tr()), findsOneWidget);
      expect(find.text('خالد سليم'), findsOneWidget);
      expect(find.text('400.00 ج.م'), findsOneWidget);
      expect(find.text('100.00 ج.م'), findsOneWidget);
      expect(find.text('300.00 ج.م'), findsOneWidget);

      final collectBtn = find.text('cashier_collect_btn'.tr());
      await tester.tap(collectBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      expect(cashierCubit.state.lastPayment, isNotNull);
      expect(cashierCubit.state.lastPayment!.bookingId, equals('BK-COLLECT-01'));
    });

    testWidgets('9. RefundPaymentDialog renders payment details and allows refund submission',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 50000,
      );
      await cashierCubit.init(branchId: 'branch_1', userId: 'USER-REC');
      final shift = cashierCubit.state.activeShift!;

      bookingsRepo.addBooking(const BookingModel(
        id: 'BK-REF-01',
        totalPrice: 200,
        paidAmount: 0,
        paymentStatus: PaymentStatusEnum.unpaid,
      ));

      await cashierCubit.collectPayment(
        clientRequestId: 'req-c-init',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'BK-REF-01',
        patientId: 'PAT-02',
        patientName: 'نورا حسن',
        amountPiastres: 20000,
        paymentMethod: 'cash',
      );

      final payment = cashierCubit.state.lastPayment!;

      await tester.pumpWidget(
        _buildTestApp(
          child: RefundPaymentDialog(payment: payment),
          sessionCubit: sessionCubit,
          cashierCubit: cashierCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cashier_refund_dialog_title'.tr()), findsOneWidget);
      expect(find.text('نورا حسن'), findsOneWidget);
      expect(find.text('200.00 ج.م'), findsOneWidget);

      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.at(1), 'إلغاء الموعد بناء على طلب المريض');
      await tester.pump();

      final refundBtn = find.text('cashier_confirm_refund'.tr());
      await tester.tap(refundBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      expect(cashierCubit.state.lastRefund, isNotNull);
      expect(cashierCubit.state.lastRefund!.originalPaymentId, equals(payment.id));
    });

    testWidgets('10. RecordDrawerExpenseDialog selects movement type and submits expense',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 50000,
      );
      await cashierCubit.init(branchId: 'branch_1', userId: 'USER-REC');
      final shift = cashierCubit.state.activeShift!;

      await tester.pumpWidget(
        _buildTestApp(
          child: RecordDrawerExpenseDialog(
            shiftId: shift.id!,
            branchId: 'branch_1',
          ),
          sessionCubit: sessionCubit,
          cashierCubit: cashierCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cashier_expense_dialog_title'.tr()), findsOneWidget);

      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.at(1), '75');
      await tester.enterText(inputs.at(2), 'شراء منظفات للعيادة');
      await tester.pump();

      final saveBtn = find.text('save'.tr());
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      expect(cashierCubit.state.activeShift!.totalExpensesPiastres, equals(7500));
    });
  });
}
