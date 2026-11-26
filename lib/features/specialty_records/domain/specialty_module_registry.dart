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
          fields: [
            SpecialtyFieldDef('entExam', 'فحص الأذن والأنف والحنجرة'),
            SpecialtyFieldDef('audiometryDb', 'اختبار السمع (dB)'),
            SpecialtyFieldDef('endoscopyNotes', 'منظار الأنف والحنجرة'),
            SpecialtyFieldDef('plan', 'الخطة العلاجية'),
          ],
        );
      case MedicalSpecialty.urology:
        return const StructuredGenericModule(
          specialty: MedicalSpecialty.urology,
          customHeaderAr: 'سجل المسالك البولية',
          fields: [
            SpecialtyFieldDef('urinarySymptoms', 'أعراض المسالك / IPSS'),
            SpecialtyFieldDef('flowRate', 'معدل التدفق البولي'),
            SpecialtyFieldDef('psaValue', 'تحليل PSA'),
            SpecialtyFieldDef('ultrasoundNotes', 'نتيجة السونار والخطة'),
          ],
        );
      case MedicalSpecialty.neurology:
        return const StructuredGenericModule(
          specialty: MedicalSpecialty.neurology,
          customHeaderAr: 'سجل المخ والأعصاب',
          fields: [
            SpecialtyFieldDef('motorPower', 'القوة الحركية / GCS'),
            SpecialtyFieldDef('headacheFreq', 'تكرار الصداع / النوبات'),
            SpecialtyFieldDef('eegMri', 'تخطيط المخ / الأشعة'),
            SpecialtyFieldDef('plan', 'الخطة العلاجية'),
          ],
        );
      case MedicalSpecialty.psychiatry:
        return const StructuredGenericModule(
          specialty: MedicalSpecialty.psychiatry,
          customHeaderAr: 'سجل الصحة النفسية',
          fields: [
            SpecialtyFieldDef('moodScore', 'مقياس المزاج (1-10)'),
            SpecialtyFieldDef('sleepQuality', 'جودة النوم'),
            SpecialtyFieldDef('phqGad', 'تقييم PHQ-9 / GAD-7'),
            SpecialtyFieldDef('therapyPlan', 'خطة العلاج النفسي والدوائي'),
          ],
        );
      case MedicalSpecialty.nutrition:
        return const NutritionModule();
      case MedicalSpecialty.generalSurgery:
        return const StructuredGenericModule(
          specialty: MedicalSpecialty.generalSurgery,
          customHeaderAr: 'سجل الجراحة العامة',
          fields: [
            SpecialtyFieldDef('surgicalSite', 'موضع الجراحة'),
            SpecialtyFieldDef('woundStatus', 'حالة الجرح (نظيف / التهاب / يلتئم)'),
            SpecialtyFieldDef('drainSutures', 'الدرنقة / الغرز'),
            SpecialtyFieldDef('opPlan', 'الخطة الجراحية والمتابعة'),
          ],
        );
      case MedicalSpecialty.generalPractice:
        return const StructuredGenericModule(
          specialty: MedicalSpecialty.generalPractice,
          isGenericFallback: true,
          fields: [
            SpecialtyFieldDef('complaint', 'الشكوى الرئيسية'),
            SpecialtyFieldDef('findings', 'الفحص السريري'),
            SpecialtyFieldDef('followUpIndicator', 'مؤشر المتابعة'),
            SpecialtyFieldDef('plan', 'الخطة العلاجية'),
          ],
        );
      case MedicalSpecialty.other:
        return const StructuredGenericModule(
          specialty: MedicalSpecialty.other,
          isGenericFallback: true,
          fields: [
            SpecialtyFieldDef('customSpecialty', 'اسم التخصص / القسم'),
            SpecialtyFieldDef('clinicalAssessment', 'التقييم السريري'),
            SpecialtyFieldDef('followUpIndicator', 'مؤشر المتابعة'),
            SpecialtyFieldDef('plan', 'خطة المتابعة'),
          ],
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
