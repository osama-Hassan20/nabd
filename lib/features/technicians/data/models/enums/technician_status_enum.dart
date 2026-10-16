import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';

enum TechnicianStatusEnum {
  available(
    value: 'available',
    labelKey: 'tech_status_available',
    color: AppColors.success,
    backgroundColor: AppColors.secondaryLight,
    icon: AppIcons.checkmarkCircle,
  ),
  busy(
    value: 'busy',
    labelKey: 'tech_status_busy',
    color: AppColors.primary,
    backgroundColor: AppColors.primaryLight,
    icon: AppIcons.calendar,
  ),
  onLeave(
    value: 'on_leave',
    labelKey: 'tech_status_on_leave',
    color: AppColors.warning,
    backgroundColor: AppColors.yellowLight,
    icon: AppIcons.cancelledBooking,
  );

  final String value;
  final String labelKey;
  final Color color;
  final Color backgroundColor;
  final String icon;

  const TechnicianStatusEnum({
    required this.value,
    required this.labelKey,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  String get label => labelKey.tr();

  static TechnicianStatusEnum? fromValue(String? val) {
    if (val == null) return null;
    return TechnicianStatusEnum.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => TechnicianStatusEnum.available,
    );
  }
}
