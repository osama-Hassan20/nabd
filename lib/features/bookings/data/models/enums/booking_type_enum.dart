import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';

enum BookingTypeEnum {
  newVisit(
    value: 'new_visit',
    labelKey: 'visit_type_new',
    color: AppColors.primary,
    backgroundColor: AppColors.primaryLight,
    icon: AppIcons.calendar,
  ),
  revisit(
    value: 'revisit',
    labelKey: 'visit_type_revisit',
    color: AppColors.secondary,
    backgroundColor: AppColors.secondaryLight,
    icon: AppIcons.clock,
  ),
  emergency(
    value: 'emergency',
    labelKey: 'visit_type_emergency',
    color: AppColors.error,
    backgroundColor: AppColors.red1A,
    icon: AppIcons.warning,
  ),

  // ─── Backward-compatibility aliases for other unrefactored modules ───────
  oneTime(
    value: 'one_time',
    labelKey: 'visit_type_new',
    color: AppColors.primary,
    backgroundColor: AppColors.primaryLight,
    icon: AppIcons.calendar,
  ),
  recurring(
    value: 'recurring',
    labelKey: 'visit_type_revisit',
    color: AppColors.secondary,
    backgroundColor: AppColors.secondaryLight,
    icon: AppIcons.clock,
  );

  final String value;
  final String labelKey;
  final Color color;
  final Color backgroundColor;
  final String icon;

  const BookingTypeEnum({
    required this.value,
    required this.labelKey,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  String get label => labelKey.tr();

  static BookingTypeEnum? fromValue(String? val) {
    if (val == null) return null;
    final normalized = val.toLowerCase().trim();
    if (normalized == 'new_visit' || normalized == 'one_time') {
      return BookingTypeEnum.newVisit;
    }
    if (normalized == 'revisit' || normalized == 'recurring') {
      return BookingTypeEnum.revisit;
    }
    if (normalized == 'emergency' || normalized == 'urgent') {
      return BookingTypeEnum.emergency;
    }
    return BookingTypeEnum.newVisit;
  }
}
