import 'dart:async';
import '../../../../../core/base/safe_cubit.dart';
import '../../../../../core/enums/staff_permission_enum.dart';
import '../../../../../core/services/audit_logger.dart';
import '../../../../../core/services/permission_evaluator.dart';
import '../../../../../core/utils/enums/request_status_enum.dart';
import '../../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../../patients/domain/repo/patients_repo.dart';
import '../../../data/models/enums/visit_status_enum.dart';
import '../../../data/models/visit_model.dart';
import '../../../data/repo/visits_mock_repo_impl.dart';
import '../../../domain/repo/visits_repo.dart';
import '../../../domain/use_cases/finalize_visit_use_case.dart';
import '../../../domain/use_cases/save_visit_draft_use_case.dart';
import '../visit_form_state.dart';
import '../visits_state.dart';

mixin VisitConsultationMixin on SafeCubit<VisitsState> {
  VisitsRepo get visitsRepo;
  PatientsRepo get patientsRepo;
  PermissionEvaluator get permissionEvaluator;
  AuditLogger? get auditLogger;
  SaveVisitDraftUseCase get saveVisitDraftUseCase;
  FinalizeVisitUseCase get finalizeVisitUseCase;
  Timer Function(Duration duration, void Function() callback)? get timerFactory;
  Future<void> loadDoctorQueue({String? doctorId, String? branchId, DateTime? date});

  Timer? _autoSaveTimer;
  String? _lastAuditedVisitId;

  bool get hasActiveTimer => _autoSaveTimer != null && _autoSaveTimer!.isActive;

  void resetLastAuditedVisitId() {
    _lastAuditedVisitId = null;
  }

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

  Future<bool> saveDraft() async {
    final active = state.activeVisit;
    if (active == null) return false;
    if (active.status == VisitStatusEnum.finalized) return false;

    final canEdit = permissionEvaluator.can(
      StaffPermissionEnum.editMedicalDiagnosis,
      branchId: active.branchId,
      patientDoctorIds: active.doctorId != null ? {active.doctorId!} : null,
    );
    if (!canEdit) return false;

    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final draft = state.formState.toVisitModel(active);
    final res = await saveVisitDraftUseCase(draft);

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
      (saved) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            activeVisit: saved,
            formState: state.formState.copyWith(
              isDirty: false,
              lastSavedAt: saved.lastSavedAt,
            ),
          ),
        );
        return true;
      },
    );
  }

  Future<void> flushDraftOnExit() async {
    stopAutoSave();
    _lastAuditedVisitId = null;
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
