import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Centralized Formatter for numbers, dates, times, currencies, and durations.
/// Ensures consistent Latin (0-9) digits across both Arabic and English locales.
class AppFormatterHelper {
  AppFormatterHelper._();

  /// Converts any Eastern Arabic (Hindi) digits (٠-٩) in a string to Latin digits (0-9).
  static String forceLatinDigits(String input) {
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var result = input;
    for (int i = 0; i < eastern.length; i++) {
      result = result.replaceAll(eastern[i], i.toString());
    }
    return result;
  }

  /// Formats currency: e.g. "300 ج.م" (Arabic) or "300 EGP" (English).
  static String formatCurrency(num? amount) {
    if (amount == null) return '0 ${'currency'.tr()}';
    // Format integer without trailing decimals if whole
    final formattedNumber = (amount % 1 == 0)
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
    return '$formattedNumber ${'currency'.tr()}';
  }

  /// Formats duration in minutes with proper Arabic pluralization:
  /// - 1: "دقيقة واحدة"
  /// - 2: "دقيقتان"
  /// - 3..10: "5 دقائق"
  /// - 11+: "20 دقيقة"
  /// In English: "20 min"
  static String formatMinutes(int? minutes, {BuildContext? context}) {
    if (minutes == null || minutes <= 0) return '0 ${'minutes'.tr()}';
    final isAr = context != null
        ? context.locale.languageCode == 'ar'
        : 'currency'.tr() == 'ج.م';

    if (!isAr) {
      return '$minutes min';
    }

    if (minutes == 1) return 'دقيقة واحدة';
    if (minutes == 2) return 'دقيقتان';
    if (minutes >= 3 && minutes <= 10) return '$minutes دقائق';
    return '$minutes دقيقة';
  }

  /// Formats slot interval and buffer together:
  /// e.g. "20 دقيقة / 5 دقائق"
  static String formatSlotAndBuffer(
    int? slotMinutes,
    int? bufferMinutes, {
    BuildContext? context,
  }) {
    final slotStr = formatMinutes(slotMinutes ?? 20, context: context);
    final bufStr = formatMinutes(bufferMinutes ?? 5, context: context);
    return '$slotStr / $bufStr';
  }

  /// Formats date to a unified system format: "2026/01/25"
  /// Uses strictly Latin digits (0-9) and standard separator, protected with LRM for RTL safety.
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '\u200E$y/$m/$d\u200E';
  }

  /// Formats date with time: "2026/01/25 - 02:30 م"
  static String formatDateTime(DateTime? dateTime, {BuildContext? context}) {
    if (dateTime == null) return '-';
    final dateStr = formatDate(dateTime);
    final h = dateTime.hour;
    final m = dateTime.minute.toString().padLeft(2, '0');

    final isAr = context != null
        ? context.locale.languageCode == 'ar'
        : 'currency'.tr() == 'ج.م';

    final period = h >= 12
        ? (isAr ? 'م' : 'PM')
        : (isAr ? 'ص' : 'AM');

    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final hourStr = hour12.toString().padLeft(2, '0');

    return '$dateStr - $hourStr:$m $period';
  }

  /// Formats single 24-hr time string (e.g. "09:00" or "14:30") to 12-hr with Latin digits and AM/PM:
  /// Output: "09:00 ص" or "02:30 م"
  static String formatTime(String? time24, {BuildContext? context}) {
    if (time24 == null || time24.isEmpty) return '-';
    final parts = time24.split(':');
    if (parts.length < 2) return time24;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final isAr = context != null
        ? context.locale.languageCode == 'ar'
        : 'currency'.tr() == 'ج.م';

    final period = hour >= 12
        ? (isAr ? 'م' : 'PM')
        : (isAr ? 'ص' : 'AM');

    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final hourStr = hour12.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');

    return '$hourStr:$minuteStr $period';
  }

  /// Formats TimeOfDay to unified string with Latin digits: "09:00 ص"
  static String formatTimeOfDay(TimeOfDay? time, {BuildContext? context}) {
    if (time == null) return '-';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return formatTime('$h:$m', context: context);
  }

  /// Formats time range: "09:00 ص - 05:00 م"
  static String formatTimeRange(
    String? startTime,
    String? endTime, {
    BuildContext? context,
  }) {
    if (startTime == null || startTime.isEmpty) return '-';
    final startStr = formatTime(startTime, context: context);
    if (endTime == null || endTime.isEmpty) return startStr;
    final endStr = formatTime(endTime, context: context);
    return '$startStr - $endStr';
  }
}
