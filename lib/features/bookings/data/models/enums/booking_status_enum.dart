import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';

enum BookingStatusEnum {
  scheduled(
    value: 'scheduled',
    labelKey: 'status_scheduled',
    color: AppColors.primary,
    backgroundColor: AppColors.primaryLight,
    icon: AppIcons.comingBooking,
  ),
  completed(
    value: 'completed',
    labelKey: 'status_completed',
    color: AppColors.success,
    backgroundColor: AppColors.secondaryLight,
    icon: AppIcons.completedBooking,
  ),
  cancelled(
    value: 'cancelled',
    labelKey: 'status_cancelled',
    color: AppColors.error,
    backgroundColor: AppColors.red1A,
    icon: AppIcons.cancelledBooking,
  );

  final String value;
  final String labelKey;
  final Color color;
  final Color backgroundColor;
  final String icon;

  const BookingStatusEnum({
    required this.value,
    required this.labelKey,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  String get label => labelKey.tr();

  static BookingStatusEnum? fromValue(String? val) {
    if (val == null) return null;
    return BookingStatusEnum.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => BookingStatusEnum.scheduled,
    );
  }
}
