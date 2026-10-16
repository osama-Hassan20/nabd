enum ActiveStatus {
  all('الكل', 'all'),
  active('نشط', 'active'),
  inactive('غير نشط', 'inactive');

  final String label;
  final String value;
  const ActiveStatus(this.label, this.value);

  static ActiveStatus fromValue(String value) {
    return ActiveStatus.values.firstWhere(
      (element) => element.value == value,
      orElse: () => ActiveStatus.all,
    );
  }
}
