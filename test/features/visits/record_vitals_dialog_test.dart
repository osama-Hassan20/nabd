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
import 'package:eyadty/features/visits/presentation/widgets/dialogs/record_vitals_dialog.dart';
import 'package:eyadty/features/visits/presentation/widgets/patient_allergy_banner.dart';
import 'package:eyadty/features/visits/presentation/widgets/vitals_input_panel.dart';

Widget _buildLocalizedApp({
  required Widget child,
  required SessionCubit sessionCubit,
  VisitsCubit? visitsCubit,
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
        if (visitsCubit != null)
          BlocProvider<VisitsCubit>.value(value: visitsCubit),
      ],
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
    await getIt.reset();

    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
    bookingsRepo = BookingsMockRepoImpl();
    visitsRepo = VisitsMockRepoImpl(bookingsRepo: bookingsRepo);
    patientsRepo = PatientsMockRepoImpl();

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

    sessionCubit = SessionCubit(
      const SessionState(
        currentUser: nurseUser,
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
    await visitsCubit.close();
    await sessionCubit.close();
  });

  testWidgets('RecordVitalsDialog renders vitals inputs, allergy banner, and NO clinical notes', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final item = ConsultationQueueItemModel(
      booking: const BookingModel(
        id: 'MED-101',
        queueNumber: 1,
        patientId: 'PAT-000101',
        patientName: 'سارة أحمد عبد الله',
        doctorId: 'DOC-01',
        doctorName: 'د. حسام الدين مصطفى',
        status: BookingStatusEnum.waiting,
        branchId: 'branch_1',
      ),
      visit: null,
    );

    visitsCubit.initRecordVitals(item);

    await tester.pumpWidget(
      _buildLocalizedApp(
        sessionCubit: sessionCubit,
        visitsCubit: visitsCubit,
        child: RecordVitalsDialog(
          item: item,
          visitsCubit: visitsCubit,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify Title & Patient Name
    expect(find.text('visits_record_vitals'.tr()), findsOneWidget);
    expect(find.textContaining('سارة أحمد عبد الله'), findsOneWidget);

    // Verify Vitals Input Panel is present
    expect(find.byType(VitalsInputPanel), findsOneWidget);
    expect(find.byType(PatientAllergyBanner), findsOneWidget);

    // STRICT Security check: NO clinical diagnosis or medical notes fields in RecordVitalsDialog
    expect(find.text('visits_diagnosis'.tr()), findsNothing);
    expect(find.text('visits_treatment_plan'.tr()), findsNothing);
    expect(find.text('visits_chief_complaint'.tr()), findsNothing);
  });

  testWidgets('VitalsInputPanel displays warning text when entering high/low vitals', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const highVitals = VitalsModel(
      systolicBp: 210, // > 200
      oxygenSaturation: 85, // < 90
    );

    await tester.pumpWidget(
      _buildLocalizedApp(
        sessionCubit: sessionCubit,
        child: VitalsInputPanel(
          vitals: highVitals,
          onVitalsChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Warning texts appear
    expect(find.text('visits_vitals_warn_bp_high'.tr()), findsOneWidget);
    expect(find.text('visits_vitals_warn_spo2_low'.tr()), findsOneWidget);
  });

  testWidgets('PatientAllergyBanner displays warning chips when allergies exist', (tester) async {
    await tester.pumpWidget(
      _buildLocalizedApp(
        sessionCubit: sessionCubit,
        child: const PatientAllergyBanner(
          allergies: ['بنسلين', 'سلفا'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('visits_allergy_warning'.tr()), findsOneWidget);
    expect(find.text('بنسلين'), findsOneWidget);
    expect(find.text('سلفا'), findsOneWidget);
  });
}
