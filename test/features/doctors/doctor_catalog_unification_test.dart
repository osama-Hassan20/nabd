import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/features/doctors/data/repo/doctors_mock_repo_impl.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/settings/data/repo/medical_services_mock_repo_impl.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_mock_repo_impl.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';

void main() {
  group('R-1: Doctor Catalog Unification Tests', () {
    late DoctorsMockRepoImpl doctorsRepo;
    late BookingsMockRepoImpl bookingsRepo;
    late MedicalServicesMockRepoImpl medicalServicesRepo;
    late StaffUsersMockRepoImpl staffUsersRepo;
    final paginationParams = const PaginationParams(page: 1, limit: 100);

    setUp(() {
      doctorsRepo = DoctorsMockRepoImpl();
      bookingsRepo = BookingsMockRepoImpl();
      medicalServicesRepo = MedicalServicesMockRepoImpl();
      staffUsersRepo = StaffUsersMockRepoImpl(auditLogger: InMemoryAuditLogger());
    });

    test('1. DoctorsMockRepoImpl contains exactly the 6 canonical doctors DOC-01 through DOC-06', () async {
      final res = await doctorsRepo.getDoctors(params: paginationParams);
      final doctors = res.getOrElse(() => throw Exception('Failed to get doctors')).doctors;

      expect(doctors.length, equals(6));
      final ids = doctors.map((d) => d.id).toSet();
      expect(ids, equals({'DOC-01', 'DOC-02', 'DOC-03', 'DOC-04', 'DOC-05', 'DOC-06'}));

      final names = doctors.map((d) => d.name).toList();
      expect(names, containsAll([
        'د. حسام الدين مصطفى',
        'د. أحمد الشافعي',
        'د. سارة المنشاوي',
        'د. محمود خليل',
        'د. ريم عبد الوهاب',
        'د. طارق العوضي',
      ]));
    });

    test('2. Every doctorId in BookingsMockRepoImpl exists in DoctorsMockRepoImpl', () async {
      final doctorsRes = await doctorsRepo.getDoctors(params: paginationParams);
      final validDoctorIds = doctorsRes.getOrElse(() => throw Exception('Failed to get doctors')).doctors.map((d) => d.id).toSet();

      for (final booking in bookingsRepo.bookings) {
        if (booking.doctorId != null) {
          expect(
            validDoctorIds.contains(booking.doctorId),
            isTrue,
            reason: 'Booking ${booking.id} has invalid doctorId: ${booking.doctorId}',
          );
        }
        for (final tech in booking.technicians) {
          expect(
            validDoctorIds.contains(tech.id),
            isTrue,
            reason: 'Booking ${booking.id} has technician with invalid doctorId: ${tech.id}',
          );
        }
      }
    });

    test('3. Every assigned doctor in MedicalServicesMockRepoImpl exists in DoctorsMockRepoImpl', () async {
      final doctorsRes = await doctorsRepo.getDoctors(params: paginationParams);
      final validDoctorIds = doctorsRes.getOrElse(() => throw Exception('Failed to get doctors')).doctors.map((d) => d.id).toSet();

      final servicesRes = await medicalServicesRepo.getMedicalServices();
      final services = servicesRes.getOrElse(() => throw Exception('Failed to get services'));

      for (final service in services) {
        if (service.assignedDoctorId != null) {
          expect(
            validDoctorIds.contains(service.assignedDoctorId),
            isTrue,
            reason: 'Service ${service.id} references invalid doctorId: ${service.assignedDoctorId}',
          );
        }
      }
    });

    test('4. Every practicing doctor in StaffUsersMockRepoImpl links to an existing doctor profile', () async {
      final doctorsRes = await doctorsRepo.getDoctors(params: paginationParams);
      final validDoctorIds = doctorsRes.getOrElse(() => throw Exception('Failed to get doctors')).doctors.map((d) => d.id).toSet();

      final staffRes = await staffUsersRepo.getStaffUsers();
      final staffUsers = staffRes.getOrElse(() => throw Exception('Failed to get staff users'));

      final practicingDoctors = staffUsers.where((u) => u.isPracticingDoctor).toList();
      expect(practicingDoctors.length, equals(6));

      for (final docUser in practicingDoctors) {
        expect(
          validDoctorIds.contains(docUser.linkedDoctorId),
          isTrue,
          reason: 'Staff user ${docUser.id} links to invalid doctorId: ${docUser.linkedDoctorId}',
        );
      }
    });

    test('5. BookingsState.initialTechnicians only contains canonical doctors', () {
      final ids = BookingsState.initialTechnicians.map((t) => t.id).toSet();
      expect(ids, equals({'DOC-01', 'DOC-02', 'DOC-03', 'DOC-04', 'DOC-05', 'DOC-06'}));
    });
  });
}
