import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';

enum DoctorStatusEnum {
  available('available'),
  busy('busy'),
  onLeave('on_leave');

  final String value;
  const DoctorStatusEnum(this.value);

  static DoctorStatusEnum? fromValue(String? value) {
    if (value == null) return null;
    return DoctorStatusEnum.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => DoctorStatusEnum.available,
    );
  }

  String get label => localizedName;

  String get localizedName {
    switch (this) {
      case DoctorStatusEnum.available:
        return 'doctor_status_available'.tr();
      case DoctorStatusEnum.busy:
        return 'doctor_status_busy'.tr();
      case DoctorStatusEnum.onLeave:
        return 'doctor_status_on_leave'.tr();
    }
  }

  String get icon {
    switch (this) {
      case DoctorStatusEnum.available:
        return AppIcons.checkmarkCircle;
      case DoctorStatusEnum.busy:
        return AppIcons.calendar;
      case DoctorStatusEnum.onLeave:
        return AppIcons.cancelledBooking;
    }
  }

  Color get color {
    switch (this) {
      case DoctorStatusEnum.available:
        return AppColors.success;
      case DoctorStatusEnum.busy:
        return AppColors.amber;
      case DoctorStatusEnum.onLeave:
        return AppColors.gray71717A;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case DoctorStatusEnum.available:
        return AppColors.secondaryLight;
      case DoctorStatusEnum.busy:
        return AppColors.amber.withValues(alpha: 0.12);
      case DoctorStatusEnum.onLeave:
        return AppColors.grayf2;
    }
  }
}
