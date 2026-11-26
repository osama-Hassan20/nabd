enum MaritalStatus {
  single('single', 'marital_single', 'آنسة / أعزب'),
  married('married', 'marital_married', 'مدام / متزوج'),
  divorced('divorced', 'marital_divorced', 'مطلقة / مطلق'),
  widowed('widowed', 'marital_widowed', 'أرملة / أرمل');

  final String value;
  final String labelKey;
  final String arabicLabel;

  const MaritalStatus(this.value, this.labelKey, this.arabicLabel);

  String femaleLabel() {
    switch (this) {
      case MaritalStatus.single:
        return 'آنسة';
      case MaritalStatus.married:
        return 'مدام';
      case MaritalStatus.divorced:
        return 'مطلقة';
      case MaritalStatus.widowed:
        return 'أرملة';
    }
  }

  static MaritalStatus? fromValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final norm = raw.trim().toLowerCase();
    for (final item in MaritalStatus.values) {
      if (item.value == norm || item.name.toLowerCase() == norm) {
        return item;
      }
    }
    return null;
  }
}
