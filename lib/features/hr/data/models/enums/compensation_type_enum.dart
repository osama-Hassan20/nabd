enum CompensationTypeEnum {
  percentage,
  fixedPerVisit,
  salaryOnly,
  salaryPlusPercentage,
  salaryPlusFixed;

  String toJson() => name;

  static CompensationTypeEnum? fromJson(String? value) {
    if (value == null) return null;
    return CompensationTypeEnum.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CompensationTypeEnum.percentage,
    );
  }
}
