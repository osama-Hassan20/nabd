import 'package:equatable/equatable.dart';

class DoctorPerformanceMetricModel extends Equatable {
  final String? doctorId;
  final String? doctorName;
  final String? specialty;
  final int? visitsCount;
  final int? revenueGeneratedPiastres;
  final int? doctorCommissionPiastres;
  final int? clinicSharePiastres;
  final int? avgConsultationDurationMinutes;
  final double? patientSatisfactionRating;

  const DoctorPerformanceMetricModel({
    this.doctorId,
    this.doctorName,
    this.specialty,
    this.visitsCount,
    this.revenueGeneratedPiastres,
    this.doctorCommissionPiastres,
    this.clinicSharePiastres,
    this.avgConsultationDurationMinutes,
    this.patientSatisfactionRating,
  });

  DoctorPerformanceMetricModel copyWith({
    String? doctorId,
    String? doctorName,
    String? specialty,
    int? visitsCount,
    int? revenueGeneratedPiastres,
    int? doctorCommissionPiastres,
    int? clinicSharePiastres,
    int? avgConsultationDurationMinutes,
    double? patientSatisfactionRating,
  }) {
    return DoctorPerformanceMetricModel(
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      visitsCount: visitsCount ?? this.visitsCount,
      revenueGeneratedPiastres: revenueGeneratedPiastres ?? this.revenueGeneratedPiastres,
      doctorCommissionPiastres: doctorCommissionPiastres ?? this.doctorCommissionPiastres,
      clinicSharePiastres: clinicSharePiastres ?? this.clinicSharePiastres,
      avgConsultationDurationMinutes: avgConsultationDurationMinutes ?? this.avgConsultationDurationMinutes,
      patientSatisfactionRating: patientSatisfactionRating ?? this.patientSatisfactionRating,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'doctorName': doctorName,
      'specialty': specialty,
      'visitsCount': visitsCount,
      'revenueGeneratedPiastres': revenueGeneratedPiastres,
      'doctorCommissionPiastres': doctorCommissionPiastres,
      'clinicSharePiastres': clinicSharePiastres,
      'avgConsultationDurationMinutes': avgConsultationDurationMinutes,
      'patientSatisfactionRating': patientSatisfactionRating,
    };
  }

  factory DoctorPerformanceMetricModel.fromMap(Map<String, dynamic> map) {
    return DoctorPerformanceMetricModel(
      doctorId: map['doctorId'] as String?,
      doctorName: map['doctorName'] as String?,
      specialty: map['specialty'] as String?,
      visitsCount: (map['visitsCount'] as num?)?.toInt(),
      revenueGeneratedPiastres: (map['revenueGeneratedPiastres'] as num?)?.toInt(),
      doctorCommissionPiastres: (map['doctorCommissionPiastres'] as num?)?.toInt(),
      clinicSharePiastres: (map['clinicSharePiastres'] as num?)?.toInt(),
      avgConsultationDurationMinutes: (map['avgConsultationDurationMinutes'] as num?)?.toInt(),
      patientSatisfactionRating: (map['patientSatisfactionRating'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        doctorId,
        doctorName,
        specialty,
        visitsCount,
        revenueGeneratedPiastres,
        doctorCommissionPiastres,
        clinicSharePiastres,
        avgConsultationDurationMinutes,
        patientSatisfactionRating,
      ];
}

