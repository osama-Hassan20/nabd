import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/patients/data/repo/patients_mock_repo_impl.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/models/vitals_model.dart';
import 'package:eyadty/features/visits/data/repo/visits_mock_repo_impl.dart';
import 'package:eyadty/features/visits/domain/use_cases/finalize_visit_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/get_doctor_queue_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/get_visit_by_booking_id_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/record_vitals_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/save_visit_draft_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/start_consultation_use_case.dart';
import 'package:eyadty/features/visits/presentation/manager/visits_cubit.dart';

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
  late BookingsMockRepoImpl bookingsRepo;
  late VisitsMockRepoImpl visitsRepo;
  late PatientsMockRepoImpl patientsRepo;
  late InMemoryAuditLogger auditLogger;
  late MockUserSessionProvider userProvider;
  late MockRolesSessionProvider rolesProvider;
  late PermissionEvaluator permissionEvaluator;

  late GetDoctorQueueUseCase getDoctorQueueUseCase;
  late GetVisitByBookingIdUseCase getVisitByBookingIdUseCase;
  late StartConsultationUseCase startConsultationUseCase;
  late SaveVisitDraftUseCase saveVisitDraftUseCase;
  late RecordVitalsUseCase recordVitalsUseCase;
  late FinalizeVisitUseCase finalizeVisitUseCase;

  late VisitsCubit cubit;

  setUp(() {
    bookingsRepo = BookingsMockRepoImpl();
    visitsRepo = VisitsMockRepoImpl(bookingsRepo: bookingsRepo);
    patientsRepo = PatientsMockRepoImpl();
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

    rolesProvider = MockRolesSessionProvider(
      roles: RoleDefinitionModel.defaultSystemRoles(),
    );
    userProvider = MockUserSessionProvider();
    permissionEvaluator = PermissionEvaluator(
      userProvider: userProvider,
      rolesProvider: rolesProvider,
    );

    getDoctorQueueUseCase = GetDoctorQueueUseCase(repo: visitsRepo);
    getVisitByBookingIdUseCase = GetVisitByBookingIdUseCase(repo: visitsRepo);
    startConsultationUseCase = StartConsultationUseCase(
      visitsRepo: visitsRepo,
      bookingsRepo: bookingsRepo,
      permissionEvaluator: permissionEvaluator,
      auditLogger: auditLogger,
    );
    saveVisitDraftUseCase = SaveVisitDraftUseCase(
      repo: visitsRepo,
      permissionEvaluator: permissionEvaluator,
    );
    recordVitalsUseCase = RecordVitalsUseCase(
      visitsRepo: visitsRepo,
      bookingsRepo: bookingsRepo,
      permissionEvaluator: permissionEvaluator,
      auditLogger: auditLogger,
    );
    finalizeVisitUseCase = FinalizeVisitUseCase(
      visitsRepo: visitsRepo,
      bookingsRepo: bookingsRepo,
      permissionEvaluator: permissionEvaluator,
      auditLogger: auditLogger,
    );

    // Default: Doctor DOC-01
    userProvider.user = const StaffUserModel(
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

    cubit = VisitsCubit(
      visitsRepo: visitsRepo,
      bookingsRepo: bookingsRepo,
      patientsRepo: patientsRepo,
      getDoctorQueueUseCase: getDoctorQueueUseCase,
      getVisitByBookingIdUseCase: getVisitByBookingIdUseCase,
      startConsultationUseCase: startConsultationUseCase,
      saveVisitDraftUseCase: saveVisitDraftUseCase,
      recordVitalsUseCase: recordVitalsUseCase,
      finalizeVisitUseCase: finalizeVisitUseCase,
      permissionEvaluator: permissionEvaluator,
      auditLogger: auditLogger,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('VisitsCubit Queue & Role Loading Tests', () {
    test('T1: loadDoctorQueue for Doctor automatically filters by session.linkedDoctorId', () async {
      await cubit.loadDoctorQueue();

      expect(cubit.state.queueStatus, RequestStatusEnum.success);
      expect(cubit.state.filterDoctorId, 'DOC-01');
      for (final item in cubit.state.queue) {
        final matches = item.booking?.doctorId == 'DOC-01' ||
            (item.booking?.technicians.any((t) => t.id == 'DOC-01') ?? false);
        expect(matches, isTrue);
      }
    });

    test('T2: loadDoctorQueue for Admin / Owner returns all doctors in branch', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-OWNER',
        fullName: 'المالك',
        isActive: true,
        isOwner: true,
      );

      await cubit.loadDoctorQueue();

      expect(cubit.state.queueStatus, RequestStatusEnum.success);
      expect(cubit.state.filterDoctorId, isNull);
      expect(cubit.state.queue, isNotEmpty);
      // Contains bookings for various doctors
      final doctorIds = cubit.state.queue.map((i) => i.booking?.doctorId).toSet();
      expect(doctorIds.length, greaterThan(1));
    });
  });

  group('VisitsCubit Active Visit Loading & Sensitivity Guard Tests', () {
    test('T3: loadActiveVisit resets formState and activeVisit before loading', () async {
      // Modify formState first
      cubit.updateDiagnosis('تشخيص قديم');
      expect(cubit.state.formState.isDirty, isTrue);

      // Now load VIS-001
      await cubit.loadActiveVisit('VIS-001');

      expect(cubit.state.activeVisitStatus, RequestStatusEnum.success);
      expect(cubit.state.activeVisit?.id, 'VIS-001');
      // Reset occurred and was populated fresh from VIS-001
      expect(cubit.state.formState.isDirty, isFalse);
    });

    test('T4: loadActiveVisit for Nurse rejects loading (requires viewConsultationNotes)', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-NURSE-01',
        fullName: 'ممرضة فاطمة',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.nurse],
          ),
        ],
      );

      await cubit.loadActiveVisit('VIS-001');

      expect(cubit.state.activeVisitStatus, RequestStatusEnum.failure);
      expect(cubit.state.errorMessage, 'permission_denied_view_consultation_notes');
      expect(cubit.state.activeVisit, isNull);
    });

    test('T5: loadActiveVisit loads only allergies and chronicDiseases without full PatientModel', () async {
      await cubit.loadActiveVisit('VIS-001');

      expect(cubit.state.activeVisitStatus, RequestStatusEnum.success);
      expect(cubit.state.patientAllergies, isA<List<String>>());
      expect(cubit.state.patientChronicDiseases, isA<List<String>>());
    });

    test('T6: loadActiveVisit emits view_patient_medical_record and NOT view_patient_profile', () async {
      await cubit.loadActiveVisit('VIS-001');

      // view_patient_medical_record was emitted
      final medRecordLogs = auditLogger.getLogs(eventType: 'view_patient_medical_record');
      expect(medRecordLogs.length, 1);
      expect(medRecordLogs.first.details, contains('visitId=VIS-001'));
      expect(medRecordLogs.first.details, contains('patientId=PAT-000101'));

      // STRICT: view_patient_profile was NOT emitted
      final profileLogs = auditLogger.getLogs(eventType: 'view_patient_profile');
      expect(profileLogs, isEmpty);
    });

    test('T7: loadPatientAllergies for Nurse loads only allergies without chronic diseases', () async {
      await cubit.loadPatientAllergies('PAT-000101');

      expect(cubit.state.patientAllergies, isNotEmpty);
      expect(cubit.state.patientChronicDiseases, isEmpty);
    });
  });

  group('VisitsCubit Auto-Save & Flush Tests', () {
    test('T8: autoSaveDraft does not call repo if isDirty == false', () async {
      await cubit.loadActiveVisit('VIS-001');
      expect(cubit.state.formState.isDirty, isFalse);

      final lastSavedBefore = cubit.state.activeVisit?.lastSavedAt;
      await cubit.autoSaveDraft();

      // No save was triggered
      expect(cubit.state.isAutoSaving, isFalse);
      expect(cubit.state.activeVisit?.lastSavedAt, lastSavedBefore);
    });

    test('T9: autoSaveDraft does not call repo if visit status is finalized', () async {
      // VIS-002 is finalized
      await cubit.loadActiveVisit('VIS-002');
      expect(cubit.state.activeVisit?.status, VisitStatusEnum.finalized);

      cubit.updateDiagnosis('تعديل بعد الإغلاق');
      expect(cubit.state.formState.isDirty, isTrue);

      await cubit.autoSaveDraft();
      expect(cubit.state.isAutoSaving, isFalse);
      // Status remains finalized and un-mutated
      expect(cubit.state.activeVisit?.status, VisitStatusEnum.finalized);
    });

    test('T10: autoSaveDraft prevents concurrent executions', () async {
      await cubit.loadActiveVisit('VIS-001');
      cubit.updateDiagnosis('تشخيص جديد 1');

      // Trigger first autoSave and immediately trigger another
      final future1 = cubit.autoSaveDraft();
      final future2 = cubit.autoSaveDraft();

      await Future.wait([future1, future2]);
      expect(cubit.state.formState.isDirty, isFalse);
    });

    test('T11: autoSaveDraft on success sets isDirty = false and updates lastSavedAt', () async {
      await cubit.loadActiveVisit('VIS-001');
      cubit.updateDiagnosis('تشخيص محدث للصداع');
      expect(cubit.state.formState.isDirty, isTrue);

      await cubit.autoSaveDraft();

      expect(cubit.state.formState.isDirty, isFalse);
      expect(cubit.state.activeVisit?.diagnosis, 'تشخيص محدث للصداع');
      expect(cubit.state.activeVisit?.lastSavedAt, isNotNull);
    });

    test('T12: autosave result arriving after finalize is ignored', () async {
      await cubit.loadActiveVisit('VIS-001');
      cubit.updateDiagnosis('مسودة أخيرة');

      // Finalize the visit
      await cubit.finalizeVisit();
      expect(cubit.state.activeVisit?.status, VisitStatusEnum.finalized);

      // Even if autoSaveDraft is invoked, it is skipped
      await cubit.autoSaveDraft();
      expect(cubit.state.activeVisit?.status, VisitStatusEnum.finalized);
    });

    test('T13: flushDraftOnExit saves draft if isDirty == true and visit is not finalized', () async {
      await cubit.loadActiveVisit('VIS-001');
      cubit.updateTreatmentPlan('علاج جديد عند المغادرة');
      expect(cubit.state.formState.isDirty, isTrue);

      await cubit.flushDraftOnExit();

      // Check visit in repo was updated
      final visitInRepo = await visitsRepo.getVisitByBookingId(bookingId: 'MED-101');
      expect(
        visitInRepo.getOrElse(() => null)?.treatmentPlan,
        'علاج جديد عند المغادرة',
      );
      expect(cubit.hasActiveTimer, isFalse);
    });

    test('T14: startAutoSave and stopAutoSave manage timer lifecycle, and close cancels timer', () async {
      await cubit.loadActiveVisit('VIS-001');
      expect(cubit.hasActiveTimer, isTrue);

      cubit.stopAutoSave();
      expect(cubit.hasActiveTimer, isFalse);

      cubit.startAutoSave();
      expect(cubit.hasActiveTimer, isTrue);

      await cubit.close();
      expect(cubit.hasActiveTimer, isFalse);
    });

    test('T15: finalizeVisit stops autoSave, updates status to finalized, and updates queue', () async {
      await cubit.loadActiveVisit('VIS-001');
      expect(cubit.hasActiveTimer, isTrue);

      final success = await cubit.finalizeVisit();
      expect(success, isTrue);
      expect(cubit.state.actionStatus, RequestStatusEnum.success);
      expect(cubit.state.activeVisit?.status, VisitStatusEnum.finalized);
      expect(cubit.hasActiveTimer, isFalse);
    });
  });

  group('VisitsCubit Form Field Modifiers Tests', () {
    test('updating fields marks form dirty and updates formState', () {
      cubit.updateChiefComplaint('شكوى');
      expect(cubit.state.formState.chiefComplaint, 'شكوى');
      expect(cubit.state.formState.isDirty, isTrue);

      cubit.updateMedicalHistory('تاريخ');
      expect(cubit.state.formState.medicalHistory, 'تاريخ');

      cubit.updatePhysicalExam('فحص');
      expect(cubit.state.formState.physicalExam, 'فحص');

      cubit.updateTreatmentPlan('خطة');
      expect(cubit.state.formState.treatmentPlan, 'خطة');

      cubit.updateFollowUpNotes('ملاحظات');
      expect(cubit.state.formState.followUpNotes, 'ملاحظات');

      cubit.updateFollowUpDays(5);
      expect(cubit.state.formState.followUpDays, 5);

      cubit.updateVitals(const VitalsModel(systolicBp: 130));
      expect(cubit.state.formState.vitals.systolicBp, 130);
    });
  });
}
