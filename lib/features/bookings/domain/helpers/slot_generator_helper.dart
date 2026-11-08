import 'package:equatable/equatable.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/slot_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/time_slot_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/doctors/data/models/enums/doctor_availability_enum.dart';
import 'package:eyadty/features/doctors/domain/helpers/doctor_availability_helper.dart';
import 'package:eyadty/features/settings/data/models/special_holiday_model.dart';

/// نتيجة توليد الفترات ليوم محدد
class SlotGenerationResult extends Equatable {
  final DoctorAvailabilityEnum dayAvailability;
  final List<TimeSlotModel> slots;
  final String? closedReasonKey;
  final String? shiftStartTime;
  final String? shiftEndTime;
  final int slotIntervalMinutes;
  final int bufferMinutes;

  const SlotGenerationResult({
    this.dayAvailability = DoctorAvailabilityEnum.available,
    this.slots = const [],
    this.closedReasonKey,
    this.shiftStartTime,
    this.shiftEndTime,
    this.slotIntervalMinutes = 20,
    this.bufferMinutes = 0,
  });

  bool get isDayAvailable =>
      dayAvailability == DoctorAvailabilityEnum.available;

  @override
  List<Object?> get props => [
        dayAvailability,
        slots,
        closedReasonKey,
        shiftStartTime,
        shiftEndTime,
        slotIntervalMinutes,
        bufferMinutes,
      ];
}

/// SlotGeneratorHelper: مساعد نقي (Pure Dart) لتوليد فترات جدول الطبيب والتحقق من التوفر
class SlotGeneratorHelper {
  SlotGeneratorHelper._();

