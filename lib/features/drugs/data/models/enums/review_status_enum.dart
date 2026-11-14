enum ReviewStatusEnum {
  pending,
  approved,
  rejected,
  merged;

  String toJson() => name;

  static ReviewStatusEnum? fromJson(String? value) {
    if (value == null) return null;
    return ReviewStatusEnum.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReviewStatusEnum.pending,
    );
  }
}
