enum LedgerEntryTypeEnum {
  advance,
  deduction,
  bonus,
  adjustment,
  payout;

  String toJson() => name;

  static LedgerEntryTypeEnum? fromJson(String? value) {
    if (value == null) return null;
    return LedgerEntryTypeEnum.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LedgerEntryTypeEnum.adjustment,
    );
  }
}

