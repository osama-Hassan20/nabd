enum DiscountTypeEnum {
  none('none'),
  percentage('percentage'),
  fixedAmount('fixed_amount'),
  free('free');

  final String value;
  const DiscountTypeEnum(this.value);

  static DiscountTypeEnum fromValue(String? val) {
    return DiscountTypeEnum.values.firstWhere(
      (e) => e.value == val,
      orElse: () => DiscountTypeEnum.none,
    );
  }
}

