enum SlotStatusEnum {
  available('available', 'slot_available'),
  booked('booked', 'slot_booked'),
  past('past', 'slot_past'),
  breakTime('break_time', 'slot_break_time'),
  insufficientTime('insufficient_time', 'slot_insufficient_time');

  final String value;
  final String labelKey;

  const SlotStatusEnum(this.value, this.labelKey);

  static SlotStatusEnum fromValue(String? val) {
    if (val == null) return SlotStatusEnum.available;
    return SlotStatusEnum.values.firstWhere(
      (e) => e.value == val,
      orElse: () => SlotStatusEnum.available,
    );
  }
}

