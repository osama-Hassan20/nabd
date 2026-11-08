import 'package:eyadty/features/doctors/data/models/doctor_break_time_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_work_day_model.dart';
import 'doctor_availability_helper.dart';

class DoctorScheduleValidator {
  /// تحويل وقت بصيغة HH:mm إلى دقائق من بداية اليوم
  static int? timeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    final parts = timeStr.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  /// التحقق من صحة يوم عمل للطبيب
  /// يرجع مفتاح الترجمة للخطأ أو null إذا كان صالحاً
  static String? validateWorkDay(DoctorWorkDayModel day) {
    if (day.isWorking != true) return null;

    final startMin = timeToMinutes(day.startTime);
    final endMin = timeToMinutes(day.endTime);

    if (startMin == null || endMin == null) {
      return 'work_hours_required';
    }

    if (startMin >= endMin) {
      return 'start_time_must_be_before_end';
    }

    final breaks = day.breaks ?? [];
    for (int i = 0; i < breaks.length; i++) {
      final b = breaks[i];
      final bStart = timeToMinutes(b.startTime);
      final bEnd = timeToMinutes(b.endTime);

      if (bStart == null || bEnd == null) {
        return 'break_hours_required';
      }

      if (bStart >= bEnd) {
        return 'break_start_must_be_before_end';
      }

      if (bStart < startMin || bEnd > endMin) {
        return 'break_must_be_within_working_hours';
      }
    }

    // التحقق من عدم تداخل الاستراحات
    if (breaks.length > 1) {
      final sortedBreaks = List<DoctorBreakTimeModel>.from(breaks)
        ..sort((a, b) => (timeToMinutes(a.startTime) ?? 0)
            .compareTo(timeToMinutes(b.startTime) ?? 0));

      for (int i = 0; i < sortedBreaks.length - 1; i++) {
        final currentEnd = timeToMinutes(sortedBreaks[i].endTime) ?? 0;
        final nextStart = timeToMinutes(sortedBreaks[i + 1].startTime) ?? 0;
        if (currentEnd > nextStart) {
          return 'breaks_cannot_overlap';
        }
      }
    }

    return null;
  }

  /// التحقق من صلاحية جدول الدوام بالكامل
  static String? validateSchedule(DoctorScheduleModel schedule) {
    if (schedule.doctorId == null || schedule.doctorId!.isEmpty) {
      return 'doctor_id_required';
    }

    final slot = schedule.slotDurationMinutes;
    if (slot != null && (slot < 5 || slot > 120)) {
      return 'slot_duration_invalid_range';
    }

    final buffer = schedule.bufferDurationMinutes;
    if (buffer != null && (buffer < 0 || buffer > 60)) {
      return 'buffer_duration_invalid_range';
    }

    if (schedule.workDays != null) {
      for (final day in schedule.workDays!) {
        final err = validateWorkDay(day);
        if (err != null) return err;
      }
    }

    return null;
  }

  /// التحقق من صلاحية إجازة الطبيب
  static String? validateLeave({
    required DoctorLeaveModel leave,
    required List<DoctorLeaveModel> existingLeaves,
    DateTime? customNow,
  }) {
    if (leave.doctorId == null || leave.doctorId!.isEmpty) {
      return 'doctor_id_required';
    }

    if (leave.startDate == null || leave.endDate == null) {
      return 'leave_dates_required';
    }

    final start = DoctorAvailabilityHelper.dateOnly(leave.startDate!);
    final end = DoctorAvailabilityHelper.dateOnly(leave.endDate!);

    if (end.isBefore(start)) {
      return 'leave_end_before_start';
    }

    final today = DoctorAvailabilityHelper.getTodayCairo(customNow);
    if (start.isBefore(today)) {
      return 'leave_start_in_past';
    }

    // فحص عدم تداخل الإجازة مع إجازة أخرى لنفس الطبيب
    for (final other in existingLeaves) {
      if (other.id == leave.id) continue;
      if (other.doctorId != leave.doctorId) continue;
      if (other.startDate == null || other.endDate == null) continue;

      final otherStart = DoctorAvailabilityHelper.dateOnly(other.startDate!);
      final otherEnd = DoctorAvailabilityHelper.dateOnly(other.endDate!);

      final overlaps = !(end.isBefore(otherStart) || start.isAfter(otherEnd));
      if (overlaps) {
        return 'leave_overlaps_existing';
      }
    }

    return null;
  }
}
