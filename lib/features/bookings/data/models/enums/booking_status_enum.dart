import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';

enum BookingStatusEnum {
  waiting(
    value: 'waiting',
    labelKey: 'status_waiting',
    color: AppColors.statusWarning,
    backgroundColor: AppColors.statusWarningLight,
    icon: AppIcons.clock,
  ),
  // Backward compatibility alias for scheduled
  scheduled(
    value: 'scheduled',
    labelKey: 'status_waiting',
    color: AppColors.statusWarning,
    backgroundColor: AppColors.statusWarningLight,
    icon: AppIcons.clock,
  ),
  inConsultation(
    value: 'in_consultation',
    labelKey: 'status_in_consultation',
    color: AppColors.primary,
    backgroundColor: AppColors.primaryLight,
    icon: AppIcons.team,
  ),
  completed(
    value: 'completed',
    labelKey: 'status_completed',
    color: AppColors.secondary,
    backgroundColor: AppColors.secondaryLight,
    icon: AppIcons.completedBooking,
  ),
  postponed(
    value: 'postponed',
    labelKey: 'status_postponed',
    color: Color(0xFF4A5568),
    backgroundColor: Color(0xFFEDF2F7),
    icon: AppIcons.pending,
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
    final normalized = val.toLowerCase().trim();
    if (normalized == 'scheduled' || normalized == 'pending' || normalized == 'waiting') {
      return BookingStatusEnum.waiting;
    }
    if (normalized == 'in_consultation' || normalized == 'in_progress') {
      return BookingStatusEnum.inConsultation;
    }
    if (normalized == 'completed' || normalized == 'done') {
      return BookingStatusEnum.completed;
    }
    if (normalized == 'postponed') {
      return BookingStatusEnum.postponed;
    }
    if (normalized == 'cancelled' || normalized == 'canceled') {
      return BookingStatusEnum.cancelled;
    }
    return BookingStatusEnum.waiting;
  }
}
