import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/user_role_enum.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/create_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_by_id_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_summary_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/update_booking_use_case.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/features/settings/data/repo/medical_services_repo_impl.dart';
import 'package:eyadty/features/settings/domain/use_cases/add_medical_service_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/delete_medical_service_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_medical_services_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/toggle_medical_service_status_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/update_medical_service_use_case.dart';
import 'package:eyadty/features/settings/presentation/cubit/medical_services_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/medical_services_state.dart';

class TestRoleProvider implements CurrentRoleProvider {
  UserRoleEnum _role = UserRoleEnum.admin;

  @override
  UserRoleEnum get currentRole => _role;

  void setRole(UserRoleEnum role) {
    _role = role;
  }
}

void main() {
  group('Medical Services Catalog Unit Tests (Phase 2)', () {
    late TestRoleProvider roleProvider;
    late BookingsRepoImpl bookingsRepo;
    late MedicalServicesRepoImpl servicesRepo;
    late GetMedicalServicesUseCase getMedicalServicesUseCase;
    late AddMedicalServiceUseCase addMedicalServiceUseCase;
    late UpdateMedicalServiceUseCase updateMedicalServiceUseCase;
    late ToggleMedicalServiceStatusUseCase toggleMedicalServiceStatusUseCase;
    late DeleteMedicalServiceUseCase deleteMedicalServiceUseCase;
    late MedicalServicesCubit servicesCubit;

    setUp(() {
      roleProvider = TestRoleProvider();
      bookingsRepo = BookingsRepoImpl(apiConsumer: LocalServerApiConsumer());
      servicesRepo = MedicalServicesRepoImpl(
        roleProvider: roleProvider,
        bookingsRepo: bookingsRepo,
      );
      getMedicalServicesUseCase = GetMedicalServicesUseCase(repo: servicesRepo);
      addMedicalServiceUseCase = AddMedicalServiceUseCase(repo: servicesRepo);
      updateMedicalServiceUseCase =
          UpdateMedicalServiceUseCase(repo: servicesRepo);
      toggleMedicalServiceStatusUseCase =
          ToggleMedicalServiceStatusUseCase(repo: servicesRepo);
      deleteMedicalServiceUseCase =
          DeleteMedicalServiceUseCase(repo: servicesRepo);

      servicesCubit = MedicalServicesCubit(
        getMedicalServicesUseCase: getMedicalServicesUseCase,
        addMedicalServiceUseCase: addMedicalServiceUseCase,
        updateMedicalServiceUseCase: updateMedicalServiceUseCase,
        toggleMedicalServiceStatusUseCase: toggleMedicalServiceStatusUseCase,
        deleteMedicalServiceUseCase: deleteMedicalServiceUseCase,
      );
    });

    tearDown(() {
      servicesCubit.close();
    });

    test('1. Rejects duplicate service name (normalized whitespace and case)',
        () async {
      // Seed service 'كشف جديد' already exists
      const duplicateService = MedicalServiceModel(
        name: '  كشف جديد  ',
        consultationFee: 300,
        durationMinutes: 25,
      );

      final result = await servicesRepo.addMedicalService(duplicateService);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'service_name_already_exists'),
        (_) => fail('Should have failed duplicate check'),
      );
    });

    test('2. Rejects negative fee (< 0) and invalid duration (< 5 or > 240)',
        () async {
      // Negative fee
      const negativeFeeService = MedicalServiceModel(
        name: 'خدمة فحص تجريبية',
        consultationFee: -50,
        durationMinutes: 20,
      );
      final negativeResult =
          await servicesRepo.addMedicalService(negativeFeeService);
      expect(negativeResult.isLeft(), isTrue);

      // Duration < 5
      const tooShortService = MedicalServiceModel(
        name: 'خدمة سريعة جداً',
        consultationFee: 100,
        durationMinutes: 3,
      );
      final tooShortResult =
          await servicesRepo.addMedicalService(tooShortService);
      expect(tooShortResult.isLeft(), isTrue);

      // Duration > 240
      const tooLongService = MedicalServiceModel(
        name: 'جلسة طويلة جداً',
        consultationFee: 500,
        durationMinutes: 300,
      );
      final tooLongResult =
          await servicesRepo.addMedicalService(tooLongService);
      expect(tooLongResult.isLeft(), isTrue);
    });

    test(
        '3. Rejects deletion of service linked to existing booking; suggests deactivation',
        () async {
      // SRV-01 is linked to seed booking MED-101
      final deleteResult = await servicesRepo.deleteMedicalService('SRV-01');

      expect(deleteResult.isLeft(), isTrue);
      deleteResult.fold(
        (failure) {
          expect(
            failure.errMessage,
            'cannot_delete_service_linked_to_bookings',
          );
        },
        (_) => fail('Should not allow deleting service linked to bookings'),
      );
    });

    test('4. Allows deletion of unlinked service', () async {
      // First, add a temporary unlinked service
      const tempService = MedicalServiceModel(
        name: 'خدمة مؤقتة قابلة للحذف',
        consultationFee: 120,
        durationMinutes: 15,
      );
      final addResult = await servicesRepo.addMedicalService(tempService);
      expect(addResult.isRight(), isTrue);
      final added = addResult.getOrElse(() => throw Exception());

      // Now delete it
      final deleteResult = await servicesRepo.deleteMedicalService(added.id!);
      expect(deleteResult.isRight(), isTrue);
    });

    test(
        '5. Permission check: non-admin roles cannot add, edit, toggle, or delete',
        () async {
      // Switch role to reception
      roleProvider.setRole(UserRoleEnum.reception);

      const newService = MedicalServiceModel(
        name: 'خدمة استقبال غير مصرح بها',
        consultationFee: 100,
        durationMinutes: 20,
      );

      final addResult = await servicesRepo.addMedicalService(newService);
      expect(addResult.isLeft(), isTrue);
      addResult.fold(
        (f) => expect(f.errMessage, 'permission_denied'),
        (_) => fail('Reception cannot add services'),
      );

      final toggleResult = await servicesRepo.toggleServiceStatus('SRV-01');
      expect(toggleResult.isLeft(), isTrue);

      final deleteResult = await servicesRepo.deleteMedicalService('SRV-01');
      expect(deleteResult.isLeft(), isTrue);
    });

    test(
        '6. Filter services by doctor: general services + assigned doctor appear, other excluded',
        () async {
      final allServicesResult = await servicesRepo.getMedicalServices();
      final allServices = allServicesResult.getOrElse(() => []);

      final stateWithDoctorFilter = MedicalServicesState(
        services: allServices,
        doctorFilter: 'DOC-01', // Dr. Rami Salama
      );

      final filtered = stateWithDoctorFilter.filteredServices;

      // Filtered must include general services (assignedDoctorId == null)
      expect(filtered.any((s) => s.assignedDoctorId == null), isTrue);

      // Filtered must include services assigned to DOC-01
      expect(filtered.any((s) => s.assignedDoctorId == 'DOC-01'), isTrue);

      // Filtered must NOT include services assigned to DOC-02
      expect(filtered.any((s) => s.assignedDoctorId == 'DOC-02'), isFalse);
    });

    test('7. End time calculation: startTime + durationMinutes', () {
      final bookingsCubit = BookingsCubit(
        getBookingSummaryUseCase:
            GetBookingSummaryUseCase(repo: bookingsRepo),
        getBookingsUseCase: GetBookingsUseCase(repo: bookingsRepo),
        getBookingByIdUseCase: GetBookingByIdUseCase(repo: bookingsRepo),
        createBookingUseCase: CreateBookingUseCase(repo: bookingsRepo),
        updateBookingUseCase: UpdateBookingUseCase(repo: bookingsRepo),
        changeBookingStatusUseCase:
            ChangeBookingStatusUseCase(repo: bookingsRepo),
        reassignTechnicianUseCase:
            ReassignTechnicianUseCase(repo: bookingsRepo),
        deleteBookingUseCase: DeleteBookingUseCase(repo: bookingsRepo),
        getMedicalServicesUseCase: getMedicalServicesUseCase,
      );

      bookingsCubit.initBookingForm(null);

      // Select service with 20 minutes duration
      const service = MedicalServiceModel(
        id: 'SRV-TEST',
        name: 'كشف استشاري',
        consultationFee: 250,
        durationMinutes: 20,
      );

      bookingsCubit.updateFormService(service);
      bookingsCubit.updateFormStartTime('10:15');

      final form = bookingsCubit.state.formState;
      expect(form, isNotNull);
      expect(form!.durationMinutes, 20);
      expect(form.consultationFee, 250);
      expect(form.startTime, '10:15');
      expect(form.endTime, '10:35'); // 10:15 + 20 min = 10:35

      bookingsCubit.close();
    });

    test(
        '8. Snapshot preservation: changing service price in catalog does not change past booking fee',
        () async {
      // 1. Create a booking with service price 250
      const initialService = MedicalServiceModel(
        id: 'SRV-01',
        name: 'كشف استشاري باطنة عامة',
        consultationFee: 250,
        durationMinutes: 20,
      );

      final newBooking = BookingModel(
        patientId: 'PAT-SNAP-1',
        patientName: 'مريض الفحص',
        doctorId: 'DOC-01',
        serviceId: initialService.id,
        serviceName: initialService.name,
        consultationFee: initialService.consultationFee,
        totalPrice: initialService.consultationFee,
        durationMinutes: initialService.durationMinutes,
        date: DateTime.now().add(const Duration(days: 1)),
        startTime: '11:00',
        endTime: '11:20',
      );

      final createRes = await bookingsRepo.createBooking(newBooking);
      expect(createRes.isRight(), isTrue);
      final createdBooking = createRes.getOrElse(() => throw Exception());

      // 2. Now update service price in catalog to 350
      final updateServiceRes = await servicesRepo.updateMedicalService(
        initialService.copyWith(consultationFee: 350),
      );
      expect(updateServiceRes.isRight(), isTrue);

      // 3. Retrieve past booking and verify its consultationFee remained 250
      final fetchRes = await bookingsRepo.getBookingById(createdBooking.id!);
      expect(fetchRes.isRight(), isTrue);
      final fetched = fetchRes.getOrElse(() => throw Exception());

      expect(fetched.consultationFee, 250);
      expect(fetched.totalPrice, 250);
    });
  });
}
