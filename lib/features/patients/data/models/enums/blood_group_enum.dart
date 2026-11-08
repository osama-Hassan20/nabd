enum BloodGroupEnum {
  aPositive('A+', 'blood_a_positive'),
  aNegative('A-', 'blood_a_negative'),
  bPositive('B+', 'blood_b_positive'),
  bNegative('B-', 'blood_b_negative'),
  abPositive('AB+', 'blood_ab_positive'),
  abNegative('AB-', 'blood_ab_negative'),
  oPositive('O+', 'blood_o_positive'),
  oNegative('O-', 'blood_o_negative'),
  unknown('unknown', 'blood_unknown');

  final String value;
  final String labelKey;

  const BloodGroupEnum(this.value, this.labelKey);

  static BloodGroupEnum fromValue(dynamic val) {
    if (val == null) return BloodGroupEnum.unknown;
    final str = val.toString().toUpperCase().trim();
    for (final bg in BloodGroupEnum.values) {
      if (bg.value.toUpperCase() == str || bg.name.toUpperCase() == str) {
        return bg;
      }
    }
    return BloodGroupEnum.unknown;
  }
}

