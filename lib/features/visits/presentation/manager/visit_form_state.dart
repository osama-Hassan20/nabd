import 'package:equatable/equatable.dart';
import '../../data/models/prescription_item_model.dart';
import '../../data/models/visit_addendum_model.dart';
import '../../data/models/visit_model.dart';
import '../../data/models/vitals_model.dart';

class VisitFormState extends Equatable {
  final String? chiefComplaint;
  final String? medicalHistory;
  final String? physicalExam;
  final String? diagnosis;
  final String? treatmentPlan;
  final String? followUpNotes;
  final int? followUpDays;
  final VitalsModel vitals;
  final List<PrescriptionItemModel>? prescriptionItems;
  final List<VisitAddendumModel>? addenda;
  final PrescriptionItemModel? editingItem;
  final bool isAllergyWarningDismissed;
  final bool isDirty;
  final bool isSaving;
  final DateTime? lastSavedAt;

  const VisitFormState({
    this.chiefComplaint,
    this.medicalHistory,
    this.physicalExam,
    this.diagnosis,
    this.treatmentPlan,
    this.followUpNotes,
    this.followUpDays,
    this.vitals = const VitalsModel(),
    this.prescriptionItems,
    this.addenda,
    this.editingItem,
    this.isAllergyWarningDismissed = false,
    this.isDirty = false,
    this.isSaving = false,
    this.lastSavedAt,
  });

  factory VisitFormState.fromVisit(VisitModel? visit) {
    if (visit == null) return const VisitFormState();
    return VisitFormState(
      chiefComplaint: visit.chiefComplaint,
      medicalHistory: visit.medicalHistory,
      physicalExam: visit.physicalExam,
      diagnosis: visit.diagnosis,
      treatmentPlan: visit.treatmentPlan,
      followUpNotes: visit.followUpNotes,
      followUpDays: visit.followUpDays,
      vitals: visit.vitals ?? const VitalsModel(),
      prescriptionItems: visit.prescriptionItems,
      addenda: visit.addenda,
      editingItem: null,
      isAllergyWarningDismissed: false,
      isDirty: false,
      isSaving: false,
      lastSavedAt: visit.lastSavedAt,
    );
  }

  VisitModel toVisitModel(VisitModel baseVisit) {
    return baseVisit.copyWith(
      chiefComplaint: chiefComplaint,
      medicalHistory: medicalHistory,
      physicalExam: physicalExam,
      diagnosis: diagnosis,
      treatmentPlan: treatmentPlan,
      followUpNotes: followUpNotes,
      followUpDays: followUpDays,
      vitals: vitals,
      prescriptionItems: prescriptionItems,
      addenda: addenda,
      lastSavedAt: lastSavedAt,
    );
  }

  VisitFormState copyWith({
    String? chiefComplaint,
    String? medicalHistory,
    String? physicalExam,
    String? diagnosis,
    String? treatmentPlan,
    String? followUpNotes,
    int? followUpDays,
    VitalsModel? vitals,
    List<PrescriptionItemModel>? prescriptionItems,
    List<VisitAddendumModel>? addenda,
    PrescriptionItemModel? editingItem,
    bool clearEditingItem = false,
    bool? isAllergyWarningDismissed,
    bool? isDirty,
    bool? isSaving,
    DateTime? lastSavedAt,
  }) {
    return VisitFormState(
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      physicalExam: physicalExam ?? this.physicalExam,
      diagnosis: diagnosis ?? this.diagnosis,
      treatmentPlan: treatmentPlan ?? this.treatmentPlan,
      followUpNotes: followUpNotes ?? this.followUpNotes,
      followUpDays: followUpDays ?? this.followUpDays,
      vitals: vitals ?? this.vitals,
      prescriptionItems: prescriptionItems ?? this.prescriptionItems,
      addenda: addenda ?? this.addenda,
      editingItem: clearEditingItem ? null : (editingItem ?? this.editingItem),
      isAllergyWarningDismissed:
          isAllergyWarningDismissed ?? this.isAllergyWarningDismissed,
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }

  @override
  List<Object?> get props => [
        chiefComplaint,
        medicalHistory,
        physicalExam,
        diagnosis,
        treatmentPlan,
        followUpNotes,
        followUpDays,
        vitals,
        prescriptionItems,
        addenda,
        editingItem,
        isAllergyWarningDismissed,
        isDirty,
        isSaving,
        lastSavedAt,
      ];
}
