import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/specialty_records/data/models/specialty_record_entry_model.dart';
import 'package:eyadty/features/specialty_records/domain/specialty_record_module.dart';
import 'package:eyadty/features/specialty_records/presentation/modules/chronic_and_msk_modules.dart';
import 'package:eyadty/features/specialty_records/presentation/modules/dentistry_module.dart';
import 'package:eyadty/features/specialty_records/presentation/modules/dermatology_cosmetic_module.dart';
import 'package:eyadty/features/specialty_records/presentation/modules/nutrition_module.dart';
import 'package:eyadty/features/specialty_records/presentation/modules/obgyn_module.dart';
import 'package:eyadty/features/specialty_records/presentation/modules/ophthalmology_module.dart';
import 'package:eyadty/features/specialty_records/presentation/modules/pediatrics_module.dart';
import 'package:eyadty/features/specialty_records/presentation/modules/structured_generic_module.dart';

class SpecialtyModuleRegistry {
  SpecialtyModuleRegistry._();

  static SpecialtyRecordModule forSpecialty(MedicalSpecialty specialty) {
    switch (specialty) {
      case MedicalSpecialty.pediatrics:
        return const PediatricsModule();
      case MedicalSpecialty.obstetricsGynecology:
        return const ObstetricsGynecologyModule();
      case MedicalSpecialty.dentistry:
        return const DentistryModule();
      case MedicalSpecialty.orthodontics:
      case MedicalSpecialty.dermatology:
      case MedicalSpecialty.cosmeticPlasticSurgery:
        return DermatologyCosmeticModule(specialty);
      case MedicalSpecialty.ophthalmology:
        return const OphthalmologyModule();
      case MedicalSpecialty.internalMedicine:
      case MedicalSpecialty.cardiology:
      case MedicalSpecialty.endocrinology:
        return ChronicCareModule(specialty);
      case MedicalSpecialty.orthopedics:
      case MedicalSpecialty.physiotherapy:
        return MusculoskeletalModule(specialty);
      case MedicalSpecialty.ent:
        return const StructuredGenericModule(
          specialty: MedicalSpecialty.ent,
          customHeaderAr: 'فحص الأنف والأذن والحنجرة',
          trendFieldLabels: ['اختبار السمع (dB)', 'منظار الأنف والحنجرة'],
        );
      case MedicalSpecialty.urology:
        return const StructuredGenericModule(
          specialty: MedicalSpecialty.urology,
          customHeaderAr: 'سجل المسالك البولية',
          trendFieldLabels: ['معدل التدفق / IPSS', 'تحليل PSA / السونار'],
        );
      case MedicalSpecialty.neurology:
        return const StructuredGenericModule(
          specialty: MedicalSpecialty.neurology,
          customHeaderAr: 'سجل المخ والأعصاب',
          trendFieldLabels: ['القوة الحركية / GCS', 'تكرار الصداع / النوبات'],
        );
      case MedicalSpecialty.psychiatry:
        return const StructuredGenericModule(
          specialty: MedicalSpecialty.psychiatry,
          customHeaderAr: 'سجل الصحة النفسية',
          trendFieldLabels: ['مقياس المزاج / النوم', 'تقييم PHQ-9 / GAD-7'],
        );
      case MedicalSpecialty.nutrition:
        return const NutritionModule();
      case MedicalSpecialty.generalSurgery:
        return const StructuredGenericModule(
          specialty: MedicalSpecialty.generalSurgery,
          customHeaderAr: 'سجل الجراحة العامة',
          trendFieldLabels: ['موضع الجراحة وحالة الجرح', 'الدرنقة / الغرز'],
        );
      case MedicalSpecialty.generalPractice:
      case MedicalSpecialty.other:
        return StructuredGenericModule(
          specialty: specialty,
          isGenericFallback: true,
          trendFieldLabels: const ['مؤشر المتابعة'],
        );
    }
  }

  static List<SpecialtyRecordModule> modulesForDoctor(DoctorModel doctor) {
    return doctor.effectiveSpecialties.map(forSpecialty).toList();
  }

  static List<SpecialtyRecordModule> modulesForPatient({
    required PatientModel patient,
    required List<MedicalSpecialty> enabledSpecialties,
    required List<SpecialtyRecordEntryModel> existingEntries,
  }) {
    final specs = <MedicalSpecialty>{
      ...enabledSpecialties,
      ...existingEntries.map((e) => e.specialty),
    };
    return specs.map(forSpecialty).toList();
  }
}
