import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class BookingTimeFormatter {
  /// Formats date to day name + full date:
  /// Arabic: "الأربعاء، 15 أكتوبر 2026"
  /// English: "Wednesday, Oct 15, 2026"
  static String formatDateWithDay(DateTime? date, BuildContext context) {
    if (date == null) return '';
    final locale = context.locale.languageCode;
    final formatter = DateFormat('EEEE، d MMMM y', locale);
    return formatter.format(date);
  }

  /// Formats compact date (e.g. "15 أكتوبر 2026" or "Oct 15, 2026")
  static String formatCompactDate(DateTime? date, BuildContext context) {
    if (date == null) return '';
    final locale = context.locale.languageCode;
    final formatter = DateFormat('d MMM y', locale);
    return formatter.format(date);
  }

  /// Formats day of week short (e.g. "الأربعاء" or "Wed")
  static String formatDayName(DateTime? date, BuildContext context) {
    if (date == null) return '';
    final locale = context.locale.languageCode;
    final formatter = DateFormat('EEEE', locale);
    return formatter.format(date);
  }

  /// Formats single 24-hr time string (e.g. "14:30") to 12-hr with Arabic ص / م:
  /// Output: "02:30 م" or "02:30 PM"
  static String formatSingleTime(String? time24, BuildContext context) {
    if (time24 == null || time24.isEmpty) return '';
    final parts = time24.split(':');
    if (parts.length < 2) return time24;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final isAr = context.locale.languageCode == 'ar';

    final period = hour >= 12
        ? (isAr ? 'م' : 'PM')
        : (isAr ? 'ص' : 'AM');

    final hour12 = hour == 0
        ? 12
        : (hour > 12 ? hour - 12 : hour);

    final hourStr = hour12.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');

    return '$hourStr:$minuteStr $period';
  }

  /// Formats time range:
  /// Output: "10:00 ص - 01:00 م"
  static String formatTimeRange(
    String? startTime,
    String? endTime,
    BuildContext context,
  ) {
    if (startTime == null || startTime.isEmpty) return '';
    final formattedStart = formatSingleTime(startTime, context);
    if (endTime == null || endTime.isEmpty) return formattedStart;
    final formattedEnd = formatSingleTime(endTime, context);
    return '$formattedStart - $formattedEnd';
  }

  /// Calculates duration between startTime and endTime in minutes
  static int calculateDurationMinutes(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) return 0;
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    if (startParts.length < 2 || endParts.length < 2) return 0;

    final startMinutes = (int.tryParse(startParts[0]) ?? 0) * 60 +
        (int.tryParse(startParts[1]) ?? 0);
    final endMinutes = (int.tryParse(endParts[0]) ?? 0) * 60 +
        (int.tryParse(endParts[1]) ?? 0);

    final diff = endMinutes - startMinutes;
    return diff > 0 ? diff : 0;
  }
}
