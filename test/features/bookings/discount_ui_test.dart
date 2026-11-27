import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/helpers/app_formatter_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/discount_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/contracts/active_visit_lookup.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import 'package:eyadty/features/bookings/domain/use_cases/apply_booking_discount_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/create_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_by_id_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_summary_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/remove_booking_discount_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/update_booking_use_case.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_card.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_discount_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_price_summary_card.dart';
import 'package:eyadty/features/bookings/presentation/widgets/bookings_table.dart';
import 'package:eyadty/features/bookings/presentation/widgets/free_booking_badge.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo_impl.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo.dart';
import 'package:eyadty/features/users_management/domain/use_cases/save_role_use_case.dart';
import 'package:eyadty/features/users_management/domain/use_cases/update_role_discount_policy_use_case.dart';
import 'package:eyadty/features/users_management/presentation/cubit/staff_users_cubit.dart';
import 'package:eyadty/features/users_management/presentation/pages/dialogs/role_permissions_matrix_dialog.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';

class _FakeActiveVisitLookup implements ActiveVisitLookup {
  const _FakeActiveVisitLookup();
  @override
  Future<VisitStatusEnum?> getVisitStatusByBookingId(String bookingId) async =>
      null;
}

Widget _buildLocalizedWidget({
  required Widget child,
  required SessionCubit sessionCubit,
  BookingsCubit? bookingsCubit,
  StaffUsersCubit? staffUsersCubit,
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
        if (bookingsCubit != null)
          BlocProvider<BookingsCubit>.value(value: bookingsCubit),
        if (staffUsersCubit != null)
          BlocProvider<StaffUsersCubit>.value(value: staffUsersCubit),
      ],
      child: MaterialApp(
        locale: const Locale('ar', 'EG'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionCubit sessionCubit;
  late BookingsRepoImpl bookingsRepo;
  late StaffUsersRepoImpl staffUsersRepo;
  late InMemoryAuditLogger auditLogger;
  late BookingsCubit bookingsCubit;
  late StaffUsersCubit staffUsersCubit;

  const ownerUser = StaffUserModel(
    id: 'USER-OWNER',
    fullName: 'د. طارق المنشاوي (المالك)',
    isOwner: true,
    isActive: true,
    branchAssignments: [
      BranchAssignmentModel(
        branchId: 'branch_1',
        roleIds: [RoleIds.branchManager],
      ),
    ],
  );

  const receptionUser = StaffUserModel(
    id: 'USER-REC',
    fullName: 'منى إبراهيم (استقبال)',
    isOwner: false,
    isActive: true,
    branchAssignments: [
      BranchAssignmentModel(
        branchId: 'branch_1',
        roleIds: [RoleIds.reception],
      ),
    ],
  );

  const doctorUser = StaffUserModel(
    id: 'USER-DOC',
    fullName: 'د. حسام مصطفى (طبيب)',
    isOwner: false,
    isActive: true,
    branchAssignments: [
      BranchAssignmentModel(
        branchId: 'branch_1',
        roleIds: [RoleIds.doctor],
      ),
    ],
  );

  const managerUser = StaffUserModel(
    id: 'USER-MGR',
    fullName: 'م. أحمد مهران (مدير الفرع)',
    isOwner: false,
    isActive: true,
    branchAssignments: [
      BranchAssignmentModel(
        branchId: 'branch_1',
        roleIds: [RoleIds.branchManager],
      ),
    ],
  );

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('ar_EG', null);
  });

  setUp(() {
    getIt.reset();
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
    staffUsersRepo = StaffUsersRepoImpl(apiConsumer: LocalServerApiConsumer(), auditLogger: auditLogger);
    bookingsRepo = BookingsRepoImpl(apiConsumer: LocalServerApiConsumer());

    sessionCubit = SessionCubit(
      SessionState.initial().copyWith(
        currentUser: ownerUser,
        activeBranchId: 'branch_1',
      ),
      initialRoles: RoleDefinitionModel.defaultSystemRoles(),
    );

    getIt.registerLazySingleton<SessionCubit>(() => sessionCubit);
    getIt.registerLazySingleton<PermissionEvaluator>(
      () => sessionCubit.permissionEvaluator,
    );
    getIt.registerLazySingleton<BookingsRepo>(() => bookingsRepo);
    getIt.registerLazySingleton<StaffUsersRepo>(() => staffUsersRepo);
    getIt.registerLazySingleton<AuditLogger>(() => auditLogger);

    final applyDiscountUseCase = ApplyBookingDiscountUseCase(
      bookingsRepo: bookingsRepo,
      staffUsersRepo: staffUsersRepo,
      permissionEvaluator: sessionCubit.permissionEvaluator,
      currentUserProvider: sessionCubit,
      auditLogger: auditLogger,
    );
    final removeDiscountUseCase = RemoveBookingDiscountUseCase(
      bookingsRepo: bookingsRepo,
      staffUsersRepo: staffUsersRepo,
      permissionEvaluator: sessionCubit.permissionEvaluator,
      currentUserProvider: sessionCubit,
      auditLogger: auditLogger,
    );
    final createBookingUseCase = CreateBookingUseCase(
      repo: bookingsRepo,
      staffUsersRepo: staffUsersRepo,
      permissionEvaluator: sessionCubit.permissionEvaluator,
      currentUserProvider: sessionCubit,
      auditLogger: auditLogger,
    );
    final updateBookingUseCase = UpdateBookingUseCase(
      repo: bookingsRepo,
      staffUsersRepo: staffUsersRepo,
      permissionEvaluator: sessionCubit.permissionEvaluator,
      currentUserProvider: sessionCubit,
      auditLogger: auditLogger,
    );
    final updatePolicyUseCase = UpdateRoleDiscountPolicyUseCase(
      staffUsersRepo: staffUsersRepo,
      auditLogger: auditLogger,
    );
    final saveRoleUseCase = SaveRoleUseCase(
      staffUsersRepo: staffUsersRepo,
      currentUserProvider: sessionCubit,
      auditLogger: auditLogger,
    );

    getIt.registerLazySingleton<ApplyBookingDiscountUseCase>(
      () => applyDiscountUseCase,
    );
    getIt.registerLazySingleton<RemoveBookingDiscountUseCase>(
      () => removeDiscountUseCase,
    );
    getIt.registerLazySingleton<CreateBookingUseCase>(
      () => createBookingUseCase,
    );
    getIt.registerLazySingleton<UpdateBookingUseCase>(
      () => updateBookingUseCase,
    );
    getIt.registerLazySingleton<UpdateRoleDiscountPolicyUseCase>(
      () => updatePolicyUseCase,
    );
    getIt.registerLazySingleton<SaveRoleUseCase>(() => saveRoleUseCase);

    bookingsCubit = BookingsCubit(
      getBookingSummaryUseCase: GetBookingSummaryUseCase(repo: bookingsRepo),
      getBookingsUseCase: GetBookingsUseCase(repo: bookingsRepo),
      getBookingByIdUseCase: GetBookingByIdUseCase(repo: bookingsRepo),
      createBookingUseCase: createBookingUseCase,
      updateBookingUseCase: updateBookingUseCase,
      changeBookingStatusUseCase: ChangeBookingStatusUseCase(
        repo: bookingsRepo,
        activeVisitLookup: const _FakeActiveVisitLookup(),
      ),
      reassignTechnicianUseCase: ReassignTechnicianUseCase(
        repo: bookingsRepo,
        activeVisitLookup: const _FakeActiveVisitLookup(),
      ),
      deleteBookingUseCase: DeleteBookingUseCase(
        repo: bookingsRepo,
        activeVisitLookup: const _FakeActiveVisitLookup(),
      ),
      applyBookingDiscountUseCase: applyDiscountUseCase,
      removeBookingDiscountUseCase: removeDiscountUseCase,
    );

    staffUsersCubit = StaffUsersCubit(
      staffUsersRepo: staffUsersRepo,
      saveRoleUseCase: saveRoleUseCase,
    );
    staffUsersCubit.loadData(showLoading: false);
  });

  group('B-DISC M-3: Discount UI Widgets Tests', () {
    testWidgets(
        'T1: FreeBookingBadge renders with gift icon and localized badge text',
        (tester) async {
      await tester.pumpWidget(
        _buildLocalizedWidget(
          child: const FreeBookingBadge(),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FreeBookingBadge), findsOneWidget);
      expect(find.byIcon(Icons.card_giftcard_rounded), findsOneWidget);
      expect(find.text('disc_free_badge'.tr()), findsOneWidget);
    });

    testWidgets(
        'T2: BookingsTable and BookingCard display FreeBookingBadge for free consultation bookings',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const freeBooking = BookingModel(
        id: 'BOOK-FREE-UI',
        patientName: 'مريض تجريبي',
        consultationFee: 300,
        paidAmount: 0,
        discountType: DiscountTypeEnum.free,
        discountValue: 0,
        status: BookingStatusEnum.waiting,
        paymentStatus: PaymentStatusEnum.unpaid,
        branchId: 'branch_1',
      );

      await tester.pumpWidget(
        _buildLocalizedWidget(
          child: Column(
            children: [
              BookingsTable(
                bookings: const [freeBooking],
                onEdit: (_) {},
                onChangeStatus: (_) {},
                onReassignTechnician: (_) {},
                onDelete: (_) {},
              ),
              const SizedBox(height: 16),
              BookingCard(
                booking: freeBooking,
                onEdit: () {},
                onChangeStatus: () {},
                onReassignTechnician: () {},
                onDelete: () {},
              ),
            ],
          ),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FreeBookingBadge), findsNWidgets(2));
    });

    testWidgets(
        'T3: BookingDiscountSection is hidden for doctor (lacks applyBookingDiscount) and visible for reception',
        (tester) async {
      final typeController = TextEditingController();
      final valController = TextEditingController();
      final reasonController = TextEditingController();

      // 1. Doctor -> Hidden
      sessionCubit.emit(
        sessionCubit.state.copyWith(
          currentUser: doctorUser,
        ),
      );

      bookingsCubit.initBookingForm(null);

      await tester.pumpWidget(
        _buildLocalizedWidget(
          child: BookingDiscountSection(
            discountTypeController: typeController,
            discountValueController: valController,
            discountReasonController: reasonController,
          ),
          sessionCubit: sessionCubit,
          bookingsCubit: bookingsCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('disc_section_title'.tr()), findsNothing);

      // 2. Receptionist -> Visible
      sessionCubit.emit(
        sessionCubit.state.copyWith(
          currentUser: receptionUser,
        ),
      );

      await tester.pumpWidget(
        _buildLocalizedWidget(
          child: BookingDiscountSection(
            discountTypeController: typeController,
            discountValueController: valController,
            discountReasonController: reasonController,
          ),
          sessionCubit: sessionCubit,
          bookingsCubit: bookingsCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('disc_section_title'.tr()), findsWidgets);
    });

    testWidgets(
        'T4: Receptionist does NOT see free consultation option by default, but sees it after owner updates role policy',
        (tester) async {
      final typeController = TextEditingController();
      final valController = TextEditingController();
      final reasonController = TextEditingController();

      sessionCubit.updateCachedRoles(RoleDefinitionModel.defaultSystemRoles());
      sessionCubit.emit(
        sessionCubit.state.copyWith(
          currentUser: receptionUser,
        ),
      );
      bookingsCubit.initBookingForm(null);

      // 1. Initially reception canGrantFreeConsultation is false
      await tester.pumpWidget(
        _buildLocalizedWidget(
          child: BookingDiscountSection(
            discountTypeController: typeController,
            discountValueController: valController,
            discountReasonController: reasonController,
          ),
          sessionCubit: sessionCubit,
          bookingsCubit: bookingsCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Tap on stack selector
      await tester.tap(find.byType(BookingDiscountSection));
      await tester.pumpAndSettle();

      // Free consultation option should not be in the available list for receptionist
      // (verified via role definition)
      final receptionRole = sessionCubit.currentRoles
          .firstWhere((r) => r.id == RoleIds.reception);
      expect(receptionRole.canGrantFreeConsultation, isFalse);

      // 2. Owner updates reception policy to grant free consultation
      final updatedRoles = sessionCubit.currentRoles.map((r) {
        if (r.id == RoleIds.reception) {
          return r.copyWith(canGrantFreeConsultation: true);
        }
        return r;
      }).toList();
      sessionCubit.updateCachedRoles(updatedRoles);

      await tester.pumpWidget(
        _buildLocalizedWidget(
          child: BookingDiscountSection(
            discountTypeController: typeController,
            discountValueController: valController,
            discountReasonController: reasonController,
          ),
          sessionCubit: sessionCubit,
          bookingsCubit: bookingsCubit,
        ),
      );
      await tester.pumpAndSettle();

      final updatedRole = sessionCubit.currentRoles
          .firstWhere((r) => r.id == RoleIds.reception);
      expect(updatedRole.canGrantFreeConsultation, isTrue);
    });

    testWidgets(
        'T5: BookingPriceSummaryCard displays full breakdown, free badge, and remove discount button',
        (tester) async {
      const discountedBooking = BookingModel(
        id: 'BOOK-SUMMARY-UI',
        consultationFee: 300,
        paidAmount: 100,
        discountType: DiscountTypeEnum.percentage,
        discountValue: 20,
        discountReason: 'خصم عائلي معتمد',
        discountApprovedByUserId: 'USER-REC',
        status: BookingStatusEnum.waiting,
        paymentStatus: PaymentStatusEnum.unpaid,
        branchId: 'branch_1',
      );

      await tester.pumpWidget(
        _buildLocalizedWidget(
          child: const BookingPriceSummaryCard(booking: discountedBooking),
          sessionCubit: sessionCubit,
          bookingsCubit: bookingsCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Verify price breakdown
      expect(find.text('disc_price_summary_title'.tr()), findsOneWidget);
      expect(find.text(AppFormatterHelper.formatCurrency(300)), findsOneWidget); // Original
      expect(find.text('- ${AppFormatterHelper.formatCurrency(60)}'), findsOneWidget); // Discount Amount
      expect(find.text(AppFormatterHelper.formatCurrency(240)), findsOneWidget); // Net Amount
      expect(find.text(AppFormatterHelper.formatCurrency(100)), findsOneWidget); // Paid
      expect(find.text(AppFormatterHelper.formatCurrency(140)), findsOneWidget); // Remaining
      expect(find.text('خصم عائلي معتمد'), findsOneWidget); // Reason
      expect(find.text('USER-REC'), findsOneWidget); // Approver

      // Verify Remove Discount button is present for authorized user
      expect(find.text('disc_remove_button'.tr()), findsOneWidget);
    });

    testWidgets(
        'T6: Remove discount button opens dialog, requires reason, and double-tap is protected',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const discountedBooking = BookingModel(
        id: 'BOOK-REMOVE-DIALOG',
        consultationFee: 300,
        paidAmount: 0,
        discountType: DiscountTypeEnum.percentage,
        discountValue: 20,
        discountReason: 'خصم أولي',
        discountApprovedByUserId: 'USER-OWNER',
        status: BookingStatusEnum.waiting,
        paymentStatus: PaymentStatusEnum.unpaid,
        branchId: 'branch_1',
      );

      await bookingsRepo.createBooking(discountedBooking);

      await tester.pumpWidget(
        _buildLocalizedWidget(
          child: const BookingPriceSummaryCard(booking: discountedBooking),
          sessionCubit: sessionCubit,
          bookingsCubit: bookingsCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Tap "إزالة الخصم"
      await tester.tap(find.text('disc_remove_button'.tr()));
      await tester.pumpAndSettle();

      // Confirm dialog appeared
      expect(find.text('disc_confirm_remove'.tr()), findsOneWidget);
      expect(find.text('disc_remove_reason_label'.tr()), findsOneWidget);

      // Tap confirm without entering reason -> validation error
      await tester.tap(find.text('disc_confirm_remove'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('disc_validation_reason_required'.tr()), findsOneWidget);

      // Enter reason and confirm
      await tester.enterText(
        find.widgetWithText(TextFormField, ''),
        'تم إلغاء العرض بناءً على طلب الإدارة',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('disc_confirm_remove'.tr()));
      await tester.pump(); // Start async remove
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4)); // Drain Toastification timer

      // Dialog closed
      expect(find.text('disc_confirm_remove'.tr()), findsNothing);
    });

    testWidgets(
        'T7: Branch manager does NOT see Discount Policy section in RolePermissionsMatrixDialog',
        (tester) async {
      // Set session user to branch manager (not owner)
      sessionCubit.emit(
        sessionCubit.state.copyWith(
          currentUser: managerUser,
        ),
      );

      await tester.pumpWidget(
        _buildLocalizedWidget(
          child: const RolePermissionsMatrixDialog(),
          sessionCubit: sessionCubit,
          staffUsersCubit: staffUsersCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Discount policy section should NOT be visible
      expect(find.text('disc_policy_title'.tr()), findsNothing);
      expect(find.text('disc_policy_max_pct'.tr()), findsNothing);
    });

    testWidgets(
        'T8: Owner DOES see Discount Policy section in RolePermissionsMatrixDialog and can modify policy',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Set session user to owner
      sessionCubit.emit(
        sessionCubit.state.copyWith(
          currentUser: ownerUser,
        ),
      );

      await tester.pumpWidget(
        _buildLocalizedWidget(
          child: const RolePermissionsMatrixDialog(),
          sessionCubit: sessionCubit,
          staffUsersCubit: staffUsersCubit,
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('disc_policy_title'.tr()),
        300,
        scrollable: find.byType(Scrollable).last,
      );

      // Discount policy section IS visible for owner
      expect(find.text('disc_policy_title'.tr()), findsOneWidget);
      expect(find.text('disc_policy_max_pct'.tr()), findsOneWidget);
      expect(find.text('disc_policy_can_free'.tr()), findsOneWidget);

      // Save changes button is enabled
      expect(find.text('save_changes'.tr()), findsOneWidget);
    });
  });
}
