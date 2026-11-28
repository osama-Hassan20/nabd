import 'package:easy_localization/easy_localization.dart';
import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/create_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_by_id_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_summary_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_doctor_bookings_for_date_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/update_booking_use_case.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/widgets/adaptive_bookings_view.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_card.dart';
import 'package:eyadty/features/bookings/presentation/widgets/bookings_table.dart';
import 'package:eyadty/features/doctors/data/repo/doctors_repo_impl.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_leaves_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_schedule_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctors_use_case.dart';
import 'package:eyadty/features/settings/data/repo/medical_services_repo_impl.dart';
import 'package:eyadty/features/settings/data/repo/settings_repo_impl.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_company_settings_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_medical_services_use_case.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/visits/data/models/consultation_queue_item_model.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/presentation/widgets/adaptive_visits_view.dart';
import 'package:eyadty/features/visits/presentation/widgets/consultation_queue_table.dart';
import 'package:eyadty/features/visits/presentation/widgets/visit_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUserProvider implements CurrentUserProvider {
  @override
  StaffUserModel? get currentUser => StaffUserModel(
        id: 'USR-NURSE-01',
        fullName: 'ممرضة فاطمة',
        isActive: true,
        isOwner: false,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.nurse]),
        ],
      );

  @override
  String? get activeBranchId => 'branch_1';
}

class _FakeRolesProvider implements RolesProvider {
  @override
  List<RoleDefinitionModel> get currentRoles =>
      RoleDefinitionModel.defaultSystemRoles();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('ar', null);
    await initializeDateFormatting('ar_EG', null);
    await EasyLocalization.ensureInitialized();
  });

  Widget wrap(Widget child) {
    return EasyLocalization(
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar', 'EG'),
      startLocale: const Locale('ar', 'EG'),
      saveLocale: false,
      child: MaterialApp(
        locale: const Locale('ar', 'EG'),
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  group('Step 1 Responsive Queue & Bookings Viewport Tests', () {
    for (final width in [1356.0, 1100.0, 900.0, 600.0]) {
      testWidgets('AdaptiveBookingsView shows status chip and actions button on-screen at width $width', (tester) async {
        const height = 847.0;
        tester.view.physicalSize = Size(width, height);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final api = LocalServerApiConsumer();
        final settingsRepo = SettingsRepoImpl(apiConsumer: api);
        final bookingsRepo = BookingsRepoImpl(apiConsumer: api, settingsRepo: settingsRepo);
        final doctorsRepo = DoctorsRepoImpl(apiConsumer: api, bookingsRepo: bookingsRepo, settingsRepo: settingsRepo);
        final medicalServicesRepo = MedicalServicesRepoImpl(apiConsumer: api);

        final cubit = BookingsCubit(
          getBookingSummaryUseCase: GetBookingSummaryUseCase(repo: bookingsRepo),
          getBookingsUseCase: GetBookingsUseCase(repo: bookingsRepo),
          getBookingByIdUseCase: GetBookingByIdUseCase(repo: bookingsRepo),
          createBookingUseCase: CreateBookingUseCase(repo: bookingsRepo),
          updateBookingUseCase: UpdateBookingUseCase(repo: bookingsRepo),
          changeBookingStatusUseCase: ChangeBookingStatusUseCase(repo: bookingsRepo),
          reassignTechnicianUseCase: ReassignTechnicianUseCase(repo: bookingsRepo),
          deleteBookingUseCase: DeleteBookingUseCase(repo: bookingsRepo),
          getDoctorsUseCase: GetDoctorsUseCase(repo: doctorsRepo),
          getMedicalServicesUseCase: GetMedicalServicesUseCase(repo: medicalServicesRepo),
          getDoctorScheduleUseCase: GetDoctorScheduleUseCase(repo: doctorsRepo),
          getDoctorLeavesUseCase: GetDoctorLeavesUseCase(repo: doctorsRepo),
          getCompanySettingsUseCase: GetCompanySettingsUseCase(repo: settingsRepo),
          getDoctorBookingsForDateUseCase: GetDoctorBookingsForDateUseCase(repo: bookingsRepo),
        );
        cubit.clearDateFilter();
        await cubit.fetchBookings();

        await tester.pumpWidget(
          wrap(
            BlocProvider.value(
              value: cubit,
              child: AdaptiveBookingsView(
                onEdit: (_) {},
                onChangeStatus: (_) {},
                onReassignTechnician: (_) {},
                onDelete: (_) {},
                onRecordVitals: (_) {},
                onCollectPayment: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (width >= 900) {
          expect(find.byType(BookingsTable), findsOneWidget);
        } else {
          expect(find.byType(BookingCard), findsWidgets);
        }

        // Verify status badge text and 3-dot actions button are within viewport bounds
        final statusText = find.text(BookingStatusEnum.waiting.label).first;
        final moreBtn = find.byIcon(Icons.more_vert).first;
        final statusRect = tester.getRect(statusText);
        final moreRect = tester.getRect(moreBtn);
        final viewport = Rect.fromLTWH(0, 0, width, height);

        expect(viewport.contains(statusRect.topLeft), isTrue, reason: 'Status chip left edge off-screen at $width');
        expect(viewport.contains(statusRect.bottomRight), isTrue, reason: 'Status chip right edge off-screen at $width');
        expect(viewport.contains(moreRect.topLeft), isTrue, reason: '3-dot actions button left edge off-screen at $width');
        expect(viewport.contains(moreRect.bottomRight), isTrue, reason: '3-dot actions button right edge off-screen at $width');
        await cubit.close();
      });

      testWidgets('AdaptiveVisitsView shows VisitStatusBadge and action button on-screen at width $width', (tester) async {
        const height = 847.0;
        tester.view.physicalSize = Size(width, height);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final evaluator = PermissionEvaluator(
          userProvider: _FakeUserProvider(),
          rolesProvider: _FakeRolesProvider(),
        );
        final items = [
          ConsultationQueueItemModel(
            booking: BookingModel(
              id: 'BK-VP-1',
              queueNumber: 1,
              patientName: 'سارة أحمد عبد الله',
              doctorId: 'DOC-01',
              doctorName: 'د. حسام الدين مصطفى',
              status: BookingStatusEnum.waiting,
              visitType: BookingTypeEnum.newVisit,
              branchId: 'branch_1',
              appointmentTime: CairoTimeHelper.now(),
            ),
            visit: const VisitModel(status: VisitStatusEnum.triage),
          ),
        ];

        await tester.pumpWidget(
          wrap(
            AdaptiveVisitsView(
              items: items,
              evaluator: evaluator,
              onRecordVitals: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (width >= 900) {
          expect(find.byType(ConsultationQueueTable), findsOneWidget);
        }

        final badge = find.byType(VisitStatusBadge).first;
        final actionBtn = find.byWidgetPredicate((w) => w is ButtonStyleButton).first;
        final badgeRect = tester.getRect(badge);
        final actionRect = tester.getRect(actionBtn);
        final viewport = Rect.fromLTWH(0, 0, width, height);

        expect(viewport.contains(badgeRect.topLeft), isTrue);
        expect(viewport.contains(badgeRect.bottomRight), isTrue);
        expect(viewport.contains(actionRect.topLeft), isTrue);
        expect(viewport.contains(actionRect.bottomRight), isTrue);
      });
    }
  });
}
