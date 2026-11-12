import 'package:easy_localization/easy_localization.dart';

enum PaymentMethod {
  cash('cash'),
  card('card'),
  bankTransfer('bankTransfer');

  final String value;
  const PaymentMethod(this.value);

  static PaymentMethod fromValue(String? val) {
    if (val == null) return PaymentMethod.cash;
    for (final method in PaymentMethod.values) {
      if (method.value.toLowerCase() == val.toLowerCase() ||
          method.name.toLowerCase() == val.toLowerCase()) {
        return method;
      }
    }
    return PaymentMethod.cash;
  }

  String get translationKey {
    switch (this) {
      case PaymentMethod.cash:
        return 'cashier_method_cash';
      case PaymentMethod.card:
        return 'cashier_method_card';
      case PaymentMethod.bankTransfer:
        return 'cashier_method_bank';
    }
  }

  String get localizedName => translationKey.tr();
}
