import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_summary_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';

/// Pure, testable helper to compute booking statistics & filter bookings
/// according to Africa/Cairo local date, branch, and status definitions.
class BookingStatisticsCalculator {
  BookingStatisticsCalculator._();

  /// Computes summary statistics for a given list of bookings, selected date, and branch.
  static BookingSummaryModel calculateSummary({
    required List<BookingModel> bookings,
    required DateTime selectedDate,
    String? branchId,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? CairoTimeHelper.now();

    int total = 0;
    int waiting = 0;
    int inConsultation = 0;
    int completed = 0;
    int noShow = 0;
    int cancelled = 0;
    int postponed = 0;
    num totalDiscounts = 0;
    int freeConsultations = 0;
    num totalNetRev = 0;

    for (final booking in bookings) {
      if (!matchesBranch(booking, branchId)) continue;

      if (isPostponedToAnotherDate(booking, selectedDate)) {
        postponed++;
        total++;
        continue;
      }

      if (isCancelledForDate(booking, selectedDate)) {
        cancelled++;
        total++;
        continue;
      }

      // Check if scheduled for this date
      final apptDate = booking.appointmentTime ?? booking.date;
      if (!CairoTimeHelper.isSameDay(apptDate, selectedDate)) {
        continue;
      }

      total++;

      // Financials for non-cancelled bookings on selected date
      totalDiscounts += booking.discountAmount;
      if (booking.isFreeConsultation) {
        freeConsultations++;
      }
      totalNetRev += booking.netAmount;

      if (booking.status == BookingStatusEnum.completed) {
        completed++;
      } else if (booking.status == BookingStatusEnum.inConsultation) {
        inConsultation++;
      } else if (isNoShow(booking, selectedDate, now: now)) {
        noShow++;
      } else if (booking.status == BookingStatusEnum.waiting) {
        waiting++;
      } else {
        // Fallback for any other active state on this date
        waiting++;
      }
    }

    return BookingSummaryModel(
      totalBookings: total,
      inWaitingCount: waiting,
      inConsultationCount: inConsultation,
      completedBookings: completed,
      noShowCount: noShow,
      cancelledBookings: cancelled,
      postponedCount: postponed,
      totalDiscountsGiven: totalDiscounts,
      freeConsultationsCount: freeConsultations,
      totalNetRevenue: totalNetRev,
    );
  }

  /// Whether booking matches the given branch ID.
  static bool matchesBranch(BookingModel booking, String? branchId) {
    if (branchId == null || branchId.isEmpty) return true;
    if (booking.branchId == null || booking.branchId!.isEmpty) return true;
    return booking.branchId == branchId;
  }

  /// Whether booking is a "No-Show":
  /// - Has appointment on selected date.
  /// - Did not arrive (arrivalTime == null).
  /// - Not in consultation, completed, cancelled, or postponed.
  /// - AND (explicit status == noShow OR appointment time passed relative to Cairo now).
  static bool isNoShow(
    BookingModel booking,
    DateTime selectedDate, {
    DateTime? now,
  }) {
    final cairoNow = now ?? CairoTimeHelper.now();

    // Explicit status
    if (booking.status == BookingStatusEnum.noShow) {
      final apptDate = booking.appointmentTime ?? booking.date;
      return CairoTimeHelper.isSameDay(apptDate, selectedDate);
    }

    // Excluded statuses
    if (booking.status == BookingStatusEnum.completed ||
        booking.status == BookingStatusEnum.cancelled ||
        booking.status == BookingStatusEnum.postponed ||
        booking.status == BookingStatusEnum.inConsultation) {
      return false;
    }

    // If arrival is recorded, not a no-show
    if (booking.arrivalTime != null) return false;

    final apptDate = booking.appointmentTime ?? booking.date;
    if (!CairoTimeHelper.isSameDay(apptDate, selectedDate)) return false;

    // Evaluate time
    final targetTime = _resolveAppointmentDateTime(booking, selectedDate);
    if (targetTime == null) return false;

    // Past date compared to Cairo today -> No-show
    final today = DateTime(cairoNow.year, cairoNow.month, cairoNow.day);
    final targetDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (targetDay.isBefore(today)) {
      return true;
    }

    if (targetDay.isAfter(today)) {
      // Future day is not a no-show yet unless explicitly set
      return false;
    }

    // Today in Cairo: passed appointment time
    return cairoNow.isAfter(targetTime);
  }

  /// Whether booking was cancelled for the selected date:
  /// - Status is cancelled.
  /// - AND (scheduled on selected date OR cancelled on selected date).
  static bool isCancelledForDate(BookingModel booking, DateTime selectedDate) {
    if (booking.status != BookingStatusEnum.cancelled) return false;
    final apptDate = booking.appointmentTime ?? booking.date;
    final cancelledAt = booking.cancelledAt;

    return CairoTimeHelper.isSameDay(apptDate, selectedDate) ||
        (cancelledAt != null && CairoTimeHelper.isSameDay(cancelledAt, selectedDate));
  }

  /// Whether booking was postponed from selected date to a DIFFERENT date.
  /// (Postponed to the same day at a later time is NOT counted here).
  static bool isPostponedToAnotherDate(
    BookingModel booking,
    DateTime selectedDate,
  ) {
    if (booking.status != BookingStatusEnum.postponed) return false;

    final origDate =
        booking.originalAppointmentTime ?? booking.appointmentTime ?? booking.date;
    if (!CairoTimeHelper.isSameDay(origDate, selectedDate)) return false;

    final newDate = booking.rescheduledTo;
    if (newDate == null) return false;

    // Must be a different calendar date
    return !CairoTimeHelper.isSameDay(origDate, newDate);
  }

  /// Resolves the exact DateTime (including hour and minute) for the booking.
  static DateTime? _resolveAppointmentDateTime(
    BookingModel booking,
    DateTime selectedDate,
  ) {
    if (booking.appointmentTime != null) {
      return booking.appointmentTime;
    }

    final timeStr = booking.endTime ?? booking.startTime;
    if (timeStr != null && timeStr.contains(':')) {
      final parts = timeStr.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, h, m);
    }

    final date = booking.date ?? selectedDate;
    return DateTime(date.year, date.month, date.day, 12, 0);
  }

