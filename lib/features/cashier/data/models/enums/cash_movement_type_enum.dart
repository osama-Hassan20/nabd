import 'package:easy_localization/easy_localization.dart';

enum CashMovementTypeEnum {
  pettyExpense('petty_expense'),
  capitalInjection('capital_injection'),
  bankDeposit('bank_deposit'),
  ownerWithdrawal('owner_withdrawal');

  final String value;
  const CashMovementTypeEnum(this.value);

  static CashMovementTypeEnum fromValue(String? val) {
    if (val == null) return CashMovementTypeEnum.pettyExpense;
    for (final type in CashMovementTypeEnum.values) {
      if (type.value.toLowerCase() == val.toLowerCase() ||
          type.name.toLowerCase() == val.toLowerCase()) {
        return type;
      }
    }
    return CashMovementTypeEnum.pettyExpense;
  }

  bool get isOutflow =>
      this == CashMovementTypeEnum.pettyExpense ||
      this == CashMovementTypeEnum.bankDeposit ||
      this == CashMovementTypeEnum.ownerWithdrawal;

  bool get isInflow => this == CashMovementTypeEnum.capitalInjection;

  String get translationKey {
    switch (this) {
      case CashMovementTypeEnum.pettyExpense:
        return 'cashier_petty_expense';
      case CashMovementTypeEnum.capitalInjection:
        return 'cashier_capital_injection';
      case CashMovementTypeEnum.bankDeposit:
        return 'cashier_bank_deposit';
      case CashMovementTypeEnum.ownerWithdrawal:
        return 'cashier_owner_withdrawal';
    }
  }

  String get localizedName => translationKey.tr();
}
