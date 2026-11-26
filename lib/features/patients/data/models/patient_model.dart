import 'package:equatable/equatable.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'clinical_record_models.dart';
import 'enums/blood_group_enum.dart';
import 'enums/gender_enum.dart';
import 'enums/marital_status_enum.dart';
import 'patient_treatment_plan_model.dart';

class PatientModel extends Equatable {
  // 1. المعرفات الأساسية
  final String? id;
  final String? fileNumber;

  // 2. البيانات الشخصية والديموغرافية الأساسية
  final String? name;
  final String? phone; // صيغة دولية موحدة: +20XXXXXXXXXX
  final bool? phoneHasWhatsapp;
  final DateTime? dateOfBirth;
  final GenderEnum? gender;

  // 3. البيانات السريرية الأساسية والحيوية (الدفعة الأولى)
  final BloodGroupEnum? bloodGroup;
  final List<String>? allergies;
  final List<String>? chronicDiseases;
  final num? heightCm;
  final num? weightKg;
  final bool? isPregnant;
  final bool? isNursing;
  final DateTime? lastMenstrualPeriodDate;
  final MaritalStatus? maritalStatus;
  final DateTime? estimatedDueDate;
  final int? nursingBabyAgeMonths;
  final int? gravidaCount;
  final int? paraCount;
  final int? miscarriageCount;
  final int? cesareanCount;
  final String? contraceptionMethod;
  final bool? isMenopause;
  final bool? hasPregnancyAllergyWarning;

  // 4. العنوان الإقليمي
  final String? governorate;
  final String? city;
  final String? detailedAddress;

  // 5. جهة اتصال الطوارئ (اختيارية تماماً)
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;

  // 6. بيانات ولي الأمر (للأطفال دون 18 سنة - بدون parentPatientId)
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianRelation;

  // 7. التأمين الصحي
  final String? insuranceCompany;
  final String? insurancePolicyNumber;
  final num? insuranceCoveragePercent;

  // 8. ملاحظات إدارية وأرشفة
  final String? internalNotes;
  final bool? isArchived;
  final DateTime? archivedAt;
  final String? archiveReason;

  // 9. إحصائيات سريرية ومالية تراكمية
  final int? totalVisitsCount;
  final DateTime? lastVisitDate;
  final DateTime? nextAppointmentDate;
  final num? totalPaidAmount;
  final num? outstandingBalance;
  final List<PatientTreatmentPlanModel>? treatmentPlans;

  // 10. السجلات والملفات السريرية التخصصية (Clinical EMR Records)
  final List<ActiveMedicationModel>? activeMedications;
  final List<SurgicalProcedureModel>? surgicalHistory;
  final List<LabRadiologyModel>? labAndRadiology;
  final List<EyeTrackingExamModel>? eyeExams;
  final List<BeforeAfterGalleryItemModel>? beforeAfterGallery;

  // 11. طوابع الوقت
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatientModel({
    this.id,
    this.fileNumber,
    this.name,
    this.phone,
    this.phoneHasWhatsapp,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.allergies,
    this.chronicDiseases,
    this.heightCm,
    this.weightKg,
    this.isPregnant,
    this.isNursing,
    this.lastMenstrualPeriodDate,
    this.maritalStatus,
    this.estimatedDueDate,
    this.nursingBabyAgeMonths,
    this.gravidaCount,
    this.paraCount,
    this.miscarriageCount,
    this.cesareanCount,
    this.contraceptionMethod,
    this.isMenopause,
    this.hasPregnancyAllergyWarning,
    this.governorate,
    this.city,
    this.detailedAddress,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.guardianName,
    this.guardianPhone,
    this.guardianRelation,
    this.insuranceCompany,
    this.insurancePolicyNumber,
    this.insuranceCoveragePercent,
    this.internalNotes,
    this.isArchived,
    this.archivedAt,
    this.archiveReason,
    this.totalVisitsCount,
    this.lastVisitDate,
    this.nextAppointmentDate,
    this.totalPaidAmount,
    this.outstandingBalance,
    this.treatmentPlans,
    this.activeMedications,
    this.surgicalHistory,
    this.labAndRadiology,
    this.eyeExams,
    this.beforeAfterGallery,
    this.createdAt,
    this.updatedAt,
  });

