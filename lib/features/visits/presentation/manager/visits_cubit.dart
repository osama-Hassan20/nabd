import 'dart:async';
import '../../../../core/base/safe_cubit.dart';
import '../../../../core/cubits/session_cubit.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../bookings/domain/repo/bookings_repo.dart';
import '../../../patients/domain/repo/patients_repo.dart';
import '../../data/models/consultation_queue_item_model.dart';
import '../../data/models/enums/visit_status_enum.dart';
import '../../data/models/visit_model.dart';
import '../../data/models/vitals_model.dart';
import '../../data/repo/visits_mock_repo_impl.dart';
import '../../domain/repo/visits_repo.dart';
import '../../domain/use_cases/finalize_visit_use_case.dart';
import '../../domain/use_cases/get_doctor_queue_use_case.dart';
import '../../domain/use_cases/get_visit_by_booking_id_use_case.dart';
import '../../domain/use_cases/record_vitals_use_case.dart';
import '../../domain/use_cases/save_visit_draft_use_case.dart';
import '../../domain/use_cases/start_consultation_use_case.dart';
import 'visit_form_state.dart';
import 'visits_state.dart';

class VisitsCubit extends SafeCubit<VisitsState> {
  final VisitsRepo visitsRepo;
  final BookingsRepo bookingsRepo;
  final PatientsRepo patientsRepo;
  final GetDoctorQueueUseCase getDoctorQueueUseCase;
  final GetVisitByBookingIdUseCase getVisitByBookingIdUseCase;
  final StartConsultationUseCase startConsultationUseCase;
  final SaveVisitDraftUseCase saveVisitDraftUseCase;
  final RecordVitalsUseCase recordVitalsUseCase;
  final FinalizeVisitUseCase finalizeVisitUseCase;
  final PermissionEvaluator permissionEvaluator;
  final AuditLogger? auditLogger;
  final SessionCubit? sessionCubit;
  final Timer Function(Duration duration, void Function() callback)?
      timerFactory;

  Timer? _autoSaveTimer;
  StreamSubscription<SessionState>? _sessionSubscription;
  String? _lastAuditedVisitId;

  VisitsCubit({
    required this.visitsRepo,
    required this.bookingsRepo,
    required this.patientsRepo,
    required this.getDoctorQueueUseCase,
    required this.getVisitByBookingIdUseCase,
    required this.startConsultationUseCase,
    required this.saveVisitDraftUseCase,
    required this.recordVitalsUseCase,
    required this.finalizeVisitUseCase,
    required this.permissionEvaluator,
    this.auditLogger,
    this.sessionCubit,
    this.timerFactory,
  }) : super(VisitsState.initial()) {
    _sessionSubscription = sessionCubit?.stream.listen((_) {
      refreshPermissions();
    });
  }

  bool get hasActiveTimer => _autoSaveTimer != null && _autoSaveTimer!.isActive;

  void startAutoSave() {
    stopAutoSave();
    final createTimer =
        timerFactory ?? ((d, cb) => Timer.periodic(d, (_) => cb()));
    _autoSaveTimer = createTimer(const Duration(seconds: 30), () {
      autoSaveDraft();
    });
  }

  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  void refreshPermissions() {
    final visit = state.activeVisit;
    final canViewNotes = permissionEvaluator.can(
      StaffPermissionEnum.viewConsultationNotes,
    );
    final canEditDiagnosis = visit != null &&
        visit.status != VisitStatusEnum.finalized &&
        permissionEvaluator.can(
          StaffPermissionEnum.editMedicalDiagnosis,
          branchId: visit.branchId,
          patientDoctorIds: visit.doctorId != null ? {visit.doctorId!} : null,
        );
    emit(state.copyWith(
      canViewNotes: canViewNotes,
      canEditDiagnosis: canEditDiagnosis,
    ));
  }

  void clearActiveVisit() {
    stopAutoSave();
    _lastAuditedVisitId = null;
    emit(state.copyWith(
      clearActiveVisit: true,
      formState: const VisitFormState(),
      patientAllergies: const [],
      patientChronicDiseases: const [],
    ));
  }

