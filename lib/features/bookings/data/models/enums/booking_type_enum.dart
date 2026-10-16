import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';

enum BookingTypeEnum {
  oneTime(
    value: 'one_time',
    labelKey: 'one_time',
    color: AppColors.primary,
    backgroundColor: AppColors.primaryLight,
    icon: AppIcons.calendar,
  ),
  recurring(
    value: 'recurring',
    labelKey: 'recurring',
    color: AppColors.cyan,
    backgroundColor: AppColors.primaryLight,
    icon: AppIcons.pending,
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
    return BookingTypeEnum.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => BookingTypeEnum.oneTime,
    );
  }
}