  /// Evaluates whether a booking matches a given status filter,
  /// guaranteeing 100% synchronization with card counts.
  static bool matchesStatusFilter(
    BookingModel booking,
    BookingStatusEnum? filterStatus, {
    required DateTime selectedDate,
    String? branchId,
    DateTime? currentTime,
  }) {
    if (!matchesBranch(booking, branchId)) return false;

    final now = currentTime ?? CairoTimeHelper.now();

    if (filterStatus == null) {
      // All statuses: matches anything on this date or postponed from this date
      return isPostponedToAnotherDate(booking, selectedDate) ||
          isCancelledForDate(booking, selectedDate) ||
          CairoTimeHelper.isSameDay(booking.appointmentTime ?? booking.date, selectedDate);
    }

    switch (filterStatus) {
      case BookingStatusEnum.noShow:
        return isNoShow(booking, selectedDate, now: now);

      case BookingStatusEnum.waiting:
        final apptDate = booking.appointmentTime ?? booking.date;
        return CairoTimeHelper.isSameDay(apptDate, selectedDate) &&
            booking.status == BookingStatusEnum.waiting &&
            !isNoShow(booking, selectedDate, now: now);

      case BookingStatusEnum.inConsultation:
        final apptDate = booking.appointmentTime ?? booking.date;
        return CairoTimeHelper.isSameDay(apptDate, selectedDate) &&
            booking.status == BookingStatusEnum.inConsultation;

      case BookingStatusEnum.completed:
        final apptDate = booking.appointmentTime ?? booking.date;
        return CairoTimeHelper.isSameDay(apptDate, selectedDate) &&
            booking.status == BookingStatusEnum.completed;

      case BookingStatusEnum.cancelled:
        return isCancelledForDate(booking, selectedDate);

      case BookingStatusEnum.postponed:
        return isPostponedToAnotherDate(booking, selectedDate);
    }
  }
}

