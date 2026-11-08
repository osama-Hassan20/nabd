import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/slot_status_enum.dart';
import 'package:eyadty/features/bookings/domain/helpers/slot_generator_helper.dart';
import 'package:eyadty/features/doctors/data/models/doctor_break_time_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_work_day_model.dart';
import 'package:eyadty/features/doctors/data/models/enums/doctor_availability_enum.dart';
import 'package:eyadty/features/doctors/data/models/enums/week_day_enum.dart';
import 'package:eyadty/features/settings/data/models/special_holiday_model.dart';

void main() {
  group('SlotGeneratorHelper Pure Dart Unit Tests', () {
    // الأحد 8 نوفمبر 2026
    final sundayDate = DateTime(2026, 11, 8);
    // الجمعة 13 نوفمبر 2026
    final fridayDate = DateTime(2026, 11, 13);

    // جدول قياسي لطبيب: يعمل السبت إلى الخميس من 09:00 إلى 15:00، استراحة 12:00 إلى 12:30، الجمعة إجازة
    final standardSchedule = DoctorScheduleModel(
      id: 'SCHED-01',
      doctorId: 'DOC-01',
      slotDurationMinutes: 20, // فاصل البدء في الشبكة كل 20 دقيقة
      bufferDurationMinutes: 5, // راحة 5 دقائق
      workDays: [
        for (final day in WeekDayEnum.values)
          DoctorWorkDayModel(
            dayOfWeek: day,
            isWorking: day != WeekDayEnum.friday,
            startTime: day != WeekDayEnum.friday ? '09:00' : null,
            endTime: day != WeekDayEnum.friday ? '15:00' : null,
            breaks: day != WeekDayEnum.friday
                ? const [
                    DoctorBreakTimeModel(
                      name: 'استراحة صلاة وغداء',
                      startTime: '12:00',
                      endTime: '12:30',
                    ),
                  ]
                : null,
          ),
      ],
    );

    test('1. Working day without bookings generates correct candidate slots every slotDurationMinutes', () {
      final res = SlotGeneratorHelper.generateSlots(
        schedule: standardSchedule,
        leaves: const [],
        holidays: const [],
        doctorBookings: const [],
        serviceDurationMinutes: 20,
        date: sundayDate,
        customNow: DateTime(2026, 11, 1, 8, 0), // وقت سابق (ليس اليوم)
      );

      expect(res.dayAvailability, DoctorAvailabilityEnum.available);
      expect(res.slots.isNotEmpty, isTrue);

      // أول فترة 09:00، والفاصل 20 دقيقة
      expect(res.slots.first.startTime, '09:00');
      expect(res.slots[1].startTime, '09:20');
      expect(res.slots[2].startTime, '09:40');

      // مدة الخدمة 20 دقيقة -> نهاية الفترة 09:20
      expect(res.slots.first.endTime, '09:20');
      // وقت الانشغال = 20 + 5 دقائق راحة = 09:25
      expect(res.slots.first.occupiedEndTime, '09:25');
      expect(res.slots.first.status, SlotStatusEnum.available);
    });

    test('2. Break time detection: slots inside break are marked breakTime', () {
      final res = SlotGeneratorHelper.generateSlots(
        schedule: standardSchedule,
        leaves: const [],
        holidays: const [],
        doctorBookings: const [],
        serviceDurationMinutes: 20,
        date: sundayDate,
        customNow: DateTime(2026, 11, 1, 8, 0),
      );

      // الاستراحة من 12:00 إلى 12:30
      // الفترات التي تبدأ في 12:00 و 12:20 تقع داخل الاستراحة
      final slot1200 = res.slots.firstWhere((s) => s.startTime == '12:00');
      expect(slot1200.status, SlotStatusEnum.breakTime);

      final slot1220 = res.slots.firstWhere((s) => s.startTime == '12:20');
      expect(slot1220.status, SlotStatusEnum.breakTime);

      // الفترة التي تبدأ بعد الاستراحة مباشرة في 12:40 متاحة
      final slot1240 = res.slots.firstWhere((s) => s.startTime == '12:40');
      expect(slot1240.status, SlotStatusEnum.available);
    });

    test('3. Past slots detection for current Cairo date', () {
      // حقن "الآن": الساعة 10:15 صباح الأحد
      final nowCairo = DateTime(2026, 11, 8, 10, 15);

      final res = SlotGeneratorHelper.generateSlots(
        schedule: standardSchedule,
        leaves: const [],
        holidays: const [],
        doctorBookings: const [],
        serviceDurationMinutes: 20,
        date: sundayDate,
        customNow: nowCairo,
      );

      // الفترات 09:00 و 09:20 و 09:40 و 10:00 مضت (<= 10:15)
      expect(res.slots.firstWhere((s) => s.startTime == '09:00').status, SlotStatusEnum.past);
      expect(res.slots.firstWhere((s) => s.startTime == '09:20').status, SlotStatusEnum.past);
      expect(res.slots.firstWhere((s) => s.startTime == '09:40').status, SlotStatusEnum.past);
      expect(res.slots.firstWhere((s) => s.startTime == '10:00').status, SlotStatusEnum.past);

      // الفترة 10:20 لم تمضِ بعد (> 10:15) -> متاحة
      expect(res.slots.firstWhere((s) => s.startTime == '10:20').status, SlotStatusEnum.available);
    });

    test('4. Active booking occupies slot and reflects booked patient info', () {
      final activeBooking = BookingModel(
        id: 'BK-101',
        patientName: 'أحمد محمود',
        doctorId: 'DOC-01',
        date: sundayDate,
        startTime: '10:40',
        endTime: '11:10', // 30 دقيقة
        durationMinutes: 30,
        status: BookingStatusEnum.waiting,
      );

      final res = SlotGeneratorHelper.generateSlots(
        schedule: standardSchedule,
        leaves: const [],
        holidays: const [],
        doctorBookings: [activeBooking],
        serviceDurationMinutes: 20,
        date: sundayDate,
        customNow: DateTime(2026, 11, 1, 8, 0),
      );

      // الفترة 10:40 تتقاطع مع الحجز
      final slot1040 = res.slots.firstWhere((s) => s.startTime == '10:40');
      expect(slot1040.status, SlotStatusEnum.booked);
      expect(slot1040.bookedPatientName, 'أحمد محمود');
      expect(slot1040.bookedBookingId, 'BK-101');

      // الفترة 11:00 تقع ضمن وقت الكشف (10:40 إلى 11:10)
      final slot1100 = res.slots.firstWhere((s) => s.startTime == '11:00');
      expect(slot1100.status, SlotStatusEnum.booked);

      // الفترة 11:20:
      // الحجز ينتهي 11:10 + 5 دقائق راحة = 11:15
      // 11:20 تبدأ بعد انتهاء الراحة -> متاحة!
      final slot1120 = res.slots.firstWhere((s) => s.startTime == '11:20');
      expect(slot1120.status, SlotStatusEnum.available);
    });

    test('5. Non-occupying bookings (cancelled, postponed, noShow) do NOT occupy slots', () {
      final cancelledBooking = BookingModel(
        id: 'BK-CANCELLED',
        patientName: 'مريض ملغي',
        doctorId: 'DOC-01',
        date: sundayDate,
        startTime: '10:40',
        endTime: '11:00',
        status: BookingStatusEnum.cancelled,
      );

      final noShowBooking = BookingModel(
        id: 'BK-NOSHOW',
        patientName: 'مريض لم يحضر',
        doctorId: 'DOC-01',
        date: sundayDate,
        startTime: '11:00',
        endTime: '11:20',
        status: BookingStatusEnum.noShow,
      );

      final postponedBooking = BookingModel(
        id: 'BK-POSTPONED',
        patientName: 'مريض مؤجل',
        doctorId: 'DOC-01',
        date: sundayDate,
        startTime: '11:20',
        endTime: '11:40',
        status: BookingStatusEnum.postponed,
      );

      final res = SlotGeneratorHelper.generateSlots(
        schedule: standardSchedule,
        leaves: const [],
        holidays: const [],
        doctorBookings: [cancelledBooking, noShowBooking, postponedBooking],
        serviceDurationMinutes: 20,
        date: sundayDate,
        customNow: DateTime(2026, 11, 1, 8, 0),
      );

      expect(res.slots.firstWhere((s) => s.startTime == '10:40').status, SlotStatusEnum.available);
      expect(res.slots.firstWhere((s) => s.startTime == '11:00').status, SlotStatusEnum.available);
      expect(res.slots.firstWhere((s) => s.startTime == '11:20').status, SlotStatusEnum.available);
    });

    test('6. Insufficient time before shift end or upcoming break', () {
      // خدمة مدتها 40 دقيقة
      final res = SlotGeneratorHelper.generateSlots(
        schedule: standardSchedule,
        leaves: const [],
        holidays: const [],
        doctorBookings: const [],
        serviceDurationMinutes: 40,
        date: sundayDate,
        customNow: DateTime(2026, 11, 1, 8, 0),
      );

      // نهاية الدوام 15:00.
      // فترة 14:40 + 40 دقيقة خدمة = 15:20 (تتجاوز 15:00) -> insufficientTime!
      final slot1440 = res.slots.firstWhere((s) => s.startTime == '14:40');
      expect(slot1440.status, SlotStatusEnum.insufficientTime);

      // الاستراحة تبدأ 12:00.
      // فترة 11:40 + 40 دقيقة خدمة = 12:20 (تتجاوز بداية الاستراحة 12:00) -> insufficientTime!
      final slot1140 = res.slots.firstWhere((s) => s.startTime == '11:40');
      expect(slot1140.status, SlotStatusEnum.insufficientTime);
    });

    test('7. Closed day handling: doctor leave, facility holiday, non-working day, no schedule', () {
      // إجازة طبيب
      final leaveRes = SlotGeneratorHelper.generateSlots(
        schedule: standardSchedule,
        leaves: [
          DoctorLeaveModel(
            doctorId: 'DOC-01',
            startDate: sundayDate,
            endDate: sundayDate,
            reason: 'مؤتمر طبي',
          ),
        ],
        holidays: const [],
        doctorBookings: const [],
        serviceDurationMinutes: 20,
        date: sundayDate,
      );
      expect(leaveRes.dayAvailability, DoctorAvailabilityEnum.onLeave);
      expect(leaveRes.slots, isEmpty);

      // عطلة منشأة
      final holidayRes = SlotGeneratorHelper.generateSlots(
        schedule: standardSchedule,
        leaves: const [],
        holidays: [
          SpecialHolidayModel(
            name: 'عطلة رسمية',
            startDate: sundayDate,
            endDate: sundayDate,
          ),
        ],
        doctorBookings: const [],
        serviceDurationMinutes: 20,
        date: sundayDate,
      );
      expect(holidayRes.dayAvailability, DoctorAvailabilityEnum.facilityHoliday);
      expect(holidayRes.slots, isEmpty);

      // يوم غير دوام (الجمعة)
      final fridayRes = SlotGeneratorHelper.generateSlots(
        schedule: standardSchedule,
        leaves: const [],
        holidays: const [],
        doctorBookings: const [],
        serviceDurationMinutes: 20,
        date: fridayDate,
      );
      expect(fridayRes.dayAvailability, DoctorAvailabilityEnum.notWorkingDay);
      expect(fridayRes.slots, isEmpty);

      // لا دوام محدد
      final noSchedRes = SlotGeneratorHelper.generateSlots(
        schedule: null,
        leaves: const [],
        holidays: const [],
        doctorBookings: const [],
        serviceDurationMinutes: 20,
        date: sundayDate,
      );
      expect(noSchedRes.dayAvailability, DoctorAvailabilityEnum.noSchedule);
      expect(noSchedRes.slots, isEmpty);
    });

    test('8. Edit mode: excluding self booking and handling off-grid legacy seed booking', () {
      final existingBooking = BookingModel(
        id: 'BK-OFFGRID',
        patientName: 'مريض قديم',
        doctorId: 'DOC-01',
        date: sundayDate,
        startTime: '09:15', // وقت فردي خارج شبكة الـ 20 دقيقة
        endTime: '09:45',
        durationMinutes: 30,
        status: BookingStatusEnum.waiting,
      );

      final res = SlotGeneratorHelper.generateSlots(
        schedule: standardSchedule,
        leaves: const [],
        holidays: const [],
        doctorBookings: [existingBooking],
        serviceDurationMinutes: 20,
        date: sundayDate,
        excludeBookingId: 'BK-OFFGRID',
        currentBookingStartTime: '09:15',
        currentBookingEndTime: '09:45',
      );

      // الحجز القديم يظهر في القائمة كموعد حالي ومتاح للحفظ
      final legacySlot = res.slots.firstWhere((s) => s.startTime == '09:15');
      expect(legacySlot.isCurrentBookingSlot, isTrue);
      expect(legacySlot.status, SlotStatusEnum.available);
    });

    test('9. isSlotStillAvailable validation method', () {
      final activeBooking = BookingModel(
        id: 'BK-200',
        doctorId: 'DOC-01',
        date: sundayDate,
        startTime: '10:00',
        endTime: '10:30',
        durationMinutes: 30,
        status: BookingStatusEnum.waiting,
      );

      // فترة متعارضة مع الحجز
      final conflict = SlotGeneratorHelper.isSlotStillAvailable(
        schedule: standardSchedule,
        leaves: const [],
        holidays: const [],
        doctorBookings: [activeBooking],
        serviceDurationMinutes: 20,
        date: sundayDate,
        startTime: '10:00',
        customNow: DateTime(2026, 11, 1, 8, 0),
      );
      expect(conflict, isFalse);

      // فترة متاحة
      final available = SlotGeneratorHelper.isSlotStillAvailable(
        schedule: standardSchedule,
        leaves: const [],
        holidays: const [],
        doctorBookings: [activeBooking],
        serviceDurationMinutes: 20,
        date: sundayDate,
        startTime: '11:00',
        customNow: DateTime(2026, 11, 1, 8, 0),
      );
      expect(available, isTrue);

      // فترة في الماضي
      final past = SlotGeneratorHelper.isSlotStillAvailable(
        schedule: standardSchedule,
        leaves: const [],
        holidays: const [],
        doctorBookings: const [],
        serviceDurationMinutes: 20,
        date: sundayDate,
        startTime: '09:00',
        customNow: DateTime(2026, 11, 8, 10, 0),
      );
      expect(past, isFalse);
    });

    test('10. checkPatientConflict detects time overlap across doctors and same-day notices', () {
      final bookings = [
        BookingModel(
          id: 'BK-PAT-1',
          patientId: 'PAT-01',
          doctorId: 'DOC-02',
          doctorName: 'د. نورهان',
          date: sundayDate,
          startTime: '10:00',
          endTime: '10:30',
          status: BookingStatusEnum.waiting,
        ),
        BookingModel(
          id: 'BK-PAT-2',
          patientId: 'PAT-01',
          doctorId: 'DOC-03',
          doctorName: 'د. حازم',
          date: sundayDate,
          startTime: '14:00',
          endTime: '14:30',
          status: BookingStatusEnum.waiting,
        ),
      ];

      // فحص تقاطع زمني: حجز جديد من 10:15 إلى 10:45 (يتقاطع مع BK-PAT-1)
      final overlap = SlotGeneratorHelper.checkPatientConflict(
        allBookings: bookings,
        patientId: 'PAT-01',
        date: sundayDate,
        startTime: '10:15',
        endTime: '10:45',
      );
      expect(overlap.hasTimeConflict, isTrue);
      expect(overlap.conflictingBooking?.id, 'BK-PAT-1');

      // فحص موعد في نفس اليوم دون تقاطع: 11:30 إلى 12:00
      final sameDayNoOverlap = SlotGeneratorHelper.checkPatientConflict(
        allBookings: bookings,
        patientId: 'PAT-01',
        date: sundayDate,
        startTime: '11:30',
        endTime: '12:00',
      );
      expect(sameDayNoOverlap.hasTimeConflict, isFalse);
      expect(sameDayNoOverlap.hasSameDayNotice, isTrue);

      // استثناء الحجز نفسه عند التعديل
      final selfExclude = SlotGeneratorHelper.checkPatientConflict(
        allBookings: bookings,
        patientId: 'PAT-01',
        date: sundayDate,
        startTime: '10:00',
        endTime: '10:30',
        excludeBookingId: 'BK-PAT-1',
      );
      expect(selfExclude.hasTimeConflict, isFalse);
      expect(selfExclude.hasSameDayNotice, isTrue); // بسبب BK-PAT-2
    });
  });
}