  // Convenience getters for backward compatibility with existing UI
  String? get address =>
      detailedAddress ??
      (city != null && governorate != null
          ? '$governorate - $city'
          : (city ?? governorate));

  String? get notes => internalNotes;
  int? get totalBookings => totalVisitsCount;
  int? get upcomingBookings =>
      (nextAppointmentDate != null &&
              nextAppointmentDate!.isAfter(CairoTimeHelper.now()))
          ? 1
          : 0;
  num? get totalSpent => totalPaidAmount;

  // حساب السن والشهور كأرقام مجردة بدون نصوص صلبة
  int? calculateAgeYears({DateTime? customNow}) {
    if (dateOfBirth == null) return null;
    final now = customNow ?? CairoTimeHelper.now();
    int years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years--;
    }
    return years >= 0 ? years : 0;
  }

  int? calculateAgeMonths({DateTime? customNow}) {
    if (dateOfBirth == null) return null;
    final now = customNow ?? CairoTimeHelper.now();
    int months =
        (now.year - dateOfBirth!.year) * 12 + (now.month - dateOfBirth!.month);
    if (now.day < dateOfBirth!.day) months--;
    return months >= 0 ? months : 0;
  }

  bool isChild({DateTime? customNow}) {
    final years = calculateAgeYears(customNow: customNow);
    if (years == null) return false;
    return years < 18;
  }

  double? get calculatedBmi {
    if (heightCm == null ||
        weightKg == null ||
        heightCm! <= 0 ||
        weightKg! <= 0) {
      return null;
    }
    final heightMeters = heightCm! / 100.0;
    return weightKg! / (heightMeters * heightMeters);
  }

  bool get hasAllergies => allergies != null && allergies!.isNotEmpty;
  bool get hasChronicDiseases =>
      chronicDiseases != null && chronicDiseases!.isNotEmpty;
  bool get hasIncompleteProfile =>
      dateOfBirth == null ||
      gender == null ||
      gender == GenderEnum.unknown;

  DateTime? get computedEdd =>
      estimatedDueDate ?? lastMenstrualPeriodDate?.add(const Duration(days: 280));

  int? gestationalWeeks({DateTime? customNow}) {
    if (isPregnant != true) return null;
    final lmp = lastMenstrualPeriodDate ??
        computedEdd?.subtract(const Duration(days: 280));
    if (lmp == null) return null;
    final now = customNow ?? CairoTimeHelper.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(lmp.year, lmp.month, lmp.day))
        .inDays;
    if (days < 0) return 0;
    return (days ~/ 7).clamp(0, 42);
  }

  int? gestationalMonth({DateTime? customNow}) {
    final weeks = gestationalWeeks(customNow: customNow);
    if (weeks == null) return null;
    return ((weeks / 4.3).ceil()).clamp(1, 9);
  }

  factory PatientModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PatientModel();

    final parsedGender =
        json['gender'] != null ? GenderEnum.fromValue(json['gender']) : null;
    final parsedPregnant =
        json['isPregnant'] as bool? ?? json['is_pregnant'] as bool?;
    final parsedNursing =
        json['isNursing'] as bool? ?? json['is_nursing'] as bool?;
    final effectiveGender = (parsedGender == null || parsedGender == GenderEnum.unknown) &&
            (parsedPregnant == true || parsedNursing == true)
        ? GenderEnum.female
        : parsedGender;

    return PatientModel(
      id: json['id']?.toString(),
      fileNumber:
          json['fileNumber']?.toString() ?? json['file_number']?.toString(),
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      phoneHasWhatsapp: json['phoneHasWhatsapp'] as bool? ??
          json['phone_has_whatsapp'] as bool?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : (json['date_of_birth'] != null
              ? DateTime.tryParse(json['date_of_birth'].toString())
              : null),
      gender: effectiveGender,
      bloodGroup: json['bloodGroup'] != null
          ? BloodGroupEnum.fromValue(json['bloodGroup'])
          : (json['blood_group'] != null
              ? BloodGroupEnum.fromValue(json['blood_group'])
              : null),
      allergies: (json['allergies'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      chronicDiseases: (json['chronicDiseases'] as List? ??
              json['chronic_diseases'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      heightCm:
          json['heightCm'] as num? ?? json['height_cm'] as num?,
      weightKg:
          json['weightKg'] as num? ?? json['weight_kg'] as num?,
      isPregnant:
          json['isPregnant'] as bool? ?? json['is_pregnant'] as bool?,
      isNursing:
          json['isNursing'] as bool? ?? json['is_nursing'] as bool?,
      lastMenstrualPeriodDate: json['lastMenstrualPeriodDate'] != null
          ? DateTime.tryParse(json['lastMenstrualPeriodDate'].toString())
          : (json['last_menstrual_period_date'] != null
              ? DateTime.tryParse(json['last_menstrual_period_date'].toString())
              : null),
      maritalStatus: MaritalStatus.fromValue(
          json['maritalStatus'] as String? ?? json['marital_status'] as String?),
      estimatedDueDate: json['estimatedDueDate'] != null
          ? DateTime.tryParse(json['estimatedDueDate'].toString())
          : (json['estimated_due_date'] != null
              ? DateTime.tryParse(json['estimated_due_date'].toString())
              : null),
      nursingBabyAgeMonths: json['nursingBabyAgeMonths'] as int? ??
          json['nursing_baby_age_months'] as int?,
      gravidaCount: json['gravidaCount'] as int? ?? json['gravida_count'] as int?,
      paraCount: json['paraCount'] as int? ?? json['para_count'] as int?,
      miscarriageCount:
          json['miscarriageCount'] as int? ?? json['miscarriage_count'] as int?,
      cesareanCount:
          json['cesareanCount'] as int? ?? json['cesarean_count'] as int?,
      contraceptionMethod: json['contraceptionMethod'] as String? ??
          json['contraception_method'] as String?,
      isMenopause:
          json['isMenopause'] as bool? ?? json['is_menopause'] as bool?,
      hasPregnancyAllergyWarning:
          json['hasPregnancyAllergyWarning'] as bool? ??
              json['has_pregnancy_allergy_warning'] as bool?,
      governorate: json['governorate'] as String?,
      city: json['city'] as String?,
      detailedAddress: json['detailedAddress'] as String? ??
          json['detailed_address'] as String? ??
          json['address'] as String?,
      emergencyContactName: json['emergencyContactName'] as String? ??
          json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String? ??
          json['emergency_contact_phone'] as String?,
      emergencyContactRelation: json['emergencyContactRelation'] as String? ??
          json['emergency_contact_relation'] as String?,
      guardianName: json['guardianName'] as String? ??
          json['guardian_name'] as String?,
      guardianPhone: json['guardianPhone'] as String? ??
          json['guardian_phone'] as String?,
      guardianRelation: json['guardianRelation'] as String? ??
          json['guardian_relation'] as String?,
      insuranceCompany: json['insuranceCompany'] as String? ??
          json['insurance_company'] as String?,
      insurancePolicyNumber: json['insurancePolicyNumber'] as String? ??
          json['insurance_policy_number'] as String?,
      insuranceCoveragePercent: json['insuranceCoveragePercent'] as num? ??
          json['insurance_coverage_percent'] as num?,
      internalNotes: json['internalNotes'] as String? ??
          json['internal_notes'] as String? ??
          json['notes'] as String?,
      isArchived:
          json['isArchived'] as bool? ?? json['is_archived'] as bool?,
      archivedAt: json['archivedAt'] != null
          ? DateTime.tryParse(json['archivedAt'].toString())
          : (json['archived_at'] != null
              ? DateTime.tryParse(json['archived_at'].toString())
              : null),
      archiveReason: json['archiveReason'] as String? ??
          json['archive_reason'] as String?,
      totalVisitsCount: json['totalVisitsCount'] as int? ??
          json['total_visits_count'] as int? ??
          json['totalBookings'] as int? ??
          json['total_bookings'] as int?,
      lastVisitDate: json['lastVisitDate'] != null
          ? DateTime.tryParse(json['lastVisitDate'].toString())
          : (json['last_visit_date'] != null
              ? DateTime.tryParse(json['last_visit_date'].toString())
              : null),
      nextAppointmentDate: json['nextAppointmentDate'] != null
          ? DateTime.tryParse(json['nextAppointmentDate'].toString())
          : (json['next_appointment_date'] != null
              ? DateTime.tryParse(json['next_appointment_date'].toString())
              : null),
      totalPaidAmount: json['totalPaidAmount'] as num? ??
          json['total_paid_amount'] as num? ??
          json['totalSpent'] as num? ??
          json['total_spent'] as num?,
      outstandingBalance: json['outstandingBalance'] as num? ??
          json['outstanding_balance'] as num?,
      treatmentPlans: (json['treatmentPlans'] as List<dynamic>?)
          ?.map((e) => PatientTreatmentPlanModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeMedications: (json['activeMedications'] as List<dynamic>?)
          ?.map((e) => ActiveMedicationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      surgicalHistory: (json['surgicalHistory'] as List<dynamic>?)
          ?.map((e) => SurgicalProcedureModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      labAndRadiology: (json['labAndRadiology'] as List<dynamic>?)
          ?.map((e) => LabRadiologyModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      eyeExams: (json['eyeExams'] as List<dynamic>?)
          ?.map((e) => EyeTrackingExamModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      beforeAfterGallery: (json['beforeAfterGallery'] as List<dynamic>?)
          ?.map((e) => BeforeAfterGalleryItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : (json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (fileNumber != null) 'file_number': fileNumber,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (phoneHasWhatsapp != null) 'phone_has_whatsapp': phoneHasWhatsapp,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth?.toIso8601String(),
      if (gender != null) 'gender': gender?.value,
      if (bloodGroup != null) 'blood_group': bloodGroup?.value,
      if (allergies != null) 'allergies': allergies,
      if (chronicDiseases != null) 'chronic_diseases': chronicDiseases,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (isPregnant != null) 'is_pregnant': isPregnant,
      if (isNursing != null) 'is_nursing': isNursing,
      if (lastMenstrualPeriodDate != null)
        'last_menstrual_period_date':
            lastMenstrualPeriodDate?.toIso8601String(),
      if (maritalStatus != null) 'marital_status': maritalStatus?.value,
      if (estimatedDueDate != null)
        'estimated_due_date': estimatedDueDate?.toIso8601String(),
      if (nursingBabyAgeMonths != null)
        'nursing_baby_age_months': nursingBabyAgeMonths,
      if (gravidaCount != null) 'gravida_count': gravidaCount,
      if (paraCount != null) 'para_count': paraCount,
      if (miscarriageCount != null) 'miscarriage_count': miscarriageCount,
      if (cesareanCount != null) 'cesarean_count': cesareanCount,
      if (contraceptionMethod != null)
        'contraception_method': contraceptionMethod,
      if (isMenopause != null) 'is_menopause': isMenopause,
      if (hasPregnancyAllergyWarning != null)
        'has_pregnancy_allergy_warning': hasPregnancyAllergyWarning,
      if (governorate != null) 'governorate': governorate,
      if (city != null) 'city': city,
      if (detailedAddress != null) 'detailed_address': detailedAddress,
      if (emergencyContactName != null)
        'emergency_contact_name': emergencyContactName,
      if (emergencyContactPhone != null)
        'emergency_contact_phone': emergencyContactPhone,
      if (emergencyContactRelation != null)
        'emergency_contact_relation': emergencyContactRelation,
      if (guardianName != null) 'guardian_name': guardianName,
      if (guardianPhone != null) 'guardian_phone': guardianPhone,
      if (guardianRelation != null) 'guardian_relation': guardianRelation,
      if (insuranceCompany != null) 'insurance_company': insuranceCompany,
      if (insurancePolicyNumber != null)
        'insurance_policy_number': insurancePolicyNumber,
      if (insuranceCoveragePercent != null)
        'insurance_coverage_percent': insuranceCoveragePercent,
      if (internalNotes != null) 'internal_notes': internalNotes,
      if (isArchived != null) 'is_archived': isArchived,
      if (archivedAt != null) 'archived_at': archivedAt?.toIso8601String(),
      if (archiveReason != null) 'archive_reason': archiveReason,
      if (totalVisitsCount != null) 'total_visits_count': totalVisitsCount,
      if (lastVisitDate != null)
        'last_visit_date': lastVisitDate?.toIso8601String(),
      if (nextAppointmentDate != null)
        'next_appointment_date': nextAppointmentDate?.toIso8601String(),
      if (totalPaidAmount != null) 'total_paid_amount': totalPaidAmount,
      if (outstandingBalance != null)
        'outstanding_balance': outstandingBalance,
      if (treatmentPlans != null)
        'treatmentPlans': treatmentPlans!.map((e) => e.toJson()).toList(),
      if (activeMedications != null)
        'activeMedications': activeMedications!.map((e) => e.toJson()).toList(),
      if (surgicalHistory != null)
        'surgicalHistory': surgicalHistory!.map((e) => e.toJson()).toList(),
      if (labAndRadiology != null)
        'labAndRadiology': labAndRadiology!.map((e) => e.toJson()).toList(),
      if (eyeExams != null)
        'eyeExams': eyeExams!.map((e) => e.toJson()).toList(),
      if (beforeAfterGallery != null)
        'beforeAfterGallery':
            beforeAfterGallery!.map((e) => e.toJson()).toList(),
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
    };
  }

  PatientModel copyWith({
    String? id,
    String? fileNumber,
    String? name,
    String? phone,
    bool? phoneHasWhatsapp,
    DateTime? dateOfBirth,
    GenderEnum? gender,
    BloodGroupEnum? bloodGroup,
    List<String>? allergies,
    List<String>? chronicDiseases,
    num? heightCm,
    num? weightKg,
    bool? isPregnant,
    bool? isNursing,
    DateTime? lastMenstrualPeriodDate,
    bool clearLmpDate = false,
    MaritalStatus? maritalStatus,
    DateTime? estimatedDueDate,
    bool clearEddDate = false,
    int? nursingBabyAgeMonths,
    int? gravidaCount,
    int? paraCount,
    int? miscarriageCount,
    int? cesareanCount,
    String? contraceptionMethod,
    bool? isMenopause,
    bool? hasPregnancyAllergyWarning,
    String? governorate,
    String? city,
    String? detailedAddress,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? guardianName,
    String? guardianPhone,
    String? guardianRelation,
    String? insuranceCompany,
    String? insurancePolicyNumber,
    num? insuranceCoveragePercent,
    String? internalNotes,
    bool? isArchived,
    DateTime? archivedAt,
    String? archiveReason,
    int? totalVisitsCount,
    DateTime? lastVisitDate,
    DateTime? nextAppointmentDate,
    num? totalPaidAmount,
    num? outstandingBalance,
    List<PatientTreatmentPlanModel>? treatmentPlans,
    List<ActiveMedicationModel>? activeMedications,
    List<SurgicalProcedureModel>? surgicalHistory,
    List<LabRadiologyModel>? labAndRadiology,
    List<EyeTrackingExamModel>? eyeExams,
    List<BeforeAfterGalleryItemModel>? beforeAfterGallery,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      fileNumber: fileNumber ?? this.fileNumber,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      phoneHasWhatsapp: phoneHasWhatsapp ?? this.phoneHasWhatsapp,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      isPregnant: isPregnant ?? this.isPregnant,
      isNursing: isNursing ?? this.isNursing,
      lastMenstrualPeriodDate: clearLmpDate
          ? null
          : (lastMenstrualPeriodDate ?? this.lastMenstrualPeriodDate),
      maritalStatus: maritalStatus ?? this.maritalStatus,
      estimatedDueDate: clearEddDate
          ? null
          : (estimatedDueDate ?? this.estimatedDueDate),
      nursingBabyAgeMonths: nursingBabyAgeMonths ?? this.nursingBabyAgeMonths,
      gravidaCount: gravidaCount ?? this.gravidaCount,
      paraCount: paraCount ?? this.paraCount,
      miscarriageCount: miscarriageCount ?? this.miscarriageCount,
      cesareanCount: cesareanCount ?? this.cesareanCount,
      contraceptionMethod: contraceptionMethod ?? this.contraceptionMethod,
      isMenopause: isMenopause ?? this.isMenopause,
      hasPregnancyAllergyWarning:
          hasPregnancyAllergyWarning ?? this.hasPregnancyAllergyWarning,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      detailedAddress: detailedAddress ?? this.detailedAddress,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation:
          emergencyContactRelation ?? this.emergencyContactRelation,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianRelation: guardianRelation ?? this.guardianRelation,
      insuranceCompany: insuranceCompany ?? this.insuranceCompany,
      insurancePolicyNumber:
          insurancePolicyNumber ?? this.insurancePolicyNumber,
      insuranceCoveragePercent:
          insuranceCoveragePercent ?? this.insuranceCoveragePercent,
      internalNotes: internalNotes ?? this.internalNotes,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      archiveReason: archiveReason ?? this.archiveReason,
      totalVisitsCount: totalVisitsCount ?? this.totalVisitsCount,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      nextAppointmentDate: nextAppointmentDate ?? this.nextAppointmentDate,
      totalPaidAmount: totalPaidAmount ?? this.totalPaidAmount,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      treatmentPlans: treatmentPlans ?? this.treatmentPlans,
      activeMedications: activeMedications ?? this.activeMedications,
      surgicalHistory: surgicalHistory ?? this.surgicalHistory,
      labAndRadiology: labAndRadiology ?? this.labAndRadiology,
      eyeExams: eyeExams ?? this.eyeExams,
      beforeAfterGallery: beforeAfterGallery ?? this.beforeAfterGallery,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fileNumber,
        name,
        phone,
        phoneHasWhatsapp,
        dateOfBirth,
        gender,
        bloodGroup,
        allergies,
        chronicDiseases,
        heightCm,
        weightKg,
        isPregnant,
        isNursing,
        lastMenstrualPeriodDate,
        maritalStatus,
        estimatedDueDate,
        nursingBabyAgeMonths,
        gravidaCount,
        paraCount,
        miscarriageCount,
        cesareanCount,
        contraceptionMethod,
        isMenopause,
        hasPregnancyAllergyWarning,
        governorate,
        city,
        detailedAddress,
        emergencyContactName,
        emergencyContactPhone,
        emergencyContactRelation,
        guardianName,
        guardianPhone,
        guardianRelation,
        insuranceCompany,
        insurancePolicyNumber,
        insuranceCoveragePercent,
        internalNotes,
        isArchived,
        archivedAt,
        archiveReason,
        totalVisitsCount,
        lastVisitDate,
        nextAppointmentDate,
        totalPaidAmount,
        outstandingBalance,
        treatmentPlans,
        activeMedications,
        surgicalHistory,
        labAndRadiology,
        eyeExams,
        beforeAfterGallery,
        createdAt,
        updatedAt,
      ];
}
