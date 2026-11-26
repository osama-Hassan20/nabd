import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';

class FemaleIntakeValidationResult {
  final List<String> errors;
  final List<String> warnings;

  const FemaleIntakeValidationResult({
    this.errors = const [],
    this.warnings = const [],
  });

  bool get isValid => errors.isEmpty;
}

class FemaleIntakeValidator {
  FemaleIntakeValidator._();

  static FemaleIntakeValidationResult validate({
    required GenderEnum? gender,
    required DateTime? dateOfBirth,
    required bool isPregnant,
    required bool isNursing,
    DateTime? lmpDate,
    DateTime? eddDate,
    bool pregnantAndNursingConfirmed = false,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final errors = <String>[];
    final warnings = <String>[];

    if (gender == GenderEnum.male) {
      if (isPregnant || isNursing) {
        errors.add('لا يمكن تسجيل الحمل أو الرضاعة لمريض ذكر.');
      }
      return FemaleIntakeValidationResult(errors: errors, warnings: warnings);
    }

    if (dateOfBirth != null) {
      int years = today.year - dateOfBirth.year;
      if (today.month < dateOfBirth.month ||
          (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
        years--;
      }
      if (years < 12 && (isPregnant || isNursing)) {
        errors.add('حقول الحمل والرضاعة غير متاحة لمن هن دون 12 سنة.');
      }
    }

    if (isPregnant) {
      if (lmpDate == null && eddDate == null) {
        errors.add('يرجى إدخال تاريخ آخر دورة (LMP) أو تاريخ الولادة المتوقع (EDD) عند تحديد الحمل.');
      }
      if (lmpDate != null) {
        final lmpDay = DateTime(lmpDate.year, lmpDate.month, lmpDate.day);
        if (lmpDay.isAfter(today)) {
          errors.add('تاريخ آخر دورة (LMP) لا يمكن أن يكون في المستقبل.');
        }
      }
      if (eddDate != null) {
        final eddDay = DateTime(eddDate.year, eddDate.month, eddDate.day);
        final diffDays = eddDay.difference(today).inDays;
        if (diffDays < 0 || diffDays > 300) {
          errors.add('تاريخ الولادة المتوقع (EDD) يجب أن يكون خلال 0 إلى 300 يوم قادمة.');
        }
      }
    }

    if (isPregnant && isNursing && !pregnantAndNursingConfirmed) {
      warnings.add('تنبيه: تم تحديد الحمل والرضاعة معاً، يرجى التأكيد.');
    }

    return FemaleIntakeValidationResult(errors: errors, warnings: warnings);
  }
}
