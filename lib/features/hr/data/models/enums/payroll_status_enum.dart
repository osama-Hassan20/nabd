enum PayrollStatusEnum {
  draft,
  confirmed,
  paid;

  String toJson() => name;

  static PayrollStatusEnum? fromJson(String? value) {
    if (value == null) return null;
    return PayrollStatusEnum.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PayrollStatusEnum.draft,
    );
  }
}
