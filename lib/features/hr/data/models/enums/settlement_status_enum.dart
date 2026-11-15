enum SettlementStatusEnum {
  draft,
  confirmed,
  paid;

  String toJson() => name;

  static SettlementStatusEnum? fromJson(String? value) {
    if (value == null) return null;
    return SettlementStatusEnum.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SettlementStatusEnum.draft,
    );
  }
}