  /// تحويل وقت بصيغة 24 ساعة (HH:mm) إلى دقائق من منتصف الليل
  static int timeToMinutes(String? time) {
    if (time == null || time.isEmpty) return 0;
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  /// تحويل عدد الدقائق من منتصف الليل إلى صيغة 24 ساعة (HH:mm)
  static String minutesToTime(int minutes) {
    final clamped = minutes.clamp(0, 24 * 60 - 1);
    final h = clamped ~/ 60;
    final m = clamped % 60;
    final hStr = h.toString().padLeft(2, '0');
    final mStr = m.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }

  /// هل الحجز من الحالات التي تشغل فترة زمنية فعلية
  ///
  /// الحالات التي تشغل: waiting, inConsultation, completed.
  /// الحالات التي لا تشغل: cancelled, postponed, noShow.
  static bool isBookingOccupyingSlot(BookingStatusEnum? status) {
    if (status == null) return false;
    switch (status) {
      case BookingStatusEnum.waiting:
      case BookingStatusEnum.inConsultation:
      case BookingStatusEnum.completed:
        return true;
      case BookingStatusEnum.cancelled:
      case BookingStatusEnum.postponed:
      case BookingStatusEnum.noShow:
        return false;
    }
  }

  /// توليد الفترات الزمنية لطبيب في تاريخ معين بناءً على الخدمة الطبية
  static SlotGenerationResult generateSlots({
    required DoctorScheduleModel? schedule,
    required List<DoctorLeaveModel>? leaves,
    required List<SpecialHolidayModel>? holidays,
    required List<BookingModel>? doctorBookings,
    required int serviceDurationMinutes,
    required DateTime date,
    DateTime? customNow,
    String? excludeBookingId,
    String? currentBookingStartTime,
    String? currentBookingEndTime,
  }) {
    // 1. التحقق من توفر اليوم للطبيب وفق أولويات DoctorAvailabilityHelper
    final dayAvailability = DoctorAvailabilityHelper.getDayAvailability(
      schedule: schedule,
      leaves: leaves,
      holidays: holidays,
      date: date,
      customNow: customNow,
    );

    if (dayAvailability != DoctorAvailabilityEnum.available) {
      String closedReasonKey;
      switch (dayAvailability) {
        case DoctorAvailabilityEnum.facilityHoliday:
          closedReasonKey = 'facility_holiday';
          break;
        case DoctorAvailabilityEnum.onLeave:
          closedReasonKey = 'on_leave';
          break;
        case DoctorAvailabilityEnum.noSchedule:
          closedReasonKey = 'no_schedule';
          break;
        case DoctorAvailabilityEnum.notWorkingDay:
          closedReasonKey = 'not_working_day';
          break;
        case DoctorAvailabilityEnum.available:
          closedReasonKey = '';
          break;
      }
      return SlotGenerationResult(
        dayAvailability: dayAvailability,
        slots: const [],
        closedReasonKey: closedReasonKey,
      );
    }

    // 2. استخراج ساعات العمل والاستراحات
    final workingHours =
        DoctorAvailabilityHelper.getWorkingHours(schedule, date);
    if (workingHours == null) {
      return const SlotGenerationResult(
        dayAvailability: DoctorAvailabilityEnum.notWorkingDay,
        slots: [],
        closedReasonKey: 'not_working_day',
      );
    }

    final shiftStart = timeToMinutes(workingHours.startTime);
    final shiftEnd = timeToMinutes(workingHours.endTime);

    final slotInterval = (schedule?.slotDurationMinutes != null &&
            schedule!.slotDurationMinutes! > 0)
        ? schedule.slotDurationMinutes!
        : 20;

    final bufferDuration = (schedule?.bufferDurationMinutes != null &&
            schedule!.bufferDurationMinutes! >= 0)
        ? schedule.bufferDurationMinutes!
        : 0;

    final serviceDuration =
        serviceDurationMinutes > 0 ? serviceDurationMinutes : slotInterval;

    // 3. تحديد توقيت القاهرة والوقت الحالي للمقارنة
    final cairoToday = DoctorAvailabilityHelper.getTodayCairo(customNow);
    final targetDateOnly = DoctorAvailabilityHelper.dateOnly(date);
    final isPastDay = targetDateOnly.isBefore(cairoToday);
    final isToday = CairoTimeHelper.isSameDay(date, cairoToday);
    final cairoNow = customNow ?? CairoTimeHelper.now();
    final nowMinutes = cairoNow.hour * 60 + cairoNow.minute;

    // 4. تجميع الاستراحات
    final breaks = (workingHours.breaks).map((b) {
      return (
        start: timeToMinutes(b.startTime),
        end: timeToMinutes(b.endTime),
        name: b.name,
      );
    }).toList();

    // 5. تجميع الحجوزات النشطة المشغولة لنفس الطبيب في هذا اليوم
    final activeBookings = (doctorBookings ?? []).where((b) {
      if (b.id != null && b.id == excludeBookingId) return false;
      if (!isBookingOccupyingSlot(b.status)) return false;

      final bDate = b.date ?? b.appointmentTime;
      if (bDate == null) return false;
      return CairoTimeHelper.isSameDay(bDate, date);
    }).map((b) {
      final bStart = b.startTime != null && b.startTime!.isNotEmpty
          ? timeToMinutes(b.startTime)
          : (b.appointmentTime != null
              ? (b.appointmentTime!.hour * 60 + b.appointmentTime!.minute)
              : 0);

      final bDuration = (b.durationMinutes != null && b.durationMinutes! > 0)
          ? b.durationMinutes!
          : slotInterval;

      final bEnd = b.endTime != null && b.endTime!.isNotEmpty
          ? timeToMinutes(b.endTime)
          : (bStart + bDuration);

      final bOccupiedEnd = bEnd + bufferDuration;

      return (
        id: b.id,
        patientName: b.patientName ?? b.customer?.name ?? '',
        start: bStart,
        end: bEnd,
        occupiedEnd: bOccupiedEnd,
      );
    }).toList();

    // 6. توليد الفترات المرشحة من بداية الدوام كل slotInterval دقيقة
    final List<TimeSlotModel> slots = [];
    bool foundCurrentBookingSlot = false;

    for (int m = shiftStart; m < shiftEnd; m += slotInterval) {
      final slotStart = m;
      final slotEnd = m + serviceDuration;
      final slotOccupiedEnd = slotEnd + bufferDuration;
      final isMorning = slotStart < 12 * 60;
      final startStr = minutesToTime(slotStart);
      final endStr = minutesToTime(slotEnd);
      final occupiedEndStr = minutesToTime(slotOccupiedEnd);

      final isCurrent = currentBookingStartTime != null &&
          currentBookingStartTime.isNotEmpty &&
          timeToMinutes(currentBookingStartTime) == slotStart;

      if (isCurrent) {
        foundCurrentBookingSlot = true;
      }

      SlotStatusEnum status;
      String? bookedPatient;
      String? bookedId;
      String? reasonKey;

      if (isPastDay || (isToday && slotStart <= nowMinutes)) {
        // مضى وقته
        status = SlotStatusEnum.past;
        reasonKey = 'slot_past';
      } else if (breaks.any((brk) => slotStart >= brk.start && slotStart < brk.end)) {
        // يقع داخل استراحة الطبيب
        status = SlotStatusEnum.breakTime;
        reasonKey = 'slot_break_time';
      } else {
        // فحص التقاطع مع حجز نشط آخر
        final conflictingBooking = activeBookings.firstWhere(
          (b) => slotStart >= b.start && slotStart < b.occupiedEnd,
          orElse: () => (
            id: null,
            patientName: '',
            start: -1,
            end: -1,
            occupiedEnd: -1,
          ),
        );

        if (conflictingBooking.start != -1) {
          status = SlotStatusEnum.booked;
          bookedPatient = conflictingBooking.patientName;
          bookedId = conflictingBooking.id;
          reasonKey = 'slot_booked';
        } else if (slotEnd > shiftEnd || slotOccupiedEnd > shiftEnd) {
          // مدة الخدمة + الراحة تتجاوز نهاية الدوام
          status = SlotStatusEnum.insufficientTime;
          reasonKey = 'slot_insufficient_time';
        } else if (breaks.any((brk) => brk.start > slotStart && slotEnd > brk.start)) {
          // تتقاطع مدة الخدمة مع بداية استراحة قادمة
          status = SlotStatusEnum.insufficientTime;
          reasonKey = 'slot_insufficient_time';
        } else if (activeBookings.any((b) => b.start > slotStart && slotOccupiedEnd > b.start)) {
          // مدة الخدمة + الراحة تصطدم بحجز قادم قبل الانتهاء
          status = SlotStatusEnum.insufficientTime;
          reasonKey = 'slot_insufficient_time';
        } else {
          status = SlotStatusEnum.available;
          reasonKey = 'slot_available';
        }
      }

      // إذا كان هذا هو حجز التعديل نفسه، يظل متاحاً له لحفظ التعديل دون تغيير الموعد
      if (isCurrent) {
        status = SlotStatusEnum.available;
      }

      slots.add(
        TimeSlotModel(
          startTime: startStr,
          endTime: endStr,
          occupiedEndTime: occupiedEndStr,
          status: status,
          bookedPatientName: bookedPatient,
          bookedBookingId: bookedId,
          serviceDurationMinutes: serviceDuration,
          bufferDurationMinutes: bufferDuration,
          isCurrentBookingSlot: isCurrent,
          reasonKey: reasonKey,
          isMorning: isMorning,
        ),
      );
    }

    // 7. معالجة الحجز القديم من الـ seed إن كان خارج شبكة الفترات
    if (currentBookingStartTime != null &&
        currentBookingStartTime.isNotEmpty &&
        !foundCurrentBookingSlot) {
      final currentStartM = timeToMinutes(currentBookingStartTime);
      final currentEndM = (currentBookingEndTime != null &&
              currentBookingEndTime.isNotEmpty)
          ? timeToMinutes(currentBookingEndTime)
          : currentStartM + serviceDuration;

      final legacySlot = TimeSlotModel(
        startTime: currentBookingStartTime,
        endTime: minutesToTime(currentEndM),
        occupiedEndTime: minutesToTime(currentEndM + bufferDuration),
        status: SlotStatusEnum.available,
        serviceDurationMinutes: serviceDuration,
        bufferDurationMinutes: bufferDuration,
        isCurrentBookingSlot: true,
        reasonKey: 'current_appointment',
        isMorning: currentStartM < 12 * 60,
      );

      // إدراج الحجز في ترتيبه الزمني بين الفترات
      int insertIndex = slots.indexWhere(
        (s) => timeToMinutes(s.startTime) > currentStartM,
      );
      if (insertIndex < 0) {
        slots.add(legacySlot);
      } else {
        slots.insert(insertIndex, legacySlot);
      }
    }

    return SlotGenerationResult(
      dayAvailability: DoctorAvailabilityEnum.available,
      slots: slots,
      shiftStartTime: workingHours.startTime,
      shiftEndTime: workingHours.endTime,
      slotIntervalMinutes: slotInterval,
      bufferMinutes: bufferDuration,
    );
  }

  /// التحقق النهائي من توفر فترة محددة قبل الحفظ
  static bool isSlotStillAvailable({
    required DoctorScheduleModel? schedule,
    required List<DoctorLeaveModel>? leaves,
    required List<SpecialHolidayModel>? holidays,
    required List<BookingModel>? doctorBookings,
    required int serviceDurationMinutes,
    required DateTime date,
    required String startTime,
    DateTime? customNow,
    String? excludeBookingId,
  }) {
    // 1. تحقق من توفر اليوم
    final dayAvailability = DoctorAvailabilityHelper.getDayAvailability(
      schedule: schedule,
      leaves: leaves,
      holidays: holidays,
      date: date,
      customNow: customNow,
    );
    if (dayAvailability != DoctorAvailabilityEnum.available) return false;

    // 2. تحقق من ساعات الدوام
    final workingHours =
        DoctorAvailabilityHelper.getWorkingHours(schedule, date);
    if (workingHours == null) return false;

    final shiftStart = timeToMinutes(workingHours.startTime);
    final shiftEnd = timeToMinutes(workingHours.endTime);
    final slotStart = timeToMinutes(startTime);

    final slotInterval = (schedule?.slotDurationMinutes != null &&
            schedule!.slotDurationMinutes! > 0)
        ? schedule.slotDurationMinutes!
        : 20;

    final bufferDuration = (schedule?.bufferDurationMinutes != null &&
            schedule!.bufferDurationMinutes! >= 0)
        ? schedule.bufferDurationMinutes!
        : 0;

    final serviceDuration =
        serviceDurationMinutes > 0 ? serviceDurationMinutes : slotInterval;

    final slotEnd = slotStart + serviceDuration;
    final slotOccupiedEnd = slotEnd + bufferDuration;

    // 3. لا يمكن الحجز خارج ساعات العمل
    if (slotStart < shiftStart || slotEnd > shiftEnd || slotOccupiedEnd > shiftEnd) {
      return false;
    }

    // 4. لا يمكن الحجز في وقت مضى
    final cairoToday = DoctorAvailabilityHelper.getTodayCairo(customNow);
    final targetDateOnly = DoctorAvailabilityHelper.dateOnly(date);
    if (targetDateOnly.isBefore(cairoToday)) return false;

    if (CairoTimeHelper.isSameDay(date, cairoToday)) {
      final cairoNow = customNow ?? CairoTimeHelper.now();
      final nowMinutes = cairoNow.hour * 60 + cairoNow.minute;
      if (slotStart <= nowMinutes) return false;
    }

    // 5. لا يتقاطع مع أي استراحة
    for (final brk in workingHours.breaks) {
      final brkStart = timeToMinutes(brk.startTime);
      final brkEnd = timeToMinutes(brk.endTime);

      // التقاطع: يبدأ أحدهما قبل نهاية الآخر
      if (slotStart < brkEnd && slotEnd > brkStart) {
        return false;
      }
    }

    // 6. لا يتقاطع مع أي حجز نشط آخر لنفس الطبيب
    for (final b in (doctorBookings ?? [])) {
      if (b.id != null && b.id == excludeBookingId) continue;
      if (!isBookingOccupyingSlot(b.status)) continue;

      final bDate = b.date ?? b.appointmentTime;
      if (bDate == null || !CairoTimeHelper.isSameDay(bDate, date)) continue;

      final bStart = b.startTime != null && b.startTime!.isNotEmpty
          ? timeToMinutes(b.startTime)
          : (b.appointmentTime != null
              ? (b.appointmentTime!.hour * 60 + b.appointmentTime!.minute)
              : 0);

      final bDuration = (b.durationMinutes != null && b.durationMinutes! > 0)
          ? b.durationMinutes!
          : slotInterval;

      final bEnd = b.endTime != null && b.endTime!.isNotEmpty
          ? timeToMinutes(b.endTime)
          : (bStart + bDuration);

      final bOccupiedEnd = bEnd + bufferDuration;

      // تقاطع الفترات المشغولة: [slotStart, slotOccupiedEnd) مع [bStart, bOccupiedEnd)
      if (slotStart < bOccupiedEnd && slotOccupiedEnd > bStart) {
        return false;
      }
    }

    return true;
  }

  /// فحص تعارض مواعيد المريض في نفس اليوم عبر جميع الأطباء
  static ({
    bool hasTimeConflict,
    bool hasSameDayNotice,
    BookingModel? conflictingBooking,
    BookingModel? sameDayBooking,
  }) checkPatientConflict({
    required List<BookingModel> allBookings,
    required String? patientId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? excludeBookingId,
  }) {
    if (patientId == null || patientId.isEmpty) {
      return (
        hasTimeConflict: false,
        hasSameDayNotice: false,
        conflictingBooking: null,
        sameDayBooking: null,
      );
    }

    final slotStart = timeToMinutes(startTime);
    final slotEnd = timeToMinutes(endTime);

    BookingModel? conflicting;
    BookingModel? sameDay;

    for (final b in allBookings) {
      if (b.id != null && b.id == excludeBookingId) continue;
      if (!isBookingOccupyingSlot(b.status)) continue;

      final bPatId = b.patientId ?? b.customer?.id ?? b.customerId;
      if (bPatId != patientId) continue;

      final bDate = b.date ?? b.appointmentTime;
      if (bDate == null || !CairoTimeHelper.isSameDay(bDate, date)) continue;

      final bStart = timeToMinutes(b.startTime);
      final bEnd = timeToMinutes(b.endTime);

      // تقاطع زمني صريح
      if (slotStart < bEnd && slotEnd > bStart) {
        conflicting = b;
        break;
      } else {
        sameDay ??= b;
      }
    }

    return (
      hasTimeConflict: conflicting != null,
      hasSameDayNotice: sameDay != null,
      conflictingBooking: conflicting,
      sameDayBooking: sameDay,
    );
  }
}

