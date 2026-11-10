import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_card.dart';
import 'package:eyadty/features/bookings/presentation/widgets/bookings_table.dart';
import 'package:eyadty/features/bookings/presentation/widgets/details_sections/booking_details_top_bar.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

Widget _buildLocalizedWidget({
  required Widget child,
  required SessionCubit sessionCubit,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: false,
    child: BlocProvider<SessionCubit>.value(
      value: sessionCubit,
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

  final today = DateTime(2026, 11, 10, 10, 0);

  const doctorUser = StaffUserModel(
    id: 'USR-DOC-01',
    fullName: 'د. حسام الدين مصطفى',
    isActive: true,
    linkedDoctorId: 'DOC-01',
    branchAssignments: [
      BranchAssignmentModel(
        branchId: 'branch_1',
        isPrimary: true,
        roleIds: [RoleIds.doctor],
      ),
    ],
  );

  const nurseUser = StaffUserModel(
    id: 'USR-NURSE-01',
    fullName: 'ممرضة فاطمة',
    isActive: true,
    branchAssignments: [
      BranchAssignmentModel(
        branchId: 'branch_1',
        isPrimary: true,
        roleIds: [RoleIds.nurse],
      ),
    ],
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('ar', null);
  });

  setUp(() async {
    CairoTimeHelper.setFixedClock(today);
    await getIt.reset();

    sessionCubit = SessionCubit(
      const SessionState(
        currentUser: doctorUser,
        activeBranchId: 'branch_1',
      ),
    );

    getIt.registerSingleton<SessionCubit>(sessionCubit);
    getIt.registerSingleton<PermissionEvaluator>(
      sessionCubit.permissionEvaluator,
    );
  });

  tearDown(() {
    CairoTimeHelper.resetFixedClock();
  });

  group('Bookings Start Consultation Button RBAC & Condition Tests', () {
    testWidgets('BookingsTable shows start consultation action only for assigned doctor today',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool startConsultationTapped = false;

      final bookingToday = BookingModel(
        id: 'BK-101',
        patientName: 'مريض تجريبي',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: BookingStatusEnum.waiting,
        appointmentTime: today,
      );

      await tester.pumpWidget(
        _buildLocalizedWidget(
          sessionCubit: sessionCubit,
          child: BookingsTable(
            bookings: [bookingToday],
            onEdit: (_) {},
            onChangeStatus: (_) {},
            onReassignTechnician: (_) {},
            onDelete: (_) {},
            onStartConsultation: (_) {
              startConsultationTapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the actions popup menu
      final moreBtn = find.byIcon(Icons.more_vert);
      expect(moreBtn, findsOneWidget);
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // Start consultation item must be visible
      final consultationItem = find.text('visits_start_consultation'.tr());
      expect(consultationItem, findsOneWidget);

      await tester.tap(consultationItem);
      await tester.pumpAndSettle();
      expect(startConsultationTapped, isTrue);
    });

    testWidgets('BookingsTable hides start consultation for another doctor or nurse',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final bookingOtherDoc = BookingModel(
        id: 'BK-102',
        patientName: 'مريض آخر',
        doctorId: 'DOC-02', // Different doctor
        branchId: 'branch_1',
        status: BookingStatusEnum.waiting,
        appointmentTime: today,
      );

      await tester.pumpWidget(
        _buildLocalizedWidget(
          sessionCubit: sessionCubit,
          child: BookingsTable(
            bookings: [bookingOtherDoc],
            onEdit: (_) {},
            onChangeStatus: (_) {},
            onReassignTechnician: (_) {},
            onDelete: (_) {},
            onStartConsultation: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Start consultation should NOT be shown
      expect(find.text('visits_start_consultation'.tr()), findsNothing);
    });

    testWidgets('BookingCard shows start consultation button for assigned doctor and hides for yesterday',
        (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Today booking -> visible
      final bookingToday = BookingModel(
        id: 'BK-103',
        patientName: 'أحمد علي',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: BookingStatusEnum.waiting,
        appointmentTime: today,
      );

      await tester.pumpWidget(
        _buildLocalizedWidget(
          sessionCubit: sessionCubit,
          child: BookingCard(
            booking: bookingToday,
            onEdit: () {},
            onChangeStatus: () {},
            onReassignTechnician: () {},
            onDelete: () {},
            onStartConsultation: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('visits_start_consultation'.tr()), findsOneWidget);

      // Close menu
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // 2. Yesterday booking -> hidden
      final bookingYesterday = bookingToday.copyWith(
        appointmentTime: today.subtract(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        _buildLocalizedWidget(
          sessionCubit: sessionCubit,
          child: BookingCard(
            booking: bookingYesterday,
            onEdit: () {},
            onChangeStatus: () {},
            onReassignTechnician: () {},
            onDelete: () {},
            onStartConsultation: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('visits_start_consultation'.tr()), findsNothing);
    });

    testWidgets('BookingDetailsTopBar displays action button for assigned doctor on today booking and invokes callback',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool startConsultationTapped = false;

      final booking = BookingModel(
        id: 'BK-104',
        patientName: 'سارة إبراهيم',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: BookingStatusEnum.waiting,
        appointmentTime: today,
      );

      await tester.pumpWidget(
        _buildLocalizedWidget(
          sessionCubit: sessionCubit,
          child: BookingDetailsTopBar(
            booking: booking,
            onEdit: () {},
            onChangeStatus: () {},
            onReassign: () {},
            onDelete: () {},
            onStartConsultation: () {
              startConsultationTapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar displays start consultation push button directly
      final startBtn = find.text('visits_start_consultation'.tr());
      expect(startBtn, findsOneWidget);

      await tester.tap(startBtn);
      await tester.pumpAndSettle();
      expect(startConsultationTapped, isTrue);
    });

    testWidgets('BookingDetailsTopBar hides button for nurse, branch mismatch, or cancelled booking',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Switch to nurse
      sessionCubit.emit(
        sessionCubit.state.copyWith(
          currentUser: nurseUser,
          activeBranchId: 'branch_1',
        ),
      );

      final booking = BookingModel(
        id: 'BK-105',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: BookingStatusEnum.waiting,
        appointmentTime: today,
      );

      await tester.pumpWidget(
        _buildLocalizedWidget(
          sessionCubit: sessionCubit,
          child: BookingDetailsTopBar(
            booking: booking,
            onEdit: () {},
            onChangeStatus: () {},
            onReassign: () {},
            onDelete: () {},
            onStartConsultation: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('visits_start_consultation'.tr()), findsNothing);
    });
  });
}
