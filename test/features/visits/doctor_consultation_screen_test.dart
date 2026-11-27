import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import 'package:eyadty/features/patients/data/repo/patients_repo_impl.dart';
import 'package:eyadty/features/patients/domain/repo/patients_repo.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/repo/visits_repo_impl.dart';
import 'package:eyadty/features/visits/domain/repo/visits_repo.dart';
import 'package:eyadty/features/visits/domain/use_cases/finalize_visit_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/get_doctor_queue_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/get_visit_by_booking_id_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/record_vitals_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/save_visit_draft_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/start_consultation_use_case.dart';
import 'package:eyadty/features/visits/presentation/helpers/consultation_action_helper.dart';
import 'package:eyadty/features/visits/presentation/manager/visits_cubit.dart';
import 'package:eyadty/features/visits/presentation/pages/doctor_consultation_screen.dart';
import 'package:eyadty/features/visits/presentation/widgets/consultation_notes_panel.dart';
import 'package:eyadty/features/visits/presentation/widgets/dialogs/finalize_visit_dialog.dart';
import 'package:eyadty/features/visits/presentation/widgets/patient_allergy_banner.dart';
import 'package:eyadty/features/visits/presentation/widgets/vitals_input_panel.dart';

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
  late BookingsRepoImpl bookingsRepo;
  late VisitsRepoImpl visitsRepo;
  late PatientsRepoImpl patientsRepo;
  late SessionCubit sessionCubit;
  late VisitsCubit visitsCubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('ar', null);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
    CairoTimeHelper.setFixedClock(DateTime(2026, 11, 10, 10, 0));
    await getIt.reset();

    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
    bookingsRepo = BookingsRepoImpl(apiConsumer: LocalServerApiConsumer());
    visitsRepo = VisitsRepoImpl(apiConsumer: LocalServerApiConsumer(), bookingsRepo: bookingsRepo);
    patientsRepo = PatientsRepoImpl(apiConsumer: LocalServerApiConsumer());

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

    getIt.registerSingleton<SessionCubit>(sessionCubit);
    getIt.registerSingleton<PermissionEvaluator>(
      sessionCubit.permissionEvaluator,
    );
    getIt.registerSingleton<VisitsRepo>(visitsRepo);
    getIt.registerSingleton<BookingsRepo>(bookingsRepo);
    getIt.registerSingleton<PatientsRepo>(patientsRepo);

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
    getIt.registerSingleton<VisitsCubit>(visitsCubit);
  });

  tearDown(() {
    CairoTimeHelper.resetFixedClock();
  });

  group('DoctorConsultationScreen M-5 UI Tests', () {
    testWidgets('renders header, allergy banner, chronic diseases, vitals, and consultation notes',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildLocalizedApp(
          sessionCubit: sessionCubit,
          child: DoctorConsultationScreen(
            visitId: 'VIS-001',
            cubit: visitsCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Allergy banner should be present for PAT-000101 (Penicillin allergy)
      expect(find.byType(PatientAllergyBanner), findsOneWidget);
      expect(find.text('حساسية بنسلين شديدة'), findsOneWidget);

      // Vitals panel should be present
      expect(find.byType(VitalsInputPanel), findsOneWidget);

      // Clinical notes panel should be present
      expect(find.byType(ConsultationNotesPanel), findsOneWidget);

      // Action buttons: Save Draft and Finalize
      expect(find.text('visits_save_draft'.tr()), findsOneWidget);
      expect(find.text('visits_finalize_visit'.tr()), findsOneWidget);
    });

    testWidgets('finalized visit renders locked notice and disables action buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // VIS-002 is finalized in the mock repo
      await tester.pumpWidget(
        _buildLocalizedApp(
          sessionCubit: sessionCubit,
          child: DoctorConsultationScreen(
            visitId: 'VIS-002',
            cubit: visitsCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Locked notice banner should be displayed
      expect(find.text('visits_locked_notice'.tr()), findsOneWidget);

      // Action buttons must NOT be present
      expect(find.text('visits_save_draft'.tr()), findsNothing);
      expect(find.text('visits_finalize_visit'.tr()), findsNothing);
    });

    testWidgets('user without editMedicalDiagnosis sees read-only notes and no action buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Switch to Medical Director who has viewConsultationNotes but NOT editMedicalDiagnosis
      const medicalDirectorUser = StaffUserModel(
        id: 'USR-DIR-01',
        fullName: 'د. المدير الطبي',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.medicalDirector],
          ),
        ],
      );

      sessionCubit.emit(
        sessionCubit.state.copyWith(
          currentUser: medicalDirectorUser,
          activeBranchId: 'branch_1',
        ),
      );

      await tester.pumpWidget(
        _buildLocalizedApp(
          sessionCubit: sessionCubit,
          child: DoctorConsultationScreen(
            visitId: 'VIS-001',
            cubit: visitsCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clinical notes panel is present
      expect(find.byType(ConsultationNotesPanel), findsOneWidget);

      // Buttons for editing/finalizing are hidden
      expect(find.text('visits_save_draft'.tr()), findsNothing);
      expect(find.text('visits_finalize_visit'.tr()), findsNothing);
    });

    testWidgets('Branch Manager sees read-only notes and no action buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const branchManagerUser = StaffUserModel(
        id: 'USR-BM-01',
        fullName: 'أ. مدير الفرع',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.branchManager],
          ),
        ],
      );

      sessionCubit.emit(
        sessionCubit.state.copyWith(
          currentUser: branchManagerUser,
          activeBranchId: 'branch_1',
        ),
      );

      await tester.pumpWidget(
        _buildLocalizedApp(
          sessionCubit: sessionCubit,
          child: DoctorConsultationScreen(
            visitId: 'VIS-001',
            cubit: visitsCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConsultationNotesPanel), findsOneWidget);
      final notesPanel = tester.widget<ConsultationNotesPanel>(
        find.byType(ConsultationNotesPanel),
      );
      expect(notesPanel.isReadOnly, isTrue);
      expect(find.text('visits_save_draft'.tr()), findsNothing);
      expect(find.text('visits_finalize_visit'.tr()), findsNothing);
    });

    testWidgets('typing in consultation notes updates formState without cursor jump',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildLocalizedApp(
          sessionCubit: sessionCubit,
          child: DoctorConsultationScreen(
            visitId: 'VIS-001',
            cubit: visitsCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final complaintField = find.descendant(
        of: find.byType(ConsultationNotesPanel),
        matching: find.byType(TextFormField),
      ).first;
      await tester.enterText(complaintField, 'صداع مستمر منذ يومين');
      await tester.pump();

      expect(visitsCubit.state.formState.chiefComplaint, 'صداع مستمر منذ يومين');

      final editableText = tester.widget<EditableText>(
        find.descendant(of: complaintField, matching: find.byType(EditableText)),
      );
      expect(
        editableText.controller.selection.baseOffset,
        'صداع مستمر منذ يومين'.length,
      );
    });

    testWidgets('actionStatus loading renders progress indicator and disables finalize button',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildLocalizedApp(
          sessionCubit: sessionCubit,
          child: DoctorConsultationScreen(
            visitId: 'VIS-001',
            cubit: visitsCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      visitsCubit.emit(
        visitsCubit.state.copyWith(
          actionStatus: RequestStatusEnum.loading,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final buttons = tester.widgetList<CustomPushButton>(
        find.byType(CustomPushButton),
      );
      final finalizeBtn = buttons.firstWhere(
        (b) => b.backgroundColor == AppColors.primary,
      );
      expect(finalizeBtn.isLoading, isTrue);
      expect(find.byType(CupertinoActivityIndicator), findsWidgets);
    });

    testWidgets('finalize with empty chief complaint or diagnosis shows missing fields error',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildLocalizedApp(
          sessionCubit: sessionCubit,
          child: DoctorConsultationScreen(
            visitId: 'VIS-001',
            cubit: visitsCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear chief complaint
      visitsCubit.updateChiefComplaint('');
      await tester.pumpAndSettle();

      // Tap finalize
      final finalizeBtn = find.text('visits_finalize_visit'.tr());
      expect(finalizeBtn, findsOneWidget);
      await tester.tap(finalizeBtn);
      await tester.pumpAndSettle();

      // Dialog should NOT open because validation prevented it
      expect(find.byType(FinalizeVisitDialog), findsNothing);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('finalize flow: opening dialog and confirming finalizes visit',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildLocalizedApp(
          sessionCubit: sessionCubit,
          child: DoctorConsultationScreen(
            visitId: 'VIS-001',
            cubit: visitsCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure chief complaint and diagnosis are filled
      visitsCubit.updateChiefComplaint('صداع نصفي مستمر');
      visitsCubit.updateDiagnosis('صداع التوتر الحاد');
      await tester.pumpAndSettle();

      // Tap finalize button in header
      final finalizeBtn = find.text('visits_finalize_visit'.tr());
      await tester.tap(finalizeBtn);
      await tester.pumpAndSettle();

      // FinalizeVisitDialog must be displayed
      expect(find.byType(FinalizeVisitDialog), findsOneWidget);
      expect(find.text('visits_finalize_confirm_title'.tr()), findsOneWidget);

      // Confirm in dialog
      final confirmBtn = find.descendant(
        of: find.byType(FinalizeVisitDialog),
        matching: find.text('visits_finalize_visit'.tr()),
      );
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Visit is now finalized, locked notice appears
      expect(find.text('visits_locked_notice'.tr()), findsOneWidget);
      expect(visitsCubit.state.activeVisit?.status, VisitStatusEnum.finalized);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('PopScope flushDraftOnExit is executed on back navigation',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildLocalizedApp(
          sessionCubit: sessionCubit,
          child: DoctorConsultationScreen(
            visitId: 'VIS-001',
            cubit: visitsCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Modify a field to make form dirty
      visitsCubit.updateChiefComplaint('شكوى محدثة قبل الخروج');
      expect(visitsCubit.state.formState.isDirty, isTrue);

      // Trigger back button
      final backBtn = find.byIcon(Icons.arrow_back);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Verify draft was saved in repo
      final updatedVisitRes = await visitsRepo.getVisitById(visitId: 'VIS-001');
      final updatedVisit = updatedVisitRes.getOrElse(() => throw 'Visit not found')!;
      expect(updatedVisit.chiefComplaint, 'شكوى محدثة قبل الخروج');
    });

    testWidgets('ConsultationActionHelper permits assigned doctor for today and rejects other conditions',
        (tester) async {
      final evaluator = sessionCubit.permissionEvaluator;

      // Case A: Today's waiting booking for DOC-01 in branch_1 -> Can start
      final bookingToday = BookingModel(
        id: 'BK-TEST-1',
        branchId: 'branch_1',
        doctorId: 'DOC-01',
        status: BookingStatusEnum.waiting,
        appointmentTime: DateTime(2026, 11, 10, 11, 0),
      );
      expect(
        ConsultationActionHelper.canStartConsultation(
          booking: bookingToday,
          visit: null,
          evaluator: evaluator,
        ),
        isTrue,
      );

      // Case B: Not today -> false
      final bookingYesterday = bookingToday.copyWith(
        appointmentTime: DateTime(2026, 11, 9, 11, 0),
      );
      expect(
        ConsultationActionHelper.canStartConsultation(
          booking: bookingYesterday,
          visit: null,
          evaluator: evaluator,
        ),
        isFalse,
      );

      // Case C: Another doctor -> false
      final bookingOtherDoc = bookingToday.copyWith(
        doctorId: 'DOC-02',
      );
      expect(
        ConsultationActionHelper.canStartConsultation(
          booking: bookingOtherDoc,
          visit: null,
          evaluator: evaluator,
        ),
        isFalse,
      );
    });
  });
}
