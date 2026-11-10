import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import 'package:eyadty/features/patients/data/repo/patients_mock_repo_impl.dart';
import 'package:eyadty/features/patients/domain/repo/patients_repo.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/visits/data/models/consultation_queue_item_model.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/data/models/vitals_model.dart';
import 'package:eyadty/features/visits/data/repo/visits_mock_repo_impl.dart';
import 'package:eyadty/features/visits/domain/repo/visits_repo.dart';
import 'package:eyadty/features/visits/domain/use_cases/finalize_visit_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/get_doctor_queue_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/get_visit_by_booking_id_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/record_vitals_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/save_visit_draft_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/start_consultation_use_case.dart';
import 'package:eyadty/features/visits/presentation/manager/visits_cubit.dart';
import 'package:eyadty/features/visits/presentation/pages/visits_page.dart';
import 'package:eyadty/features/visits/presentation/widgets/adaptive_visits_view.dart';
import 'package:eyadty/features/visits/presentation/widgets/consultation_queue_card.dart';
import 'package:eyadty/features/visits/presentation/widgets/consultation_queue_table.dart';

Widget _buildLocalizedApp({
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
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryAuditLogger auditLogger;
  late BookingsMockRepoImpl bookingsRepo;
  late VisitsMockRepoImpl visitsRepo;
  late PatientsMockRepoImpl patientsRepo;
  late SessionCubit sessionCubit;
  late VisitsCubit visitsCubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('ar', null);
  });

  setUp(() async {
    CairoTimeHelper.setFixedClock(DateTime(2026, 11, 10, 10, 0));
    await getIt.reset();

    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
    bookingsRepo = BookingsMockRepoImpl();
    visitsRepo = VisitsMockRepoImpl(bookingsRepo: bookingsRepo);
    patientsRepo = PatientsMockRepoImpl();

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

    sessionCubit = SessionCubit(
      const SessionState(
        currentUser: doctorUser,
        activeBranchId: 'branch_1',
      ),
    );

    visitsCubit = VisitsCubit(
      visitsRepo: visitsRepo,
      bookingsRepo: bookingsRepo,
      patientsRepo: patientsRepo,
      getDoctorQueueUseCase: GetDoctorQueueUseCase(repo: visitsRepo),
      getVisitByBookingIdUseCase: GetVisitByBookingIdUseCase(repo: visitsRepo),
      startConsultationUseCase: StartConsultationUseCase(
        visitsRepo: visitsRepo,
        bookingsRepo: bookingsRepo,
        permissionEvaluator: sessionCubit.permissionEvaluator,
        auditLogger: auditLogger,
      ),
      saveVisitDraftUseCase: SaveVisitDraftUseCase(
        repo: visitsRepo,
        permissionEvaluator: sessionCubit.permissionEvaluator,
      ),
      recordVitalsUseCase: RecordVitalsUseCase(
        visitsRepo: visitsRepo,
        bookingsRepo: bookingsRepo,
        permissionEvaluator: sessionCubit.permissionEvaluator,
        auditLogger: auditLogger,
      ),
      finalizeVisitUseCase: FinalizeVisitUseCase(
        visitsRepo: visitsRepo,
        bookingsRepo: bookingsRepo,
        permissionEvaluator: sessionCubit.permissionEvaluator,
        auditLogger: auditLogger,
      ),
      permissionEvaluator: sessionCubit.permissionEvaluator,
      auditLogger: auditLogger,
      sessionCubit: sessionCubit,
    );

    getIt.registerSingleton<AuditLogger>(auditLogger);
    getIt.registerSingleton<BookingsRepo>(bookingsRepo);
    getIt.registerSingleton<VisitsRepo>(visitsRepo);
    getIt.registerSingleton<PatientsRepo>(patientsRepo);
    getIt.registerSingleton<SessionCubit>(sessionCubit);
    getIt.registerSingleton<VisitsCubit>(visitsCubit);
  });

  tearDown(() async {
    CairoTimeHelper.resetFixedClock();
    await visitsCubit.close();
    await sessionCubit.close();
  });

  group('ConsultationQueueTable & Actions RBAC Tests', () {
    testWidgets('Doctor DOC-01 sees correct action buttons for own patients per status', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = CairoTimeHelper.now();
      final items = [
        // 1. Waiting without visit
        ConsultationQueueItemModel(
          booking: BookingModel(
            id: 'BK-1',
            queueNumber: 1,
            patientName: 'مريض 1',
            doctorId: 'DOC-01',
            doctorName: 'د. حسام',
            status: BookingStatusEnum.waiting,
            branchId: 'branch_1',
            appointmentTime: now,
          ),
          visit: null,
        ),
        // 2. Waiting with triage visit
        ConsultationQueueItemModel(
          booking: BookingModel(
            id: 'BK-2',
            queueNumber: 2,
            patientName: 'مريض 2',
            doctorId: 'DOC-01',
            doctorName: 'د. حسام',
            status: BookingStatusEnum.waiting,
            branchId: 'branch_1',
            appointmentTime: now,
          ),
          visit: const VisitModel(
            id: 'VIS-2',
            bookingId: 'BK-2',
            doctorId: 'DOC-01',
            status: VisitStatusEnum.triage,
            vitals: VitalsModel(systolicBp: 120),
          ),
        ),
        // 3. In Progress visit
        ConsultationQueueItemModel(
          booking: BookingModel(
            id: 'BK-3',
            queueNumber: 3,
            patientName: 'مريض 3',
            doctorId: 'DOC-01',
            doctorName: 'د. حسام',
            status: BookingStatusEnum.inConsultation,
            branchId: 'branch_1',
            appointmentTime: now,
          ),
          visit: const VisitModel(
            id: 'VIS-3',
            bookingId: 'BK-3',
            doctorId: 'DOC-01',
            status: VisitStatusEnum.inProgress,
          ),
        ),
        // 4. Finalized visit
        ConsultationQueueItemModel(
          booking: BookingModel(
            id: 'BK-4',
            queueNumber: 4,
            patientName: 'مريض 4',
            doctorId: 'DOC-01',
            doctorName: 'د. حسام',
            status: BookingStatusEnum.completed,
            branchId: 'branch_1',
            appointmentTime: now,
          ),
          visit: const VisitModel(
            id: 'VIS-4',
            bookingId: 'BK-4',
            doctorId: 'DOC-01',
            status: VisitStatusEnum.finalized,
          ),
        ),
      ];

      await tester.pumpWidget(
        _buildLocalizedApp(
          sessionCubit: sessionCubit,
          child: ConsultationQueueTable(
            items: items,
            evaluator: sessionCubit.permissionEvaluator,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Buttons:
      // BK-1: "بدء الكشف"
      expect(find.text('visits_start_consultation'.tr()), findsOneWidget);
      // BK-2: "إكمال الكشف (علامات مسجّلة)"
      expect(find.text('visits_complete_vitals'.tr()), findsOneWidget);
      // BK-3: "متابعة الكشف"
      expect(find.text('visits_continue_consultation'.tr()), findsOneWidget);
      // BK-4: "عرض الكشف"
      expect(find.text('visits_action_view'.tr()), findsOneWidget);
    });

    testWidgets('Nurse sees only record vitals for waiting bookings, and no consultation buttons', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      sessionCubit.switchMockUser(
        const StaffUserModel(
          id: 'USR-NURSE-01',
          fullName: 'ممرضة فاطمة',
          isActive: true,
          branchAssignments: [
            BranchAssignmentModel(
              branchId: 'branch_1',
              roleIds: [RoleIds.nurse],
            ),
          ],
        ),
      );
      await tester.pump();

      final now = CairoTimeHelper.now();
      final items = [
        ConsultationQueueItemModel(
          booking: BookingModel(
            id: 'BK-1',
            queueNumber: 1,
            patientName: 'مريض 1',
            doctorId: 'DOC-01',
            status: BookingStatusEnum.waiting,
            branchId: 'branch_1',
            appointmentTime: now,
          ),
          visit: null,
        ),
        ConsultationQueueItemModel(
          booking: BookingModel(
            id: 'BK-2',
            queueNumber: 2,
            patientName: 'مريض 2',
            doctorId: 'DOC-01',
            status: BookingStatusEnum.inConsultation,
            branchId: 'branch_1',
            appointmentTime: now,
          ),
          visit: const VisitModel(status: VisitStatusEnum.inProgress),
        ),
      ];

      await tester.pumpWidget(
        _buildLocalizedApp(
          sessionCubit: sessionCubit,
          child: ConsultationQueueTable(
            items: items,
            evaluator: sessionCubit.permissionEvaluator,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nurse sees "تسجيل العلامات" for BK-1
      expect(find.text('visits_record_vitals'.tr()), findsOneWidget);
      // Nurse NEVER sees "بدء الكشف" nor "متابعة الكشف"
      expect(find.text('visits_start_consultation'.tr()), findsNothing);
      expect(find.text('visits_continue_consultation'.tr()), findsNothing);
    });

    testWidgets('Mobile viewport renders ConsultationQueueCard instead of table', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        ConsultationQueueItemModel(
          booking: const BookingModel(
            id: 'BK-1',
            queueNumber: 1,
            patientName: 'مريض هاتف',
            doctorId: 'DOC-01',
            status: BookingStatusEnum.waiting,
            branchId: 'branch_1',
          ),
          visit: null,
        ),
      ];

      await tester.pumpWidget(
        _buildLocalizedApp(
          sessionCubit: sessionCubit,
          child: AdaptiveVisitsView(
            items: items,
            evaluator: sessionCubit.permissionEvaluator,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConsultationQueueCard), findsOneWidget);
      expect(find.byType(ConsultationQueueTable), findsNothing);
      expect(find.text('مريض هاتف'), findsOneWidget);
    });

    testWidgets('VisitsPage renders header, filter bar, and loads queue', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildLocalizedApp(
          sessionCubit: sessionCubit,
          child: VisitsPage(visitsCubit: visitsCubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('visits_page_title'.tr()), findsOneWidget);
      expect(find.text('visits_page_subtitle'.tr()), findsOneWidget);
      expect(find.byType(AdaptiveVisitsView), findsOneWidget);
    });
  });
}
