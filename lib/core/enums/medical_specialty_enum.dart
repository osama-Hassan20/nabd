import 'package:flutter/material.dart';

enum MedicalSpecialty {
  generalPractice(
    'general_practice',
    'specialty_general_practice',
    Icons.local_hospital_outlined,
  ),
  internalMedicine(
    'internal_medicine',
    'specialty_internal_medicine',
    Icons.medical_services_outlined,
  ),
  cardiology(
    'cardiology',
    'specialty_cardiology',
    Icons.favorite_outline,
  ),
  pediatrics(
    'pediatrics',
    'specialty_pediatrics',
    Icons.child_care_outlined,
  ),
  obstetricsGynecology(
    'obstetrics_gynecology',
    'specialty_obstetrics_gynecology',
    Icons.pregnant_woman_outlined,
  ),
  dentistry(
    'dentistry',
    'specialty_dentistry',
    Icons.mood_outlined,
  ),
  orthodontics(
    'orthodontics',
    'specialty_orthodontics',
    Icons.grid_on_outlined,
  ),
  dermatology(
    'dermatology',
    'specialty_dermatology',
    Icons.face_retouching_natural_outlined,
  ),
  cosmeticPlasticSurgery(
    'cosmetic_plastic_surgery',
    'specialty_cosmetic_plastic_surgery',
    Icons.auto_awesome_outlined,
  ),
  ophthalmology(
    'ophthalmology',
    'specialty_ophthalmology',
    Icons.visibility_outlined,
  ),
  ent(
    'ent',
    'specialty_ent',
    Icons.hearing_outlined,
  ),
  orthopedics(
    'orthopedics',
    'specialty_orthopedics',
    Icons.accessibility_new_outlined,
  ),
  generalSurgery(
    'general_surgery',
    'specialty_general_surgery',
    Icons.healing_outlined,
  ),
  urology(
    'urology',
    'specialty_urology',
    Icons.water_drop_outlined,
  ),
  neurology(
    'neurology',
    'specialty_neurology',
    Icons.psychology_outlined,
  ),
  psychiatry(
    'psychiatry',
    'specialty_psychiatry',
    Icons.self_improvement_outlined,
  ),
  physiotherapy(
    'physiotherapy',
    'specialty_physiotherapy',
    Icons.fitness_center_outlined,
  ),
  nutrition(
    'nutrition',
    'specialty_nutrition',
    Icons.restaurant_outlined,
  ),
  endocrinology(
    'endocrinology',
    'specialty_endocrinology',
    Icons.science_outlined,
  ),
  other(
    'other',
    'specialty_other',
    Icons.category_outlined,
  );

  final String value;
  final String labelKey;
  final IconData icon;

  const MedicalSpecialty(this.value, this.labelKey, this.icon);

  static MedicalSpecialty fromValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return MedicalSpecialty.generalPractice;
    final normalized = raw.trim().toLowerCase();

    // 1. Exact code or enum name match
    for (final item in MedicalSpecialty.values) {
      if (item.value == normalized || item.name.toLowerCase() == normalized) {
        return item;
      }
    }

    // 2. Legacy free-text Arabic / English migration
    if (normalized.contains('أطفال') || normalized.contains('اطفال') || normalized.contains('pediatric')) {
      return MedicalSpecialty.pediatrics;
    }
    if (normalized.contains('نساء') || normalized.contains('توليد') || normalized.contains('ob') || normalized.contains('gyn')) {
      return MedicalSpecialty.obstetricsGynecology;
    }
    if (normalized.contains('تقويم')) {
      return MedicalSpecialty.orthodontics;
    }
    if (normalized.contains('أسنان') || normalized.contains('اسنان') || normalized.contains('dent')) {
      return MedicalSpecialty.dentistry;
    }
    if (normalized.contains('تجميل') || normalized.contains('cosmetic') || normalized.contains('plastic')) {
      return MedicalSpecialty.cosmeticPlasticSurgery;
    }
    if (normalized.contains('جلدية') || normalized.contains('جلديه') || normalized.contains('ليزر') || normalized.contains('derma')) {
      return MedicalSpecialty.dermatology;
    }
    if (normalized.contains('عيون') || normalized.contains('رمد') || normalized.contains('ophthal')) {
      return MedicalSpecialty.ophthalmology;
    }
    if (normalized.contains('أنف') || normalized.contains('انف') || normalized.contains('أذن') || normalized.contains('اذن') || normalized.contains('ent')) {
      return MedicalSpecialty.ent;
    }
    if (normalized.contains('عظام') || normalized.contains('مفاصل') || normalized.contains('ortho')) {
      return MedicalSpecialty.orthopedics;
    }
    if (normalized.contains('علاج طبيعي') || normalized.contains('physio')) {
      return MedicalSpecialty.physiotherapy;
    }
    if (normalized.contains('جراحة') || normalized.contains('جراحه') || normalized.contains('surgery')) {
      return MedicalSpecialty.generalSurgery;
    }
    if (normalized.contains('قلب') || normalized.contains('cardio')) {
      return MedicalSpecialty.cardiology;
    }
    if (normalized.contains('باطنة') || normalized.contains('باطنه') || normalized.contains('internal')) {
      return MedicalSpecialty.internalMedicine;
    }
    if (normalized.contains('مسالك') || normalized.contains('urol')) {
      return MedicalSpecialty.urology;
    }
    if (normalized.contains('مخ') || normalized.contains('أعصاب') || normalized.contains('اعصاب') || normalized.contains('neuro')) {
      return MedicalSpecialty.neurology;
    }
    if (normalized.contains('نفسية') || normalized.contains('نفسيه') || normalized.contains('psych')) {
      return MedicalSpecialty.psychiatry;
    }
    if (normalized.contains('تغذية') || normalized.contains('تغذيه') || normalized.contains('nutri')) {
      return MedicalSpecialty.nutrition;
    }
    if (normalized.contains('غدد') || normalized.contains('سكر') || normalized.contains('endo')) {
      return MedicalSpecialty.endocrinology;
    }
    if (normalized.contains('عام') || normalized.contains('general')) {
      return MedicalSpecialty.generalPractice;
    }

