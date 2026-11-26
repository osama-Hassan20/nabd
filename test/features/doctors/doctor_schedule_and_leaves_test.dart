import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/enums/user_role_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/doctors/data/models/doctor_break_time_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_work_day_model.dart';
import 'package:eyadty/features/doctors/data/models/enums/doctor_availability_enum.dart';
import 'package:eyadty/features/doctors/data/models/enums/week_day_enum.dart';
import 'package:eyadty/features/doctors/data/repo/doctors_mock_repo_impl.dart';
import 'package:eyadty/features/doctors/domain/helpers/doctor_availability_helper.dart';
import 'package:eyadty/features/doctors/domain/helpers/doctor_schedule_validator.dart';
import 'package:eyadty/features/doctors/domain/use_cases/add_doctor_leave_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/add_doctor_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/delete_doctor_leave_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/delete_doctor_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_by_id_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_leaves_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_schedule_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctors_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/save_doctor_schedule_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/update_doctor_use_case.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/doctors/presentation/widgets/doctor_details_sections/doctor_upcoming_availability_widget.dart';
import 'package:eyadty/features/settings/data/models/special_holiday_model.dart';
import 'package:eyadty/features/settings/data/repo/settings_mock_repo_impl.dart';

class TestRoleProvider implements CurrentRoleProvider {
  UserRoleEnum _role = UserRoleEnum.admin;

  @override
  UserRoleEnum get currentRole => _role;

  void setRole(UserRoleEnum role) {
    _role = role;
  }
}

