import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';

enum BookingStatusEnum {
  waiting(
    value: 'waiting',
    labelKey: 'status_waiting',
    color: Color(0xFFE89A24),
    backgroundColor: Color(0xFFFEF6E9),
    icon: AppIcons.clock,
  ),
  inConsultation(
    value: 'in_consultation',
    labelKey: 'status_in_consultation',
    color: Color(0xFF3880EC),
    backgroundColor: Color(0xFFEEF4FD),
    icon: AppIcons.team,
  ),
  completed(
    value: 'completed',
    labelKey: 'status_completed',
    color: Color(0xFF2E9A68),
    backgroundColor: Color(0xFFEBF7F0),
    icon: AppIcons.completedBooking,
  ),
  noShow(
    value: 'no_show',
    labelKey: 'status_no_show',
    color: Color(0xFF6B7280),
    backgroundColor: Color(0xFFF3F4F6),
    icon: AppIcons.clock,
  ),
  postponed(
    value: 'postponed',
    labelKey: 'status_postponed',
    color: Color(0xFF0D9488),
    backgroundColor: Color(0xFFE6FFFA),
    icon: AppIcons.pending,
  ),
  cancelled(
    value: 'cancelled',
    labelKey: 'status_cancelled',
    color: Color(0xFFE54848),
    backgroundColor: Color(0xFFFDF0F0),
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

  /// Backward compatibility alias for scheduled -> maps directly to waiting
  static const BookingStatusEnum scheduled = BookingStatusEnum.waiting;

  static BookingStatusEnum? fromValue(String? val) {
    if (val == null) return null;
    final normalized = val.toLowerCase().trim();
    if (normalized == 'scheduled' ||
        normalized == 'pending' ||
        normalized == 'waiting') {
      return BookingStatusEnum.waiting;
    }
    if (normalized == 'in_consultation' || normalized == 'in_progress') {
      return BookingStatusEnum.inConsultation;
    }
    if (normalized == 'completed' || normalized == 'done') {
      return BookingStatusEnum.completed;
    }
    if (normalized == 'no_show' ||
        normalized == 'noshow' ||
        normalized == 'no-show') {
      return BookingStatusEnum.noShow;
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
