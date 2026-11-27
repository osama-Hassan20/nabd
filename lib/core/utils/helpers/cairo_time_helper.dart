import 'package:flutter/foundation.dart';

/// Helper to handle Africa/Cairo local timezone calculations accurately.
class CairoTimeHelper {
  CairoTimeHelper._();

  static DateTime? _fixedClock;

  /// Sets a fixed clock for reproducible testing and deterministic environments.
  @visibleForTesting
  static void setFixedClock(DateTime? clock) {
    _fixedClock = clock;
  }

  /// Resets fixed clock back to real-time wall clock.
  @visibleForTesting
  static void resetFixedClock() {
    _fixedClock = null;
  }

  /// Returns current date and time in Africa/Cairo.
  /// If a fixed clock is set (e.g. in tests), returns the fixed clock directly.
  /// (UTC+2 in winter, UTC+3 during DST between last Friday of April and last Thursday of October).
  static DateTime now({DateTime? customUtc}) {
    if (_fixedClock != null) return _fixedClock!;
    final utc = customUtc ?? DateTime.now().toUtc();
    final isDst = _isCairoDst(utc);
    final offsetHours = isDst ? 3 : 2;
    return utc.add(Duration(hours: offsetHours));
  }

  /// Whether given UTC time falls within Egyptian Daylight Saving Time (DST).
  /// Starts: Last Friday of April at 00:00 (midnight).
  /// Ends: Last Thursday of October at 24:00 (i.e. Friday 00:00).
  static bool _isCairoDst(DateTime utc) {
    final year = utc.year;
    // Egypt resumed DST in 2023
    if (year < 2023) return false;

    // Find last Friday of April
    final lastDayOfApril = DateTime.utc(year, 4, 30);
    final daysUntilFriday = (lastDayOfApril.weekday - DateTime.friday) % 7;
    final lastFridayOfApril = DateTime.utc(year, 4, 30 - daysUntilFriday);

    // Find last Thursday of October (ends at midnight entering last Friday)
    final lastDayOfOctober = DateTime.utc(year, 10, 31);
    final daysUntilThursday = (lastDayOfOctober.weekday - DateTime.thursday) % 7;
    final lastThursdayOfOctober =
        DateTime.utc(year, 10, 31 - daysUntilThursday, 23, 59, 59);

    return utc.isAfter(lastFridayOfApril) &&
        utc.isBefore(lastThursdayOfOctober);
  }

  /// Checks if two dates fall on the same calendar day in Cairo.
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Checks if the date is today in Cairo.
  static bool isToday(DateTime? date, {DateTime? nowOverride}) {
    if (date == null) return false;
    final cairo = nowOverride ?? now();
    return isSameDay(date, cairo);
  }

  /// Default grace period in minutes before a scheduled booking is considered late.
  static const int defaultGraceMinutes = 5;

  /// Calculates delay in minutes between appointment time and current Cairo time.
  /// Positive value indicates appointment time has passed by that many minutes.
  static int calculateDelayMinutes(
    DateTime? date, [
    String? startTime,
    DateTime? nowOverride,
  ]) {
    if (date == null) return 0;
    DateTime appt = date;
    if (startTime != null && startTime.isNotEmpty) {
      final parts = startTime.split(':');
      final hour = int.tryParse(parts.first) ?? 0;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      appt = DateTime(date.year, date.month, date.day, hour, minute);
    }
    final cairo = nowOverride ?? now();
    final diff = cairo.difference(appt);
    return diff.inMinutes;
  }

  /// Formats delay nicely into Arabic text:
  /// e.g. "متأخر 45 دقيقة" or "متأخر ساعة و15 دقيقة"
  static String formatDelayArabic(int minutes) {
    if (minutes <= 0) return '';
    if (minutes < 60) {
      return 'متأخر $minutes دقيقة';
    }
    final hours = minutes ~/ 60;
    final remainingMin = minutes % 60;
    if (remainingMin == 0) {
      if (hours == 1) return 'متأخر ساعة';
      if (hours == 2) return 'متأخر ساعتان';
      if (hours <= 10) return 'متأخر $hours ساعات';
      return 'متأخر $hours ساعة';
    }
    final hourPart = hours == 1
        ? 'ساعة'
        : (hours == 2 ? 'ساعتان' : (hours <= 10 ? '$hours ساعات' : '$hours ساعة'));
    return 'متأخر $hourPart و $remainingMin دقيقة';
  }

  /// Evaluates dynamic timing display for a waiting/scheduled booking against Cairo now.
  /// Never returns a positive "remaining" label once the slot end has passed.
  static BookingTimingInfo evaluateBookingTiming({
    required DateTime? date,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    bool isWalkIn = false,
    DateTime? nowOverride,
  }) {
    if (date == null) {
      return const BookingTimingInfo(label: '—', isLateOrExpired: false);
    }

    final cairo = nowOverride ?? now();
    DateTime start = date;
    if (startTime != null && startTime.contains(':')) {
      final parts = startTime.split(':');
      final hour = int.tryParse(parts.first) ?? 0;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      start = DateTime(date.year, date.month, date.day, hour, minute);
    }

    final safeDuration = (durationMinutes != null && durationMinutes > 0)
        ? durationMinutes
        : 15;
    DateTime end = start.add(Duration(minutes: safeDuration));
    if (endTime != null && endTime.contains(':')) {
      final parts = endTime.split(':');
      final hour = int.tryParse(parts.first) ?? 0;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      end = DateTime(date.year, date.month, date.day, hour, minute);
    }

    if (cairo.isBefore(start)) {
      final rem = start.difference(cairo).inMinutes;
      return BookingTimingInfo(
        label: rem > 0 ? 'متبقي $rem دقيقة' : 'حان الموعد',
        isLateOrExpired: false,
      );
    }

    if (!cairo.isAfter(end)) {
      if (isWalkIn) {
        final remEnd = end.difference(cairo).inMinutes;
        return BookingTimingInfo(
          label: remEnd > 0 ? 'دخول فوري • متبقي $remEnd دقيقة' : 'دخول فوري • الآن',
          isLateOrExpired: false,
        );
      }
      final delay = cairo.difference(start).inMinutes;
      if (delay > defaultGraceMinutes) {
        return BookingTimingInfo(
          label: formatDelayArabic(delay),
          isLateOrExpired: true,
        );
      }
      return const BookingTimingInfo(
        label: 'حان الموعد',
        isLateOrExpired: false,
      );
    }

    // Slot end has passed without check-in -> late / expired (never positive remaining)
    final overdue = cairo.difference(isWalkIn ? end : start).inMinutes;
    return BookingTimingInfo(
      label: overdue > 0 ? formatDelayArabic(overdue) : 'انتهى الوقت',
      isLateOrExpired: true,
    );
  }
}

class BookingTimingInfo {
  final String label;
  final bool isLateOrExpired;

  const BookingTimingInfo({
    required this.label,
    required this.isLateOrExpired,
  });
}

