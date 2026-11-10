import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/change_booking_status_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/reassign_technician_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/visits/data/models/vitals_model.dart';
import 'package:eyadty/features/visits/data/repo/visits_mock_repo_impl.dart';

void main() {
  late BookingsMockRepoImpl bookingsRepo;
  late VisitsMockRepoImpl visitsRepo;
  late ChangeBookingStatusUseCase changeBookingStatusUseCase;
  late ReassignTechnicianUseCase reassignTechnicianUseCase;
  late DeleteBookingUseCase deleteBookingUseCase;

  setUp(() {
    bookingsRepo = BookingsMockRepoImpl();
    visitsRepo = VisitsMockRepoImpl(bookingsRepo: bookingsRepo);

    changeBookingStatusUseCase = ChangeBookingStatusUseCase(
      repo: bookingsRepo,
      activeVisitLookup: visitsRepo,
    );
    reassignTechnicianUseCase = ReassignTechnicianUseCase(
      repo: bookingsRepo,
      activeVisitLookup: visitsRepo,
    );
    deleteBookingUseCase = DeleteBookingUseCase(
      repo: bookingsRepo,
      activeVisitLookup: visitsRepo,
    );
  });

  group('ChangeBookingStatusUseCase Lock Tests', () {
    test('blocks changing status to cancelled when visit is inProgress', () async {
      // In seed, MED-101 has visit VIS-001 in progress
      final res = await changeBookingStatusUseCase(
        const ChangeBookingStatusParams(
          bookingId: 'MED-101',
          newStatus: BookingStatusEnum.cancelled,
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'booking_locked_consultation_in_progress'),
        (_) => fail('should fail'),
      );
    });

    test('blocks changing status to noShow when visit is inProgress', () async {
      final res = await changeBookingStatusUseCase(
        const ChangeBookingStatusParams(
          bookingId: 'MED-101',
          newStatus: BookingStatusEnum.noShow,
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'booking_locked_consultation_in_progress'),
        (_) => fail('should fail'),
      );
    });

    test('blocks changing status to postponed when visit is inProgress', () async {
      final res = await changeBookingStatusUseCase(
        const ChangeBookingStatusParams(
          bookingId: 'MED-101',
          newStatus: BookingStatusEnum.postponed,
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'booking_locked_consultation_in_progress'),
        (_) => fail('should fail'),
      );
    });

    test('blocks changing status to waiting when visit is inProgress', () async {
      final res = await changeBookingStatusUseCase(
        const ChangeBookingStatusParams(
          bookingId: 'MED-101',
          newStatus: BookingStatusEnum.waiting,
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'booking_locked_consultation_in_progress'),
        (_) => fail('should fail'),
      );
    });

    test('allows changing status to completed when visit is inProgress', () async {
      final res = await changeBookingStatusUseCase(
        const ChangeBookingStatusParams(
          bookingId: 'MED-101',
          newStatus: BookingStatusEnum.completed,
        ),
      );

      expect(res.isRight(), isTrue);
    });

    test('allows changing status (cancelled, noShow, postponed) when visit is in triage', () async {
      // 1. Create triage visit for MED-102
      await visitsRepo.recordVitals(
        bookingId: 'MED-102',
        patientId: 'PAT-000102',
        branchId: 'branch_1',
        patientName: 'يوسف',
        doctorId: 'DOC-02',
        doctorName: 'د. أحمد',
        vitals: const VitalsModel(systolicBp: 120),
      );

      // 2. Cancellation is allowed for triage
      final res = await changeBookingStatusUseCase(
        const ChangeBookingStatusParams(
          bookingId: 'MED-102',
          newStatus: BookingStatusEnum.cancelled,
        ),
      );

      expect(res.isRight(), isTrue);
    });

    test('allows status change when visit is finalized or null', () async {
      // MED-104 has finalized visit VIS-002
      final res = await changeBookingStatusUseCase(
        const ChangeBookingStatusParams(
          bookingId: 'MED-104',
          newStatus: BookingStatusEnum.completed,
        ),
      );

      expect(res.isRight(), isTrue);
    });
  });

  group('ReassignTechnicianUseCase Lock Tests', () {
    test('blocks reassigning doctor when visit is inProgress', () async {
      final res = await reassignTechnicianUseCase(
        ReassignTechnicianParams(
          bookingId: 'MED-101',
          newTechnicianId: 'DOC-02',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'booking_locked_cannot_reassign_in_progress'),
        (_) => fail('should fail'),
      );
    });

    test('allows reassigning doctor when visit is triage', () async {
      await visitsRepo.recordVitals(
        bookingId: 'MED-102',
        patientId: 'PAT-000102',
        branchId: 'branch_1',
        patientName: 'يوسف',
        doctorId: 'DOC-02',
        doctorName: 'د. أحمد',
        vitals: const VitalsModel(systolicBp: 120),
      );

      final res = await reassignTechnicianUseCase(
        ReassignTechnicianParams(
          bookingId: 'MED-102',
          newTechnicianId: 'DOC-01',
        ),
      );

      expect(res.isRight(), isTrue);
    });

    test('allows reassigning doctor when visit is null or finalized', () async {
      // MED-103 has no visit
      final res = await reassignTechnicianUseCase(
        ReassignTechnicianParams(
          bookingId: 'MED-103',
          newTechnicianId: 'DOC-01',
        ),
      );

      expect(res.isRight(), isTrue);
    });
  });

  group('DeleteBookingUseCase Lock Tests', () {
    test('blocks deleting booking when visit is inProgress', () async {
      final res = await deleteBookingUseCase('MED-101');

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'booking_locked_cannot_delete_active_visit'),
        (_) => fail('should fail'),
      );
    });

    test('blocks deleting booking when visit is triage', () async {
      await visitsRepo.recordVitals(
        bookingId: 'MED-102',
        patientId: 'PAT-000102',
        branchId: 'branch_1',
        patientName: 'يوسف',
        doctorId: 'DOC-02',
        doctorName: 'د. أحمد',
        vitals: const VitalsModel(systolicBp: 120),
      );

      final res = await deleteBookingUseCase('MED-102');

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'booking_locked_cannot_delete_active_visit'),
        (_) => fail('should fail'),
      );
    });

    test('allows deleting booking when visit is finalized or null', () async {
      // MED-103 has no visit
      final res = await deleteBookingUseCase('MED-103');
      expect(res.isRight(), isTrue);
    });
  });
}
