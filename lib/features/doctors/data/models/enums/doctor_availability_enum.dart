enum DoctorAvailabilityEnum {
  available('available'),
  notWorkingDay('not_working_day'),
  onLeave('on_leave'),
  facilityHoliday('facility_holiday'),
  noSchedule('no_schedule');

  final String value;
  const DoctorAvailabilityEnum(this.value);

  String get translationKey => value;
}

