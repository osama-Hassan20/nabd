import 'package:easy_localization/easy_localization.dart';

enum DiscountTypeEnum {
  none('none'),
  percentage('percentage'),
  fixedAmount('fixed_amount'),
  free('free');

  final String value;
  const DiscountTypeEnum(this.value);

  String get labelKey {
    switch (this) {
      case DiscountTypeEnum.percentage:
        return 'disc_type_percentage';
      case DiscountTypeEnum.fixedAmount:
        return 'disc_type_fixed';
      case DiscountTypeEnum.free:
        return 'disc_type_free';
      case DiscountTypeEnum.none:
        return 'disc_type_none';
    }
  }

  String get localizedName => labelKey.tr();

  static DiscountTypeEnum fromValue(String? val) {
    return DiscountTypeEnum.values.firstWhere(
      (e) => e.value == val,
      orElse: () => DiscountTypeEnum.none,
    );
  }
}

