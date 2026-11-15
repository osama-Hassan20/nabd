enum EmployeeTypeEnum {
  doctor,
  staff;

  String toJson() => name;

  static EmployeeTypeEnum? fromJson(String? value) {
    if (value == null) return null;
    return EmployeeTypeEnum.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EmployeeTypeEnum.staff,
    );
  }
}
