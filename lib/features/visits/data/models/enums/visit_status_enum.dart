enum VisitStatusEnum {
  triage('triage'),
  inProgress('in_progress'),
  finalized('finalized');

  final String value;
  const VisitStatusEnum(this.value);

  static VisitStatusEnum? fromValue(String? value) {
    if (value == null) return null;
    for (final status in VisitStatusEnum.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}