    return MedicalSpecialty.other;
  }

  /// Parses legacy free-text specialty strings (e.g. 'باطنة وقلب', 'جلدية وتجميل')
  /// into one or more [MedicalSpecialty] entries.
  static List<MedicalSpecialty> parseMultiple(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    final normalized = raw.trim().toLowerCase();
    final matched = <MedicalSpecialty>{};

    if (normalized.contains('باطنة') || normalized.contains('باطنه') || normalized.contains('internal')) {
      matched.add(MedicalSpecialty.internalMedicine);
    }
    if (normalized.contains('قلب') || normalized.contains('cardio')) {
      matched.add(MedicalSpecialty.cardiology);
    }
    if (normalized.contains('أطفال') || normalized.contains('اطفال') || normalized.contains('pediatric')) {
      matched.add(MedicalSpecialty.pediatrics);
    }
    if (normalized.contains('نساء') || normalized.contains('توليد')) {
      matched.add(MedicalSpecialty.obstetricsGynecology);
    }
    if (normalized.contains('تقويم')) {
      matched.add(MedicalSpecialty.orthodontics);
    } else if (normalized.contains('أسنان') || normalized.contains('اسنان') || normalized.contains('dent')) {
      matched.add(MedicalSpecialty.dentistry);
    }
    if (normalized.contains('جلدية') || normalized.contains('جلديه') || normalized.contains('derma')) {
      matched.add(MedicalSpecialty.dermatology);
    }
    if (normalized.contains('تجميل') || normalized.contains('cosmetic') || normalized.contains('plastic')) {
      matched.add(MedicalSpecialty.cosmeticPlasticSurgery);
    }
    if (normalized.contains('عيون') || normalized.contains('رمد') || normalized.contains('ophthal')) {
      matched.add(MedicalSpecialty.ophthalmology);
    }
    if (normalized.contains('أنف') || normalized.contains('انف') || normalized.contains('أذن') || normalized.contains('ent')) {
      matched.add(MedicalSpecialty.ent);
    }
    if (normalized.contains('عظام') || normalized.contains('مفاصل') || normalized.contains('ortho')) {
      matched.add(MedicalSpecialty.orthopedics);
    }
    if (normalized.contains('جراحة') || normalized.contains('جراحه') || normalized.contains('surgery')) {
      matched.add(MedicalSpecialty.generalSurgery);
    }
    if (normalized.contains('مسالك') || normalized.contains('urol')) {
      matched.add(MedicalSpecialty.urology);
    }
    if (normalized.contains('مخ') || normalized.contains('أعصاب') || normalized.contains('neuro')) {
      matched.add(MedicalSpecialty.neurology);
    }
    if (normalized.contains('نفسية') || normalized.contains('psych')) {
      matched.add(MedicalSpecialty.psychiatry);
    }
    if (normalized.contains('علاج طبيعي') || normalized.contains('physio')) {
      matched.add(MedicalSpecialty.physiotherapy);
    }
    if (normalized.contains('تغذية') || normalized.contains('nutri')) {
      matched.add(MedicalSpecialty.nutrition);
    }
    if (normalized.contains('غدد') || normalized.contains('endo')) {
      matched.add(MedicalSpecialty.endocrinology);
    }
    if (normalized.contains('عام') || normalized.contains('general')) {
      matched.add(MedicalSpecialty.generalPractice);
    }

    if (matched.isEmpty) {
      matched.add(fromValue(raw));
    }
    return matched.toList();
  }
}
