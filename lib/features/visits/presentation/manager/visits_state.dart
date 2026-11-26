import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/consultation_queue_item_model.dart';
import '../../data/models/visit_model.dart';
import 'visit_form_state.dart';

class VisitsState extends Equatable {
  final RequestStatusEnum queueStatus;
  final RequestStatusEnum activeVisitStatus;
  final RequestStatusEnum actionStatus;
  final List<ConsultationQueueItemModel> queue;
  final VisitModel? activeVisit;
  final VisitFormState formState;
  final List<String> patientAllergies;
  final List<String> patientChronicDiseases;
  final String? errorMessage;
  final String? filterDoctorId;
  final DateTime? filterDate;
  final bool isAutoSaving;
  final bool autoSaveFailed;
  final bool canEditDiagnosis;
  final bool canViewNotes;

  const VisitsState({
    this.queueStatus = RequestStatusEnum.initial,
    this.activeVisitStatus = RequestStatusEnum.initial,
    this.actionStatus = RequestStatusEnum.initial,
    this.queue = const [],
    this.activeVisit,
    this.formState = const VisitFormState(),
    this.patientAllergies = const [],
    this.patientChronicDiseases = const [],
    this.errorMessage,
    this.filterDoctorId,
    this.filterDate,
    this.isAutoSaving = false,
    this.autoSaveFailed = false,
    this.canEditDiagnosis = false,
    this.canViewNotes = false,
  });

  factory VisitsState.initial() => const VisitsState();

  VisitsState copyWith({
    RequestStatusEnum? queueStatus,
    RequestStatusEnum? activeVisitStatus,
    RequestStatusEnum? actionStatus,
    List<ConsultationQueueItemModel>? queue,
    VisitModel? activeVisit,
    bool clearActiveVisit = false,
    VisitFormState? formState,
    List<String>? patientAllergies,
    List<String>? patientChronicDiseases,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? filterDoctorId,
    bool clearFilterDoctorId = false,
    DateTime? filterDate,
    bool? isAutoSaving,
    bool? autoSaveFailed,
    bool? canEditDiagnosis,
    bool? canViewNotes,
  }) {
    return VisitsState(
      queueStatus: queueStatus ?? this.queueStatus,
      activeVisitStatus: activeVisitStatus ?? this.activeVisitStatus,
      actionStatus: actionStatus ?? this.actionStatus,
      queue: queue ?? this.queue,
      activeVisit: clearActiveVisit ? null : (activeVisit ?? this.activeVisit),
      formState: formState ?? this.formState,
      patientAllergies: patientAllergies ?? this.patientAllergies,
      patientChronicDiseases:
          patientChronicDiseases ?? this.patientChronicDiseases,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      filterDoctorId: clearFilterDoctorId
          ? null
          : (filterDoctorId ?? this.filterDoctorId),
      filterDate: filterDate ?? this.filterDate,
      isAutoSaving: isAutoSaving ?? this.isAutoSaving,
      autoSaveFailed: autoSaveFailed ?? this.autoSaveFailed,
      canEditDiagnosis: canEditDiagnosis ?? this.canEditDiagnosis,
      canViewNotes: canViewNotes ?? this.canViewNotes,
    );
  }

  @override
  List<Object?> get props => [
        queueStatus,
        activeVisitStatus,
        actionStatus,
        queue,
        activeVisit,
        formState,
        patientAllergies,
        patientChronicDiseases,
        errorMessage,
        filterDoctorId,
        filterDate,
        isAutoSaving,
        autoSaveFailed,
        canEditDiagnosis,
        canViewNotes,
      ];
}
