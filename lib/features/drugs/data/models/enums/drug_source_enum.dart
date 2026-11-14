enum DrugSourceEnum {
  preset,
  custom,
  imported,
  quickAdd;

  String toJson() => name;

  static DrugSourceEnum? fromJson(String? value) {
    if (value == null) return null;
    return DrugSourceEnum.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DrugSourceEnum.preset,
    );
  }
}
