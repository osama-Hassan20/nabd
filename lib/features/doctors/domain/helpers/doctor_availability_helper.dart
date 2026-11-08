import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/doctors/data/models/doctor_break_time_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/doctors/data/models/enums/doctor_availability_enum.dart';
import 'package:eyadty/features/doctors/data/models/enums/week_day_enum.dart';
import 'package:eyadty/features/settings/data/models/special_holiday_model.dart';

/// DoctorAvailabilityHelper: مساعد نقي (Pure Dart) لتحديد توفر وساعات عمل الطبيب
///
/// جميع الحسابات تجري بالتاريخ فقط (دون الوقت) وبتوقيت القاهرة الرسمي،
/// مع دعم حقن التاريخ والوقت للاختبارات المستقلة.
class DoctorAvailabilityHelper {
  /// ترجيع تاريخ مجرد بدون أوقات (00:00:00) للمقارنة الدقيقة
  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// هل التاريخ المحدد يوم عمل وفق جدول الطبيب
  static bool isWorkingDay(DoctorScheduleModel? schedule, DateTime date) {
    if (schedule == null || schedule.workDays == null) return false;
    final targetDay = WeekDayEnum.fromDateTime(date);

    for (final wd in schedule.workDays!) {
      if (wd.dayOfWeek == targetDay) {
        return wd.isWorking == true;
      }
    }
    return false;
  }

  /// هل الطبيب في إجازة في هذا التاريخ
  static bool isOnLeave(List<DoctorLeaveModel>? leaves, DateTime date) {
    if (leaves == null || leaves.isEmpty) return false;
    final target = dateOnly(date);

    for (final leave in leaves) {
      if (leave.startDate == null || leave.endDate == null) continue;
      final start = dateOnly(leave.startDate!);
      final end = dateOnly(leave.endDate!);

      if (!target.isBefore(start) && !target.isAfter(end)) {
        return true;
      }
    }
    return false;
  }

  /// هل التاريخ عطلة رسمية أو عطلة للمنشأة
  static bool isFacilityHoliday(
    List<SpecialHolidayModel>? holidays,
    DateTime date,
  ) {
    if (holidays == null || holidays.isEmpty) return false;
    final target = dateOnly(date);

    for (final holiday in holidays) {
      if (holiday.startDate == null) continue;
      final start = dateOnly(holiday.startDate!);
      final end = holiday.endDate != null
          ? dateOnly(holiday.endDate!)
          : start;

      if (!target.isBefore(start) && !target.isAfter(end)) {
        return true;
      }
    }
    return false;
  }

  /// تحديد حالة توفر الطبيب في يوم معين وفق ترتيب الأولوية الصارم:
  /// 1. عطلة المنشأة (facilityHoliday)
  /// 2. إجازة الطبيب (onLeave)
  /// 3. لم يحدد دوام (noSchedule)
  /// 4. ليس يوم عمل (notWorkingDay)
  /// 5. متاح (available)
  static DoctorAvailabilityEnum getDayAvailability({
    DoctorScheduleModel? schedule,
    List<DoctorLeaveModel>? leaves,
    List<SpecialHolidayModel>? holidays,
    required DateTime date,
    DateTime? customNow,
  }) {
    if (isFacilityHoliday(holidays, date)) {
      return DoctorAvailabilityEnum.facilityHoliday;
    }

    if (isOnLeave(leaves, date)) {
      return DoctorAvailabilityEnum.onLeave;
    }

    if (schedule == null ||
        schedule.workDays == null ||
        schedule.workDays!.isEmpty) {
      return DoctorAvailabilityEnum.noSchedule;
    }

    if (!isWorkingDay(schedule, date)) {
      return DoctorAvailabilityEnum.notWorkingDay;
    }

    return DoctorAvailabilityEnum.available;
  }

  /// استرجاع ساعات واستراحات العمل ليوم محدد، أو null إن لم يكن يوم عمل
  static ({
    String startTime,
    String endTime,
    List<DoctorBreakTimeModel> breaks,
  })? getWorkingHours(DoctorScheduleModel? schedule, DateTime date) {
    if (schedule == null || schedule.workDays == null) return null;
    final targetDay = WeekDayEnum.fromDateTime(date);

    for (final wd in schedule.workDays!) {
      if (wd.dayOfWeek == targetDay &&
          wd.isWorking == true &&
          wd.startTime != null &&
          wd.endTime != null) {
        return (
          startTime: wd.startTime!,
          endTime: wd.endTime!,
          breaks: wd.breaks ?? const [],
        );
      }
    }
    return null;
  }

  /// الحصول على تاريخ اليوم الحالي بتوقيت القاهرة مع دعم حقن customNow
  static DateTime getTodayCairo([DateTime? customNow]) {
    final now = customNow ?? CairoTimeHelper.now();
    return dateOnly(now);
  }
}

