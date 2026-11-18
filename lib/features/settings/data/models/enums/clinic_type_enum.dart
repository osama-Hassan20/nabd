enum ClinicTypeEnum {
  singleDoctor('single_doctor', 'عيادة فردية (طبيب واحد)'),
  polyclinic('polyclinic', 'مركز طبي / مجمع عيادات');

  final String value;
  final String label;

  const ClinicTypeEnum(this.value, this.label);

  static ClinicTypeEnum fromValue(String? value) {
    if (value == 'single_doctor' || value == 'singleDoctor') {
      return ClinicTypeEnum.singleDoctor;
    }
    return ClinicTypeEnum.polyclinic;
  }
}
