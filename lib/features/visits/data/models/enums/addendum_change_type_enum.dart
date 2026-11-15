enum AddendumChangeTypeEnum {
  dose,
  frequency,
  duration,
  instructions,
  discontinue,
  add,
  diagnosis;

  String toJson() => name;

  static AddendumChangeTypeEnum? fromJson(String? value) {
    if (value == null) return null;
    return AddendumChangeTypeEnum.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AddendumChangeTypeEnum.instructions,
    );
  }
}

