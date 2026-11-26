import 'package:flutter/material.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_specialty_tracking_section.dart';
import 'package:eyadty/features/specialty_records/domain/specialty_record_module.dart';
import 'package:eyadty/features/specialty_records/presentation/widgets/sessions_and_packages_widget.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';

class DermatologyCosmeticModule implements SpecialtyRecordModule {
  @override
  final MedicalSpecialty specialty;

  const DermatologyCosmeticModule(this.specialty);

  @override
  String get tabLabelKey => specialty.labelKey;

  @override
  Map<String, dynamic> emptyEntry() => {
        'area': '',
        'procedure': '',
        'deviceOrProduct': '',
        'energyOrUnits': '',
        'batchNumber': '',
        'consentSigned': false,
        'sessionIndex': 1,
        'totalSessions': 4,
      };

  @override
  List<String> validate(Map<String, dynamic> entry) => const [];

  @override
  Widget buildPatientTab(PatientModel patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SessionsAndPackagesWidget(
          patientId: patient.id ?? '',
          patientName: patient.name,
          specialty: specialty,
          title: specialty == MedicalSpecialty.dermatology
              ? 'جلسات الجلدية والليزر'
              : (specialty == MedicalSpecialty.orthodontics
                  ? 'جلسات تعديل وتقويم الأسنان'
                  : 'باقات وجلسات التجميل'),
          procedureOptions: specialty == MedicalSpecialty.dermatology
              ? const ['ليزر إزالة شعر', 'تقشير كيميائي', 'فراكشنال ليزر', 'ميزوثيرابي']
              : (specialty == MedicalSpecialty.orthodontics
                  ? const ['شد سلك التقويم', 'تغيير أستيك', 'متابعة تقويم شفاف']
                  : const ['حقن بوتوكس', 'حقن فيلر', 'شد خيوط', 'متابعة جراحية']),
        ),
        if (patient.beforeAfterGallery != null &&
            patient.beforeAfterGallery!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const PatientSpecialtyTrackingSection(),
        ],
      ],
    );
  }

  @override
  Widget buildVisitSection(VisitModel visit) {
    return SessionsAndPackagesWidget(
      patientId: visit.patientId ?? '',
      patientName: visit.patientName,
      visitId: visit.id,
      doctorId: visit.doctorId,
      doctorName: visit.doctorName,
      specialty: specialty,
      title: specialty == MedicalSpecialty.dermatology
          ? 'جلسات الجلدية والليزر'
          : (specialty == MedicalSpecialty.orthodontics
              ? 'جلسات تقويم الأسنان'
              : 'جلسات التجميل والحقن'),
      procedureOptions: specialty == MedicalSpecialty.dermatology
          ? const ['ليزر إزالة شعر', 'تقشير كيميائي', 'ميزوثيرابي']
          : (specialty == MedicalSpecialty.orthodontics
              ? const ['شد سلك التقويم', 'متابعة تقويم']
              : const ['حقن بوتوكس', 'حقن فيلر', 'متابعة تجميل']),
    );
  }
}
