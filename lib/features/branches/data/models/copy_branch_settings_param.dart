class CopyBranchSettingsParam {
  final String? sourceBranchId;
  final String? targetBranchId;
  final bool? copyWorkingHours;
  final bool? copySpecialHolidays;
  final bool? copyMedicalServices;
  final bool? copyDoctorSchedules;

  const CopyBranchSettingsParam({
    this.sourceBranchId,
    this.targetBranchId,
    this.copyWorkingHours,
    this.copySpecialHolidays,
    this.copyMedicalServices,
    this.copyDoctorSchedules,
  });

  factory CopyBranchSettingsParam.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CopyBranchSettingsParam();
    return CopyBranchSettingsParam(
      sourceBranchId: json['sourceBranchId']?.toString(),
      targetBranchId: json['targetBranchId']?.toString(),
      copyWorkingHours: json['copyWorkingHours'] as bool?,
      copySpecialHolidays: json['copySpecialHolidays'] as bool?,
      copyMedicalServices: json['copyMedicalServices'] as bool?,
      copyDoctorSchedules: json['copyDoctorSchedules'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sourceBranchId != null) 'sourceBranchId': sourceBranchId,
      if (targetBranchId != null) 'targetBranchId': targetBranchId,
      if (copyWorkingHours != null) 'copyWorkingHours': copyWorkingHours,
      if (copySpecialHolidays != null)
        'copySpecialHolidays': copySpecialHolidays,
      if (copyMedicalServices != null)
        'copyMedicalServices': copyMedicalServices,
      if (copyDoctorSchedules != null)
        'copyDoctorSchedules': copyDoctorSchedules,
    };
  }

  CopyBranchSettingsParam copyWith({
    String? sourceBranchId,
    String? targetBranchId,
    bool? copyWorkingHours,
    bool? copySpecialHolidays,
    bool? copyMedicalServices,
    bool? copyDoctorSchedules,
  }) {
    return CopyBranchSettingsParam(
      sourceBranchId: sourceBranchId ?? this.sourceBranchId,
      targetBranchId: targetBranchId ?? this.targetBranchId,
      copyWorkingHours: copyWorkingHours ?? this.copyWorkingHours,
      copySpecialHolidays: copySpecialHolidays ?? this.copySpecialHolidays,
      copyMedicalServices: copyMedicalServices ?? this.copyMedicalServices,
      copyDoctorSchedules: copyDoctorSchedules ?? this.copyDoctorSchedules,
    );
  }
}

