import 'package:easy_localization/easy_localization.dart';

enum DoctorGenderEnum {
  male('male'),
  female('female');

  final String value;
  const DoctorGenderEnum(this.value);

  static DoctorGenderEnum? fromValue(String? value) {
    if (value == null) return null;
    return DoctorGenderEnum.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => DoctorGenderEnum.male,
    );
  }

  String get label => localizedName;

  String get localizedName {
    switch (this) {
      case DoctorGenderEnum.male:
        return 'gender_male'.tr();
      case DoctorGenderEnum.female:
        return 'gender_female'.tr();
    }
  }
}
