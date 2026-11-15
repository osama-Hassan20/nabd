import 'package:equatable/equatable.dart';
import 'enums/visit_status_enum.dart';
import 'prescription_item_model.dart';
import 'visit_addendum_model.dart';
import 'vitals_model.dart';

class VisitModel extends Equatable {
  final String? id;
  final String? bookingId;
  final String? patientId;
  final String? branchId;
  final String? patientName;
  final String? patientPhone;
  final String? doctorId;
  final String? doctorName;
  final String? specialty;
  final VisitStatusEnum? status;
  final VitalsModel? vitals;
  final String? chiefComplaint;
  final String? medicalHistory;
  final String? physicalExam;
  final String? diagnosis;
  final String? treatmentPlan;
  final String? followUpNotes;
  final int? followUpDays;
  final List<PrescriptionItemModel>? prescriptionItems;
  final List<VisitAddendumModel>? addenda;
  final DateTime? triageAt;
  final DateTime? startedAt;
  final DateTime? finalizedAt;
  final DateTime? lastSavedAt;

  const VisitModel({
    this.id,
    this.bookingId,
    this.patientId,
    this.branchId,
    this.patientName,
    this.patientPhone,
    this.doctorId,
    this.doctorName,
    this.specialty,
    this.status,
    this.vitals,
    this.chiefComplaint,
    this.medicalHistory,
    this.physicalExam,
    this.diagnosis,
    this.treatmentPlan,
    this.followUpNotes,
    this.followUpDays,
    this.prescriptionItems,
    this.addenda,
    this.triageAt,
    this.startedAt,
    this.finalizedAt,
    this.lastSavedAt,
  });

  factory VisitModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VisitModel();
    return VisitModel(
      id: json['id'] as String?,
      bookingId: json['bookingId'] as String?,
      patientId: json['patientId'] as String?,
      branchId: json['branchId'] as String?,
      patientName: json['patientName'] as String?,
      patientPhone: json['patientPhone'] as String?,
      doctorId: json['doctorId'] as String?,
      doctorName: json['doctorName'] as String?,
      specialty: json['specialty'] as String?,
      status: VisitStatusEnum.fromValue(json['status'] as String?),
      vitals: json['vitals'] != null
          ? VitalsModel.fromJson(json['vitals'] as Map<String, dynamic>)
          : null,
      chiefComplaint: json['chiefComplaint'] as String?,
      medicalHistory: json['medicalHistory'] as String?,
      physicalExam: json['physicalExam'] as String?,
      diagnosis: json['diagnosis'] as String?,
      treatmentPlan: json['treatmentPlan'] as String?,
      followUpNotes: json['followUpNotes'] as String?,
      followUpDays: json['followUpDays'] as int?,
      prescriptionItems: json['prescriptionItems'] != null
          ? (json['prescriptionItems'] as List<dynamic>)
              .map((e) =>
                  PrescriptionItemModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      addenda: json['addenda'] != null
          ? (json['addenda'] as List<dynamic>)
              .map((e) =>
                  VisitAddendumModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      triageAt: json['triageAt'] != null
          ? DateTime.tryParse(json['triageAt'] as String)
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      finalizedAt: json['finalizedAt'] != null
          ? DateTime.tryParse(json['finalizedAt'] as String)
          : null,
      lastSavedAt: json['lastSavedAt'] != null
          ? DateTime.tryParse(json['lastSavedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'patientId': patientId,
      'branchId': branchId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'specialty': specialty,
      'status': status?.value,
      'vitals': vitals?.toJson(),
      'chiefComplaint': chiefComplaint,
      'medicalHistory': medicalHistory,
      'physicalExam': physicalExam,
      'diagnosis': diagnosis,
      'treatmentPlan': treatmentPlan,
      'followUpNotes': followUpNotes,
      'followUpDays': followUpDays,
      'prescriptionItems': prescriptionItems?.map((e) => e.toJson()).toList(),
      'addenda': addenda?.map((e) => e.toJson()).toList(),
      'triageAt': triageAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'finalizedAt': finalizedAt?.toIso8601String(),
      'lastSavedAt': lastSavedAt?.toIso8601String(),
    };
  }

  VisitModel copyWith({
    String? id,
    String? bookingId,
    String? patientId,
    String? branchId,
    String? patientName,
    String? patientPhone,
    String? doctorId,
    String? doctorName,
    String? specialty,
    VisitStatusEnum? status,
    VitalsModel? vitals,
    String? chiefComplaint,
    String? medicalHistory,
    String? physicalExam,
    String? diagnosis,
    String? treatmentPlan,
    String? followUpNotes,
    int? followUpDays,
    List<PrescriptionItemModel>? prescriptionItems,
    List<VisitAddendumModel>? addenda,
    DateTime? triageAt,
    DateTime? startedAt,
    DateTime? finalizedAt,
    DateTime? lastSavedAt,
  }) {
    return VisitModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      patientId: patientId ?? this.patientId,
      branchId: branchId ?? this.branchId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      status: status ?? this.status,
      vitals: vitals ?? this.vitals,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      physicalExam: physicalExam ?? this.physicalExam,
      diagnosis: diagnosis ?? this.diagnosis,
      treatmentPlan: treatmentPlan ?? this.treatmentPlan,
      followUpNotes: followUpNotes ?? this.followUpNotes,
      followUpDays: followUpDays ?? this.followUpDays,
      prescriptionItems: prescriptionItems ?? this.prescriptionItems,
      addenda: addenda ?? this.addenda,
      triageAt: triageAt ?? this.triageAt,
      startedAt: startedAt ?? this.startedAt,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        patientId,
        branchId,
        patientName,
        patientPhone,
        doctorId,
        doctorName,
        specialty,
        status,
        vitals,
        chiefComplaint,
        medicalHistory,
        physicalExam,
        diagnosis,
        treatmentPlan,
        followUpNotes,
        followUpDays,
        prescriptionItems,
        addenda,
        triageAt,
        startedAt,
        finalizedAt,
        lastSavedAt,
      ];
}
