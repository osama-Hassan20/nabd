enum GenderEnum {
  male('male', 'gender_male'),
  female('female', 'gender_female'),
  unknown('unknown', 'gender_unknown');

  final String value;
  final String labelKey;

  const GenderEnum(this.value, this.labelKey);

  static GenderEnum fromValue(dynamic val) {
    if (val == null) return GenderEnum.unknown;
    final str = val.toString().toLowerCase().trim();
    if (str == 'male' || str == 'm' || str == 'ذكر') return GenderEnum.male;
    if (str == 'female' || str == 'f' || str == 'أنثى') return GenderEnum.female;
    return GenderEnum.unknown;
  }
}