  @override
  Future<void> close() {
    stopAutoSave();
    _sessionSubscription?.cancel();
    return super.close();
  }

  // ─── Queue Loading ─────────────────────────────────────────────────────────

  Future<void> loadDoctorQueue({
    String? doctorId,
    String? branchId,
    DateTime? date,
  }) async {
    final currentUser = permissionEvaluator.userProvider.currentUser;
    final targetBranch = branchId ??
        permissionEvaluator.userProvider.activeBranchId ??
        'branch_1';
    final targetDate = date ?? state.filterDate ?? CairoTimeHelper.now();

    String? effectiveDoctorId;
    if (currentUser != null &&
        currentUser.isPracticingDoctor &&
        currentUser.isOwner != true) {
      effectiveDoctorId = currentUser.linkedDoctorId;
    } else {
      effectiveDoctorId = doctorId ?? state.filterDoctorId;
    }

    emit(
      state.copyWith(
        queueStatus: RequestStatusEnum.loading,
        filterDoctorId: effectiveDoctorId,
        clearFilterDoctorId: effectiveDoctorId == null,
        filterDate: targetDate,
      ),
    );

    final res = await getDoctorQueueUseCase(
      GetDoctorQueueParams(
        doctorId: effectiveDoctorId,
        branchId: targetBranch,
        date: targetDate,
      ),
    );

    res.fold(
      (failure) {
        emit(
          state.copyWith(
            queueStatus: RequestStatusEnum.failure,
            errorMessage: failure.errMessage,
          ),
        );
      },
      (queue) {
        emit(
          state.copyWith(
            queueStatus: RequestStatusEnum.success,
            queue: queue,
            clearErrorMessage: true,
          ),
        );
      },
    );
  }

  void setFilterDoctorId(String? doctorId) {
    loadDoctorQueue(doctorId: doctorId);
  }

  void setFilterDate(DateTime date) {
    loadDoctorQueue(date: date);
  }

  // ─── Active Visit Loading & Sensitivity Guard ─────────────────────────────

  Future<void> loadActiveVisit(String visitId) async {
    // 1. RBAC Guard: Requires viewConsultationNotes (Nurse NEVER loads activeVisit)
    final canViewNotes = permissionEvaluator.can(
      StaffPermissionEnum.viewConsultationNotes,
    );
    if (!canViewNotes) {
      emit(
        state.copyWith(
          activeVisitStatus: RequestStatusEnum.failure,
          errorMessage: 'permission_denied_view_consultation_notes',
        ),
      );
      return;
    }

    // 2. State Reset before loading new consultation
    stopAutoSave();
    emit(
      state.copyWith(
        activeVisitStatus: RequestStatusEnum.loading,
        clearActiveVisit: true,
        formState: const VisitFormState(),
        patientAllergies: const [],
        patientChronicDiseases: const [],
        clearErrorMessage: true,
      ),
    );

    // 3. Find visit
    VisitModel? visit;
    if (visitsRepo is VisitsMockRepoImpl) {
      visit = (visitsRepo as VisitsMockRepoImpl)
          .visits
          .where((v) => v.id == visitId)
          .firstOrNull;
    } else {
      visit = state.queue.where((i) => i.visitId == visitId).firstOrNull?.visit;
    }

    if (visit == null) {
      emit(
        state.copyWith(
          activeVisitStatus: RequestStatusEnum.failure,
          errorMessage: 'visit_not_found',
        ),
      );
      return;
    }

    // 4. Load Patient Sensitivity (Allergies + Chronic Diseases without full PatientModel)
    List<String> allergies = [];
    List<String> chronicDiseases = [];
    if (visit.patientId != null) {
      final patientRes =
          await patientsRepo.getPatientById(id: visit.patientId!);
      patientRes.fold(
        (failure) => null,
        (patient) {
          allergies = patient.allergies ?? [];
          if (canViewNotes) {
            chronicDiseases = patient.chronicDiseases ?? [];
          }
        },
      );
    }

    // 5. Audit Logging for Opening Consultation Record (IDs only: visitId, patientId)
    // Only log once per open (do not duplicate on refresh/rebuild with same visitId)
    if (_lastAuditedVisitId != visit.id) {
      _lastAuditedVisitId = visit.id;
      auditLogger?.log(
        eventType: 'view_patient_medical_record',
        performedByUserId: permissionEvaluator.userProvider.currentUser?.id,
        performedByUserName:
            permissionEvaluator.userProvider.currentUser?.fullName,
        branchId: visit.branchId,
        details: 'visitId=${visit.id}, patientId=${visit.patientId}',
      );
    }

    // 6. Check Clinical Edit Permission
    final canEdit = permissionEvaluator.can(
      StaffPermissionEnum.editMedicalDiagnosis,
      branchId: visit.branchId,
      patientDoctorIds: visit.doctorId != null ? {visit.doctorId!} : null,
    );

    final form = VisitFormState.fromVisit(visit);

    emit(
      state.copyWith(
        activeVisitStatus: RequestStatusEnum.success,
        activeVisit: visit,
        formState: form,
        patientAllergies: allergies,
        patientChronicDiseases: chronicDiseases,
        canViewNotes: canViewNotes,
        canEditDiagnosis: canEdit,
        clearErrorMessage: true,
      ),
    );

    // 7. Auto-save trigger
    if (visit.status != VisitStatusEnum.finalized && canEdit) {
      startAutoSave();
    }
  }

