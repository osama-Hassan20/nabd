import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/booking_form_options_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/create_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_by_id_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_summary_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_doctor_bookings_for_date_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/update_booking_use_case.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/doctors/data/repo/doctors_mock_repo_impl.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_leaves_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_schedule_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctors_use_case.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/features/settings/data/repo/medical_services_mock_repo_impl.dart';
import 'package:eyadty/features/settings/data/repo/settings_mock_repo_impl.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_company_settings_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_medical_services_use_case.dart';

void main() {
  group('Repo & Cubit Slot Conflict & Booking Flow Tests', () {
    late BookingsMockRepoImpl bookingsRepo;
    late DoctorsMockRepoImpl doctorsRepo;
    late SettingsMockRepoImpl settingsRepo;
    late MedicalServicesMockRepoImpl medicalServicesRepo;
    late BookingsCubit cubit;

    final testDate = DateTime(2026, 11, 8); // الأحد
    final fixedNow = DateTime(2026, 11, 8, 8, 30); // 08:30 صباحاً

    setUp(() {
      CairoTimeHelper.setFixedClock(fixedNow);
      settingsRepo = SettingsMockRepoImpl();
      medicalServicesRepo = MedicalServicesMockRepoImpl();
      bookingsRepo = BookingsMockRepoImpl(settingsRepo: settingsRepo);
      doctorsRepo = DoctorsMockRepoImpl(
        bookingsRepo: bookingsRepo,
        settingsRepo: settingsRepo,
      );
      // ربط الـ bookingsRepo بالـ doctorsRepo للفحص المتبادل
      final dynamicRepo = BookingsMockRepoImpl(
        doctorsRepo: doctorsRepo,
        settingsRepo: settingsRepo,
      );
      bookingsRepo = dynamicRepo;

      cubit = BookingsCubit(
        getBookingSummaryUseCase: GetBookingSummaryUseCase(repo: bookingsRepo),
        getBookingsUseCase: GetBookingsUseCase(repo: bookingsRepo),
        getBookingByIdUseCase: GetBookingByIdUseCase(repo: bookingsRepo),
        createBookingUseCase: CreateBookingUseCase(repo: bookingsRepo),
        updateBookingUseCase: UpdateBookingUseCase(repo: bookingsRepo),
        changeBookingStatusUseCase: ChangeBookingStatusUseCase(repo: bookingsRepo),
        reassignTechnicianUseCase: ReassignTechnicianUseCase(repo: bookingsRepo),
        deleteBookingUseCase: DeleteBookingUseCase(repo: bookingsRepo),
        getDoctorsUseCase: GetDoctorsUseCase(repo: doctorsRepo),
        getMedicalServicesUseCase: GetMedicalServicesUseCase(repo: medicalServicesRepo),
        getDoctorScheduleUseCase: GetDoctorScheduleUseCase(repo: doctorsRepo),
        getDoctorLeavesUseCase: GetDoctorLeavesUseCase(repo: doctorsRepo),
        getCompanySettingsUseCase: GetCompanySettingsUseCase(repo: settingsRepo),
        getDoctorBookingsForDateUseCase: GetDoctorBookingsForDateUseCase(repo: bookingsRepo),
      );
    });

    tearDown(() {
      CairoTimeHelper.resetFixedClock();
      cubit.close();
    });

    test('1. Repo: Booking an occupied slot returns SlotConflictFailure', () async {
      // DOC-01 عنده حجز MED-101 اليوم من 10:00 إلى 10:30
      final conflictingBooking = BookingModel(
        doctorId: 'DOC-01',
        technicians: const [TechnicianModel(id: 'DOC-01', name: 'د. رامي سلامة')],
        patientId: 'PAT-000102',
        date: testDate,
        startTime: '10:00',
        endTime: '10:30',
        durationMinutes: 30,
        status: BookingStatusEnum.waiting,
      );

      final res = await bookingsRepo.createBooking(
        conflictingBooking,
        customNow: fixedNow,
      );

      expect(res.isLeft(), isTrue);
      res.fold((failure) {
        expect(failure, isA<SlotConflictFailure>());
        expect(failure.errMessage, 'slot_already_booked_or_unavailable');
      }, (_) => fail('Should have failed with SlotConflictFailure'));
    });

    test('2. Repo: Booking a past appointment time returns ValidationFailure', () async {
      // موعد الساعة 08:00 صباحاً بينما الوقت الحالي 08:30
      final pastBooking = BookingModel(
        doctorId: 'DOC-01',
        technicians: const [TechnicianModel(id: 'DOC-01', name: 'د. رامي سلامة')],
        patientId: 'PAT-000102',
        date: testDate,
        startTime: '08:00',
        endTime: '08:30',
        durationMinutes: 30,
        status: BookingStatusEnum.waiting,
      );

      final res = await bookingsRepo.createBooking(
        pastBooking,
        customNow: fixedNow,
      );

      expect(res.isLeft(), isTrue);
      res.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.errMessage, 'booking_time_in_past');
      }, (_) => fail('Should have failed with ValidationFailure'));
    });

    test('3. Repo: Updating a booking to the same appointment succeeds without self-conflict', () async {
      // MED-101 هو حجز موجود عند 10:00 لـ DOC-01
      final initialRes = await bookingsRepo.getBookingById('MED-101');
      expect(initialRes.isRight(), isTrue);

      final existing = initialRes.getOrElse(() => throw 'error');
      final updatedNote = existing.copyWith(notes: 'ملاحظة محدثة للتأكيد');

      final updateRes = await bookingsRepo.updateBooking(
        updatedNote,
        customNow: fixedNow,
      );

      expect(updateRes.isRight(), isTrue);
      updateRes.fold((l) => fail(l.errMessage), (r) {
        expect(r.notes, 'ملاحظة محدثة للتأكيد');
      });
    });

    test('4. Repo: Booking inside doctor break returns SlotConflictFailure', () async {
      // DOC-01 استراحته من 12:00 إلى 12:30
      final breakBooking = BookingModel(
        doctorId: 'DOC-01',
        technicians: const [TechnicianModel(id: 'DOC-01', name: 'د. رامي سلامة')],
        patientId: 'PAT-000103',
        date: testDate,
        startTime: '12:00',
        endTime: '12:30',
        durationMinutes: 30,
        status: BookingStatusEnum.waiting,
      );

      final res = await bookingsRepo.createBooking(
        breakBooking,
        customNow: fixedNow,
      );

      expect(res.isLeft(), isTrue);
      res.fold((failure) {
        expect(failure, isA<SlotConflictFailure>());
      }, (_) => fail('Should fail inside break'));
    });

    test('5. Cubit: Auto-loads slots when doctor, service, and date are present', () async {
      cubit.initBookingForm(null);

      // 1. اختيار الطبيب
      cubit.updateFormTechnician(
        const BookingTechnicianOption(id: 'DOC-01', name: 'د. رامي سلامة'),
      );
      // لم تكتمل المدخلات بعد (الخدمة غير محددة)
      expect(cubit.state.slotsStatus, RequestStatusEnum.initial);
      expect(cubit.state.availableSlots, isEmpty);

      // 2. اختيار الخدمة
      final slotsFuture = cubit.stream
          .firstWhere((s) => s.slotsStatus == RequestStatusEnum.success);
      cubit.updateFormService(
        const MedicalServiceModel(
          id: 'SRV-01',
          name: 'كشف استشاري باطنة عامة',
          durationMinutes: 30,
          consultationFee: 300,
        ),
      );

      // انتظر تحميل الفترات
      await slotsFuture;

      expect(cubit.state.slotsStatus, RequestStatusEnum.success);
      expect(cubit.state.availableSlots.isNotEmpty, isTrue);

      // الفترات تحتوي على فترات صباحية ومسائية
      expect(cubit.state.availableSlots.any((s) => s.isMorning == true), isTrue);
      expect(cubit.state.availableSlots.any((s) => s.isMorning == false), isTrue);
    });

    test('6. Cubit: Changing doctor or service clears selected slot and reloads', () async {
      cubit.initBookingForm(null);

      cubit.updateFormTechnician(
        const BookingTechnicianOption(id: 'DOC-01', name: 'د. رامي سلامة'),
      );
      final slotsFuture1 = cubit.stream
          .firstWhere((s) => s.slotsStatus == RequestStatusEnum.success);
      cubit.updateFormService(
        const MedicalServiceModel(
          id: 'SRV-01',
          name: 'كشف استشاري',
          durationMinutes: 30,
        ),
      );
      await slotsFuture1;

      // اختيار فترة
      final availableSlot = cubit.state.availableSlots.firstWhere((s) => s.isAvailable);
      cubit.selectTimeSlot(availableSlot);
      expect(cubit.state.formState?.startTime, availableSlot.startTime);

      // تغيير الطبيب -> يمسح الفترة المختارة ويعيد التحميل
      cubit.updateFormTechnician(
        const BookingTechnicianOption(id: 'DOC-02', name: 'د. نورهان السيد'),
      );
      expect(cubit.state.formState?.startTime, '');
      expect(cubit.state.formState?.endTime, '');
    });

    test('7. Cubit: Conflict on submit refreshes slots and retains form data', () async {
      cubit.initBookingForm(null);

      cubit.updateFormCustomer(
        const BookingCustomerOption(
          id: 'PAT-000101',
          name: 'سارة أحمد',
          phone: '+201012345678',
          address: 'القاهرة',
        ),
      );
      cubit.updateFormTechnician(
        const BookingTechnicianOption(id: 'DOC-01', name: 'د. رامي سلامة'),
      );
      final slotsFuture = cubit.stream
          .firstWhere((s) => s.slotsStatus == RequestStatusEnum.success);
      cubit.updateFormService(
        const MedicalServiceModel(
          id: 'SRV-01',
          name: 'كشف استشاري باطنة عامة',
          durationMinutes: 30,
        ),
      );
      await slotsFuture;

      // اختيار موعد 10:00 (وهو محجوز بالفعل في الـ repo لـ MED-101)
      cubit.updateFormStartTime('10:00');
      cubit.updateFormNotes('ملاحظات مهمة للتشخيص');

      final success = await cubit.submitBookingForm(customNow: fixedNow);
      expect(success, isFalse);

      // تم الحفاظ على الملاحظات والمريض والطبيب
      expect(cubit.state.formState?.notes, 'ملاحظات مهمة للتشخيص');
      expect(cubit.state.formState?.customer?.name, 'سارة أحمد');
      // تم مسح الفترة المتعارضة
      expect(cubit.state.formState?.startTime, '');
      // ظهر تنبيه الخطأ
      expect(cubit.state.actionStatus, RequestStatusEnum.failure);
      expect(cubit.state.errMessage, 'slot_already_booked_or_unavailable');
    });
  });
}