Widget wrapWithTestApp(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: false,
    child: MaterialApp(
      locale: const Locale('ar', 'EG'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('ar_EG', null);
    await EasyLocalization.ensureInitialized();
  });

  group('DoctorAvailabilityHelper Tests', () {
    final schedule = DoctorScheduleModel(
      doctorId: 'DOC-01',
      slotDurationMinutes: 30,
      bufferDurationMinutes: 10,
      isAcceptingWalkIns: true,
      workDays: [
        DoctorWorkDayModel(
          dayOfWeek: WeekDayEnum.saturday,
          isWorking: true,
          startTime: '09:00',
          endTime: '17:00',
          breaks: const [
            DoctorBreakTimeModel(
              name: 'Lunch',
              startTime: '13:00',
              endTime: '14:00',
            ),
          ],
        ),
        DoctorWorkDayModel(
          dayOfWeek: WeekDayEnum.sunday,
          isWorking: true,
          startTime: '09:00',
          endTime: '17:00',
        ),
        DoctorWorkDayModel(
          dayOfWeek: WeekDayEnum.friday,
          isWorking: false,
        ),
      ],
    );

    test('isWorkingDay returns true for configured working day', () {
      final sat = DateTime(2026, 11, 7); // Saturday
      expect(DoctorAvailabilityHelper.isWorkingDay(schedule, sat), isTrue);

      final fri = DateTime(2026, 11, 13); // Friday (isWorking: false)
      expect(DoctorAvailabilityHelper.isWorkingDay(schedule, fri), isFalse);

      final monday = DateTime(2026, 11, 9); // Monday (not in list)
      expect(DoctorAvailabilityHelper.isWorkingDay(schedule, monday), isFalse);
    });

    test('isOnLeave identifies dates on boundary and between start and end', () {
      final leaves = [
        DoctorLeaveModel(
          id: 'L-1',
          doctorId: 'DOC-01',
          startDate: DateTime(2026, 11, 10),
          endDate: DateTime(2026, 11, 12),
          reason: 'Conference',
        ),
      ];

      expect(DoctorAvailabilityHelper.isOnLeave(leaves, DateTime(2026, 11, 9)), isFalse);
      expect(DoctorAvailabilityHelper.isOnLeave(leaves, DateTime(2026, 11, 10)), isTrue);
      expect(DoctorAvailabilityHelper.isOnLeave(leaves, DateTime(2026, 11, 11)), isTrue);
      expect(DoctorAvailabilityHelper.isOnLeave(leaves, DateTime(2026, 11, 12)), isTrue);
      expect(DoctorAvailabilityHelper.isOnLeave(leaves, DateTime(2026, 11, 13)), isFalse);
    });

    test('isFacilityHoliday detects single day and range holidays', () {
      final holidays = [
        SpecialHolidayModel(
          id: 'H1',
          name: 'Revolution Day',
          startDate: DateTime(2026, 7, 23),
        ),
        SpecialHolidayModel(
          id: 'H2',
          name: 'Eid',
          startDate: DateTime(2026, 4, 10),
          endDate: DateTime(2026, 4, 13),
        ),
      ];

      expect(DoctorAvailabilityHelper.isFacilityHoliday(holidays, DateTime(2026, 7, 23)), isTrue);
      expect(DoctorAvailabilityHelper.isFacilityHoliday(holidays, DateTime(2026, 7, 24)), isFalse);
      expect(DoctorAvailabilityHelper.isFacilityHoliday(holidays, DateTime(2026, 4, 11)), isTrue);
      expect(DoctorAvailabilityHelper.isFacilityHoliday(holidays, DateTime(2026, 4, 14)), isFalse);
    });

    test('getDayAvailability follows strict 5-level priority order', () {
      final holiday = SpecialHolidayModel(
        id: 'H1',
        name: 'National Holiday',
        startDate: DateTime(2026, 11, 7), // Saturday
      );
      final leave = DoctorLeaveModel(
        id: 'L1',
        doctorId: 'DOC-01',
        startDate: DateTime(2026, 11, 7),
        endDate: DateTime(2026, 11, 8),
      );

      final sat = DateTime(2026, 11, 7);

      // 1. Holiday overrides both working day and leave
      expect(
        DoctorAvailabilityHelper.getDayAvailability(
          schedule: schedule,
          leaves: [leave],
          holidays: [holiday],
          date: sat,
        ),
        DoctorAvailabilityEnum.facilityHoliday,
      );

      // 2. Without holiday, leave overrides working day
      expect(
        DoctorAvailabilityHelper.getDayAvailability(
          schedule: schedule,
          leaves: [leave],
          holidays: [],
          date: sat,
        ),
        DoctorAvailabilityEnum.onLeave,
      );

      // 3. Without leave/holiday, returns available on Saturday
      expect(
        DoctorAvailabilityHelper.getDayAvailability(
          schedule: schedule,
          leaves: [],
          holidays: [],
          date: sat,
        ),
        DoctorAvailabilityEnum.available,
      );

      // 4. Non-working day returns notWorkingDay
      final fri = DateTime(2026, 11, 13);
      expect(
        DoctorAvailabilityHelper.getDayAvailability(
          schedule: schedule,
          leaves: [],
          holidays: [],
          date: fri,
        ),
        DoctorAvailabilityEnum.notWorkingDay,
      );

      // 5. Doctor with null schedule returns noSchedule
      expect(
        DoctorAvailabilityHelper.getDayAvailability(
          schedule: null,
          leaves: [],
          holidays: [],
          date: sat,
        ),
        DoctorAvailabilityEnum.noSchedule,
      );
    });

    test('getWorkingHours returns hours and breaks for working day only', () {
      final sat = DateTime(2026, 11, 7);
      final hours = DoctorAvailabilityHelper.getWorkingHours(schedule, sat);
      expect(hours, isNotNull);
      expect(hours!.startTime, '09:00');
      expect(hours.endTime, '17:00');
      expect(hours.breaks.length, 1);
      expect(hours.breaks.first.startTime, '13:00');

      final fri = DateTime(2026, 11, 13);
      expect(DoctorAvailabilityHelper.getWorkingHours(schedule, fri), isNull);
    });
  });

  group('DoctorScheduleValidator Tests', () {
    test('validateWorkDay catches invalid start/end times and break times', () {
      // Valid
      final validDay = DoctorWorkDayModel(
        dayOfWeek: WeekDayEnum.saturday,
        isWorking: true,
        startTime: '09:00',
        endTime: '17:00',
        breaks: const [
          DoctorBreakTimeModel(startTime: '12:00', endTime: '13:00'),
        ],
      );
      expect(DoctorScheduleValidator.validateWorkDay(validDay), isNull);

      // start >= end
      final invalidTimes = validDay.copyWith(startTime: '17:00', endTime: '09:00');
      expect(DoctorScheduleValidator.validateWorkDay(invalidTimes), 'start_time_must_be_before_end');

      // missing start/end
      final missingTimes = validDay.copyWith(startTime: '');
      expect(DoctorScheduleValidator.validateWorkDay(missingTimes), 'work_hours_required');

      // break outside working hours
      final breakOutside = validDay.copyWith(
        breaks: const [DoctorBreakTimeModel(startTime: '17:30', endTime: '18:00')],
      );
      expect(DoctorScheduleValidator.validateWorkDay(breakOutside), 'break_must_be_within_working_hours');

      // break start >= break end
      final invalidBreak = validDay.copyWith(
        breaks: const [DoctorBreakTimeModel(startTime: '14:00', endTime: '13:00')],
      );
      expect(DoctorScheduleValidator.validateWorkDay(invalidBreak), 'break_start_must_be_before_end');

      // overlapping breaks
      final overlappingBreaks = validDay.copyWith(
        breaks: const [
          DoctorBreakTimeModel(startTime: '12:00', endTime: '13:30'),
          DoctorBreakTimeModel(startTime: '13:00', endTime: '14:00'),
        ],
      );
      expect(DoctorScheduleValidator.validateWorkDay(overlappingBreaks), 'breaks_cannot_overlap');

      // non working day is always valid
      final nonWorking = validDay.copyWith(isWorking: false, startTime: null, endTime: null);
      expect(DoctorScheduleValidator.validateWorkDay(nonWorking), isNull);
    });

    test('validateSchedule catches invalid slot and buffer duration', () {
      const base = DoctorScheduleModel(
        doctorId: 'DOC-01',
        slotDurationMinutes: 30,
        bufferDurationMinutes: 10,
      );
      expect(DoctorScheduleValidator.validateSchedule(base), isNull);

      // Missing doctorId
      expect(
        DoctorScheduleValidator.validateSchedule(base.copyWith(doctorId: '')),
        'doctor_id_required',
      );

      // Slot < 5
      expect(
        DoctorScheduleValidator.validateSchedule(base.copyWith(slotDurationMinutes: 4)),
        'slot_duration_invalid_range',
      );

      // Slot > 120
      expect(
        DoctorScheduleValidator.validateSchedule(base.copyWith(slotDurationMinutes: 121)),
        'slot_duration_invalid_range',
      );

      // Buffer < 0
      expect(
        DoctorScheduleValidator.validateSchedule(base.copyWith(bufferDurationMinutes: -1)),
        'buffer_duration_invalid_range',
      );

      // Buffer > 60
      expect(
        DoctorScheduleValidator.validateSchedule(base.copyWith(bufferDurationMinutes: 61)),
        'buffer_duration_invalid_range',
      );
    });

    test('validateLeave enforces date ranges, future dates, and non-overlapping leaves', () {
      final now = DateTime(2026, 11, 7);
      final existing = [
        DoctorLeaveModel(
          id: 'L1',
          doctorId: 'DOC-01',
          startDate: DateTime(2026, 11, 15),
          endDate: DateTime(2026, 11, 20),
        ),
      ];

      // Valid leave
      final valid = DoctorLeaveModel(
        id: 'L2',
        doctorId: 'DOC-01',
        startDate: DateTime(2026, 11, 22),
        endDate: DateTime(2026, 11, 25),
      );
      expect(
        DoctorScheduleValidator.validateLeave(
          leave: valid,
          existingLeaves: existing,
          customNow: now,
        ),
        isNull,
      );

      // End before start
      final endBeforeStart = valid.copyWith(
        startDate: DateTime(2026, 11, 25),
        endDate: DateTime(2026, 11, 22),
      );
      expect(
        DoctorScheduleValidator.validateLeave(
          leave: endBeforeStart,
          existingLeaves: existing,
          customNow: now,
        ),
        'leave_end_before_start',
      );

      // Start in past
      final pastLeave = valid.copyWith(
        startDate: DateTime(2026, 11, 5),
        endDate: DateTime(2026, 11, 10),
      );
      expect(
        DoctorScheduleValidator.validateLeave(
          leave: pastLeave,
          existingLeaves: existing,
          customNow: now,
        ),
        'leave_start_in_past',
      );

      // Overlaps existing leave of same doctor
      final overlap = valid.copyWith(
        startDate: DateTime(2026, 11, 18),
        endDate: DateTime(2026, 11, 22),
      );
      expect(
        DoctorScheduleValidator.validateLeave(
          leave: overlap,
          existingLeaves: existing,
          customNow: now,
        ),
        'leave_overlaps_existing',
      );

      // Overlap with different doctor is allowed
      final diffDoctor = overlap.copyWith(doctorId: 'DOC-02');
      expect(
        DoctorScheduleValidator.validateLeave(
          leave: diffDoctor,
          existingLeaves: existing,
          customNow: now,
        ),
        isNull,
      );
    });
  });

  group('DoctorsMockRepoImpl Schedule & Leaves RBAC & Conflict Tests', () {
    late TestRoleProvider roleProvider;
    late BookingsMockRepoImpl bookingsRepo;
    late SettingsMockRepoImpl settingsRepo;
    late DoctorsMockRepoImpl doctorsRepo;

    setUp(() {
      roleProvider = TestRoleProvider();
      bookingsRepo = BookingsMockRepoImpl();
      settingsRepo = SettingsMockRepoImpl();
      doctorsRepo = DoctorsMockRepoImpl(
        roleProvider: roleProvider,
        bookingsRepo: bookingsRepo,
        settingsRepo: settingsRepo,
      );
    });

    test('Non-admin role cannot save doctor schedule', () async {
      roleProvider.setRole(UserRoleEnum.doctor);

      final schedule = DoctorScheduleModel(
        doctorId: 'DOC-01',
        slotDurationMinutes: 30,
        bufferDurationMinutes: 10,
        workDays: const [],
      );

      final result = await doctorsRepo.saveDoctorSchedule(schedule: schedule);
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should have failed with ValidationFailure'),
      );
    });

    test('Non-admin role cannot add or delete doctor leave', () async {
      roleProvider.setRole(UserRoleEnum.reception);

      final leave = DoctorLeaveModel(
        doctorId: 'DOC-01',
        startDate: DateTime(2026, 12, 1),
        endDate: DateTime(2026, 12, 5),
      );

      final addResult = await doctorsRepo.addDoctorLeave(leave: leave);
      expect(addResult.isLeft(), isTrue);
      addResult.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should have failed with ValidationFailure'),
      );

      final deleteResult = await doctorsRepo.deleteDoctorLeave(leaveId: 'LEAVE-01');
      expect(deleteResult.isLeft(), isTrue);
      deleteResult.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should have failed with ValidationFailure'),
      );
    });

    test('Admin can get initial seed schedules with realistic variety', () async {
      // DOC-01: morning shift
      final doc1Schedule = await doctorsRepo.getDoctorSchedule(doctorId: 'DOC-01');
      expect(doc1Schedule.isRight(), isTrue);
      doc1Schedule.fold((l) => fail(l.errMessage), (s) {
        expect(s, isNotNull);
        expect(s!.doctorId, 'DOC-01');
        expect(s.slotDurationMinutes, 20);
        expect(s.isAcceptingWalkIns, isTrue);
      });

      // DOC-02: split shift / break between shifts
      final doc2Schedule = await doctorsRepo.getDoctorSchedule(doctorId: 'DOC-02');
      expect(doc2Schedule.isRight(), isTrue);
      doc2Schedule.fold((l) => fail(l.errMessage), (s) {
        expect(s, isNotNull);
        expect(s!.workDays?.first.breaks?.length, 1);
      });

      // DOC-06: null schedule
      final doc6Schedule = await doctorsRepo.getDoctorSchedule(doctorId: 'DOC-06');
      expect(doc6Schedule.isRight(), isTrue);
      doc6Schedule.fold((l) => fail(l.errMessage), (s) {
        expect(s, isNull);
      });
    });

    test('Adding leave with conflicting active bookings returns ConflictingBookingsFailure if force is false', () async {
      roleProvider.setRole(UserRoleEnum.admin);

      final leaveDate = DateTime.now().add(const Duration(days: 25));
      final booking = BookingModel(
        id: 'TEST-BKG-1',
        doctorId: 'DOC-01',
        technicianId: 'DOC-01',
        technicianName: 'د. أحمد محمود',
        patientId: 'PAT-001',
        patientName: 'محمد أحمد علي',
        date: leaveDate,
        status: BookingStatusEnum.waiting,
      );
      await bookingsRepo.createBooking(booking);

      final leave = DoctorLeaveModel(
        doctorId: 'DOC-01',
        startDate: leaveDate,
        endDate: leaveDate,
        reason: 'Conference',
      );

      // 1. Without force -> should fail with ConflictingBookingsFailure
      final resultWithoutForce = await doctorsRepo.addDoctorLeave(leave: leave, force: false);
      expect(resultWithoutForce.isLeft(), isTrue);
      resultWithoutForce.fold(
        (failure) {
          expect(failure, isA<ConflictingBookingsFailure>());
          expect((failure as ConflictingBookingsFailure).conflictingCount, greaterThanOrEqualTo(1));
        },
        (_) => fail('Should have returned ConflictingBookingsFailure'),
      );

      // 2. With force -> should succeed
      final resultWithForce = await doctorsRepo.addDoctorLeave(leave: leave, force: true);
      expect(resultWithForce.isRight(), isTrue);
    });
  });

  group('DoctorsCubit Schedule & Leaves Flow Tests', () {
    late TestRoleProvider roleProvider;
    late BookingsMockRepoImpl bookingsRepo;
    late SettingsMockRepoImpl settingsRepo;
    late DoctorsMockRepoImpl doctorsRepo;
    late DoctorsCubit cubit;

    setUp(() {
      roleProvider = TestRoleProvider();
      bookingsRepo = BookingsMockRepoImpl();
      settingsRepo = SettingsMockRepoImpl();
      doctorsRepo = DoctorsMockRepoImpl(
        roleProvider: roleProvider,
        bookingsRepo: bookingsRepo,
        settingsRepo: settingsRepo,
      );

      cubit = DoctorsCubit(
        getDoctorsUseCase: GetDoctorsUseCase(repo: doctorsRepo),
        getDoctorByIdUseCase: GetDoctorByIdUseCase(repo: doctorsRepo),
        addDoctorUseCase: AddDoctorUseCase(repo: doctorsRepo),
        updateDoctorUseCase: UpdateDoctorUseCase(repo: doctorsRepo),
        deleteDoctorUseCase: DeleteDoctorUseCase(repo: doctorsRepo),
        getDoctorLeavesUseCase: GetDoctorLeavesUseCase(repo: doctorsRepo),
        addDoctorLeaveUseCase: AddDoctorLeaveUseCase(repo: doctorsRepo),
        deleteDoctorLeaveUseCase: DeleteDoctorLeaveUseCase(repo: doctorsRepo),
        getDoctorScheduleUseCase: GetDoctorScheduleUseCase(repo: doctorsRepo),
        saveDoctorScheduleUseCase: SaveDoctorScheduleUseCase(repo: doctorsRepo),
        getBookingsUseCase: GetBookingsUseCase(repo: bookingsRepo),
        changeBookingStatusUseCase: ChangeBookingStatusUseCase(repo: bookingsRepo),
        reassignTechnicianUseCase: ReassignTechnicianUseCase(repo: bookingsRepo),
        deleteBookingUseCase: DeleteBookingUseCase(repo: bookingsRepo),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initScheduleForm creates 7 work days starting from Saturday', () async {
      await cubit.initScheduleForm('DOC-01');

      final form = cubit.state.scheduleFormState;
      expect(form, isNotNull);
      expect(form!.doctorId, 'DOC-01');
      expect(form.workDays.length, 7);
      expect(form.workDays.containsKey(WeekDayEnum.saturday), isTrue);
      expect(form.workDays.containsKey(WeekDayEnum.friday), isTrue);
    });

    test('copyDayToOtherWorkDays copies hours and breaks to all active days', () async {
      await cubit.initScheduleForm('DOC-01');

      // Update Saturday with specific times and break
      cubit.updateDayHours(WeekDayEnum.saturday, '08:30', '16:30');
      cubit.addDayBreak(
        WeekDayEnum.saturday,
        const DoctorBreakTimeModel(name: 'Lunch', startTime: '12:00', endTime: '13:00'),
      );

      // Copy Saturday to all other active days
      cubit.copyDayToOtherWorkDays(WeekDayEnum.saturday);

      final form = cubit.state.scheduleFormState!;
      // Sunday is working day
      final sunday = form.workDays[WeekDayEnum.sunday];
      expect(sunday, isNotNull);
      expect(sunday!.startTime, '08:30');
      expect(sunday.endTime, '16:30');
      expect(sunday.breaks.length, 2);
      expect(sunday.breaks.first.startTime, '12:00');
    });

    test('saveSchedule saves valid schedule successfully', () async {
      await cubit.initScheduleForm('DOC-01');
      final success = await cubit.saveSchedule();
      expect(success, isTrue);
    });
  });

  group('DoctorUpcomingAvailabilityWidget Widget Tests', () {
    testWidgets('renders 14 days with day labels and status badges', (tester) async {
      final schedule = DoctorScheduleModel(
        doctorId: 'DOC-01',
        workDays: [
          DoctorWorkDayModel(
            dayOfWeek: WeekDayEnum.saturday,
            isWorking: true,
            startTime: '09:00',
            endTime: '17:00',
          ),
          DoctorWorkDayModel(
            dayOfWeek: WeekDayEnum.sunday,
            isWorking: true,
            startTime: '09:00',
            endTime: '17:00',
          ),
          DoctorWorkDayModel(
            dayOfWeek: WeekDayEnum.monday,
            isWorking: true,
            startTime: '09:00',
            endTime: '17:00',
          ),
          DoctorWorkDayModel(
            dayOfWeek: WeekDayEnum.tuesday,
            isWorking: true,
            startTime: '09:00',
            endTime: '17:00',
          ),
          DoctorWorkDayModel(
            dayOfWeek: WeekDayEnum.wednesday,
            isWorking: true,
            startTime: '09:00',
            endTime: '17:00',
          ),
          DoctorWorkDayModel(
            dayOfWeek: WeekDayEnum.thursday,
            isWorking: true,
            startTime: '09:00',
            endTime: '17:00',
          ),
          DoctorWorkDayModel(
            dayOfWeek: WeekDayEnum.friday,
            isWorking: false,
          ),
        ],
      );

      await tester.pumpWidget(
        wrapWithTestApp(
          DoctorUpcomingAvailabilityWidget(
            schedule: schedule,
            leaves: const [],
            holidays: const [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DoctorUpcomingAvailabilityWidget), findsOneWidget);
    });
  });
}