  // ─── Patient Allergies for Queue Row / Nurse Dialog ────────────────────────

  Future<void> loadPatientAllergies(String patientId) async {
    final patientRes = await patientsRepo.getPatientById(id: patientId);
    patientRes.fold(
      (failure) => null,
      (patient) {
        emit(
          state.copyWith(
            patientAllergies: patient.allergies ?? const [],
          ),
        );
      },
    );
  }

  // ─── Form State Updates ───────────────────────────────────────────────────

  void updateChiefComplaint(String val) {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          chiefComplaint: val,
          isDirty: true,
        ),
      ),
    );
  }

  void updateMedicalHistory(String val) {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          medicalHistory: val,
          isDirty: true,
        ),
      ),
    );
  }

  void updatePhysicalExam(String val) {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          physicalExam: val,
          isDirty: true,
        ),
      ),
    );
  }

  void updateDiagnosis(String val) {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          diagnosis: val,
          isDirty: true,
        ),
      ),
    );
  }

  void updateTreatmentPlan(String val) {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          treatmentPlan: val,
          isDirty: true,
        ),
      ),
    );
  }

  void updateFollowUpNotes(String val) {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          followUpNotes: val,
          isDirty: true,
        ),
      ),
    );
  }

  void updateFollowUpDays(int? val) {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          followUpDays: val,
          isDirty: true,
        ),
      ),
    );
  }

  void updateVitals(VitalsModel vitals) {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          vitals: vitals,
          isDirty: true,
        ),
      ),
    );
  }

  // ─── Auto-Save Engine ─────────────────────────────────────────────────────

  Future<void> autoSaveDraft() async {
    final active = state.activeVisit;
    if (active == null) return;
    if (!state.formState.isDirty) return;
    if (active.status == VisitStatusEnum.finalized) return;
    if (state.isAutoSaving) return;

    final canEdit = permissionEvaluator.can(
      StaffPermissionEnum.editMedicalDiagnosis,
      branchId: active.branchId,
      patientDoctorIds: active.doctorId != null ? {active.doctorId!} : null,
    );
    if (!canEdit) return;

    emit(state.copyWith(isAutoSaving: true));

    final draft = state.formState.toVisitModel(active);
    final res = await saveVisitDraftUseCase(draft);

    // If visit was finalized while request was in-flight, ignore response
    if (state.activeVisit?.status == VisitStatusEnum.finalized) {
      emit(state.copyWith(isAutoSaving: false));
      return;
    }

    res.fold(
      (failure) {
        emit(state.copyWith(isAutoSaving: false));
      },
      (saved) {
        emit(
          state.copyWith(
            isAutoSaving: false,
            activeVisit: saved,
            formState: state.formState.copyWith(
              isDirty: false,
              lastSavedAt: saved.lastSavedAt,
            ),
          ),
        );
      },
    );
  }

  Future<void> flushDraftOnExit() async {
    stopAutoSave();
    final active = state.activeVisit;
    if (active != null &&
        state.formState.isDirty &&
        active.status != VisitStatusEnum.finalized) {
      final draft = state.formState.toVisitModel(active);
      await saveVisitDraftUseCase(draft);
      if (!isClosed) {
        emit(
          state.copyWith(
            formState: state.formState.copyWith(
              isDirty: false,
              lastSavedAt: CairoTimeHelper.now(),
            ),
          ),
        );
      }
    }
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void initRecordVitals(ConsultationQueueItemModel item) {
    final existingVitals = item.visit?.vitals ?? const VitalsModel();
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          vitals: existingVitals,
          isDirty: false,
        ),
        patientAllergies: const [],
      ),
    );
    if (item.booking?.patientId != null) {
      loadPatientAllergies(item.booking!.patientId!);
    }
  }

  Future<bool> saveRecordedVitals(ConsultationQueueItemModel item) async {
    final booking = item.booking;
    if (booking == null) return false;

    return recordVitals(
      bookingId: booking.id ?? '',
      patientId: booking.patientId ?? '',
      branchId: booking.branchId ?? 'branch_1',
      patientName: booking.patientName ?? '',
      patientPhone: booking.patientPhone,
      doctorId: booking.doctorId ?? '',
      doctorName: booking.doctorName ?? '',
      specialty: booking.specialty,
      vitals: state.formState.vitals,
    );
  }

  Future<VisitModel?> startConsultation(ConsultationQueueItemModel item) async {
    final booking = item.booking;
    if (booking == null) return null;

    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final res = await startConsultationUseCase(
      StartConsultationParams(
        bookingId: booking.id ?? '',
        patientId: booking.patientId ?? '',
        branchId: booking.branchId ?? 'branch_1',
        patientName: booking.patientName ?? '',
        patientPhone: booking.patientPhone,
        doctorId: booking.doctorId ?? '',
        doctorName: booking.doctorName ?? '',
        specialty: booking.specialty,
      ),
    );

    return res.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errorMessage: failure.errMessage,
          ),
        );
        return null;
      },
      (startedVisit) {
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        loadDoctorQueue();
        return startedVisit;
      },
    );
  }

  Future<bool> recordVitals({
    required String bookingId,
    required String patientId,
    required String branchId,
    required String patientName,
    String? patientPhone,
    required String doctorId,
    required String doctorName,
    String? specialty,
    required VitalsModel vitals,
  }) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final res = await recordVitalsUseCase(
      RecordVitalsParams(
        bookingId: bookingId,
        patientId: patientId,
        branchId: branchId,
        patientName: patientName,
        patientPhone: patientPhone,
        doctorId: doctorId,
        doctorName: doctorName,
        specialty: specialty,
        vitals: vitals,
      ),
    );

    return res.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errorMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (visit) {
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        loadDoctorQueue();
        return true;
      },
    );
  }

  Future<bool> finalizeVisit() async {
    final active = state.activeVisit;
    if (active == null) return false;

    stopAutoSave();

    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final finalModel = state.formState.toVisitModel(active);
    final res = await finalizeVisitUseCase(finalModel);

    return res.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errorMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (finalized) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            activeVisit: finalized,
            formState: state.formState.copyWith(
              isDirty: false,
              lastSavedAt: finalized.lastSavedAt,
            ),
          ),
        );
        loadDoctorQueue();
        return true;
      },
    );
  }
}
