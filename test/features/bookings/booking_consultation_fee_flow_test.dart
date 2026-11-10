import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/use_cases/create_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_by_id_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/update_booking_use_case.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/patients/domain/use_cases/get_patients_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctors_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_summary_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/patients/data/repo/patients_mock_repo_impl.dart';
import 'package:eyadty/features/doctors/data/repo/doctors_mock_repo_impl.dart';

void main() {
  group('Booking Consultation Fee Flow Tests (Removal of hourlyRate)', () {
    late BookingsMockRepoImpl repo;
    late CreateBookingUseCase createBookingUseCase;
    late UpdateBookingUseCase updateBookingUseCase;
    late GetBookingByIdUseCase getBookingByIdUseCase;

    setUp(() {
      repo = BookingsMockRepoImpl();
      createBookingUseCase = CreateBookingUseCase(repo: repo);
      updateBookingUseCase = UpdateBookingUseCase(repo: repo);
      getBookingByIdUseCase = GetBookingByIdUseCase(repo: repo);
    });

    test('1. Direct Mock Repo: Saving consultationFee stores and retrieves correctly', () async {
      final newBooking = BookingModel(
        patientId: 'PAT-TEST-1',
        patientName: 'أحمد محمود',
        patientPhone: '+201012345678',
        doctorId: 'DOC-01',
        doctorName: 'د. حسام مصطفى',
        serviceName: 'كشف باطنة عامة',
        consultationFee: 250,
        totalPrice: 250,
        date: CairoTimeHelper.now().add(const Duration(days: 1)),
        startTime: '10:00',
        endTime: '10:30',
        durationMinutes: 30,
        status: BookingStatusEnum.scheduled,
        paymentStatus: PaymentStatusEnum.paid,
      );

      final createResult = await createBookingUseCase(newBooking);
      expect(createResult.isRight(), isTrue);

      final createdBooking = createResult.getOrElse(() => throw Exception());
      expect(createdBooking.id, isNotNull);
      expect(createdBooking.consultationFee, 250);
      expect(createdBooking.totalPrice, 250);

      // Verify retrieval by ID simulates details page load
      final fetchResult = await getBookingByIdUseCase(createdBooking.id!);
      expect(fetchResult.isRight(), isTrue);
      final fetched = fetchResult.getOrElse(() => throw Exception());

      expect(fetched.consultationFee, 250);
      expect(fetched.totalPrice, 250);
    });

    test('2. Direct Mock Repo: Updating consultationFee persists to details', () async {
      final newBooking = BookingModel(
        patientId: 'PAT-TEST-2',
        patientName: 'منى خليل',
        consultationFee: 200,
        totalPrice: 200,
        date: CairoTimeHelper.now().add(const Duration(days: 1)),
        status: BookingStatusEnum.scheduled,
      );

      final createResult = await createBookingUseCase(newBooking);
      final created = createResult.getOrElse(() => throw Exception());

      // Update consultation fee to 350
      final updatedBooking = created.copyWith(
        consultationFee: 350,
        totalPrice: 350,
      );

      final updateResult = await updateBookingUseCase(updatedBooking);
      expect(updateResult.isRight(), isTrue);

      final fetchResult = await getBookingByIdUseCase(created.id!);
      final fetched = fetchResult.getOrElse(() => throw Exception());

      expect(fetched.consultationFee, 350);
      expect(fetched.totalPrice, 350);
    });

    test('3. Cubit Form Flow: Changing consultationFee updates price without hourly multiplication', () async {
      final patientsRepo = PatientsMockRepoImpl();
      final doctorsRepo = DoctorsMockRepoImpl();

      final cubit = BookingsCubit(
        getBookingSummaryUseCase: GetBookingSummaryUseCase(repo: repo),
        getBookingsUseCase: GetBookingsUseCase(repo: repo),
        getBookingByIdUseCase: getBookingByIdUseCase,
        createBookingUseCase: createBookingUseCase,
        updateBookingUseCase: updateBookingUseCase,
        changeBookingStatusUseCase: ChangeBookingStatusUseCase(repo: repo),
        reassignTechnicianUseCase: ReassignTechnicianUseCase(repo: repo),
        deleteBookingUseCase: DeleteBookingUseCase(repo: repo),
        getCustomersUseCase: GetPatientsUseCase(repo: patientsRepo),
        getTechniciansUseCase: GetDoctorsUseCase(repo: doctorsRepo),
      );

      // Initialize fresh booking form
      cubit.initBookingForm(null);
      expect(cubit.state.formState, isNotNull);

      // Set consultation fee to 300
      cubit.updateFormConsultationFee(300);
      expect(cubit.state.formState!.consultationFee, 300);
      expect(cubit.state.formState!.totalPrice, 300);

      // Set time 10:00 to 10:15 (15 minutes duration)
      // Duration MUST NOT divide or multiply consultation fee (old hourlyRate bug)
      cubit.updateFormStartTime('10:00');
      cubit.updateFormEndTime('10:15');

      expect(cubit.state.formState!.durationMinutes, 15);
      expect(cubit.state.formState!.consultationFee, 300);
      expect(cubit.state.formState!.totalPrice, 300); // Retains 300, not 300 * 15/60 = 75!
    });
  });
}
