enum WeekDayEnum {
  saturday('saturday'),
  sunday('sunday'),
  monday('monday'),
  tuesday('tuesday'),
  wednesday('wednesday'),
  thursday('thursday'),
  friday('friday');

  final String value;
  const WeekDayEnum(this.value);

  String get translationKey => value;

  /// Returns the day of week enum for a given DateTime.
  /// DateTime.saturday is 6, DateTime.sunday is 7, DateTime.monday is 1, etc.
  static WeekDayEnum fromDateTime(DateTime date) {
    switch (date.weekday) {
      case DateTime.saturday:
        return WeekDayEnum.saturday;
      case DateTime.sunday:
        return WeekDayEnum.sunday;
      case DateTime.monday:
        return WeekDayEnum.monday;
      case DateTime.tuesday:
        return WeekDayEnum.tuesday;
      case DateTime.wednesday:
        return WeekDayEnum.wednesday;
      case DateTime.thursday:
        return WeekDayEnum.thursday;
      case DateTime.friday:
        return WeekDayEnum.friday;
      default:
        return WeekDayEnum.saturday;
    }
  }

  static WeekDayEnum? fromValue(String? val) {
    if (val == null) return null;
    final normalized = val.toLowerCase().trim();
    for (final day in WeekDayEnum.values) {
      if (day.value == normalized) return day;
    }
    return null;
  }
}

