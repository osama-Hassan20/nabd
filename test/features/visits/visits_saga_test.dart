import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/data/models/vitals_model.dart';
import 'package:eyadty/features/visits/data/repo/visits_mock_repo_impl.dart';
import 'package:eyadty/features/visits/domain/use_cases/finalize_visit_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/record_vitals_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/start_consultation_use_case.dart';

void main() {
  late BookingsMockRepoImpl bookingsRepo;
  late VisitsMockRepoImpl visitsRepo;
  late StartConsultationUseCase startConsultationUseCase;
  late FinalizeVisitUseCase finalizeVisitUseCase;
  late RecordVitalsUseCase recordVitalsUseCase;

  setUp(() {
    bookingsRepo = BookingsMockRepoImpl();
    visitsRepo = VisitsMockRepoImpl(bookingsRepo: bookingsRepo);

    startConsultationUseCase = StartConsultationUseCase(
      visitsRepo: visitsRepo,
      bookingsRepo: bookingsRepo,
    );
    finalizeVisitUseCase = FinalizeVisitUseCase(
      visitsRepo: visitsRepo,
      bookingsRepo: bookingsRepo,
    );
    recordVitalsUseCase = RecordVitalsUseCase(
      visitsRepo: visitsRepo,
      bookingsRepo: bookingsRepo,
    );
  });

  group('StartConsultationUseCase Saga Tests', () {
    test('happy path: changes booking to inConsultation and starts visit', () async {
      // MED-102 is initially waiting in seed
      final bBefore = await bookingsRepo.getBookingById('MED-102');
      expect(bBefore.getOrElse(() => const BookingModel()).status, BookingStatusEnum.waiting);

      final res = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'MED-102',
          patientId: 'PAT-000102',
          branchId: 'branch_1',
          patientName: 'يوسف إبراهيم',
          doctorId: 'DOC-02',
          doctorName: 'د. أحمد الشافعي',
        ),
      );

      expect(res.isRight(), isTrue);
      final visit = res.getOrElse(() => const VisitModel());
      expect(visit.status, VisitStatusEnum.inProgress);
      expect(visit.bookingId, 'MED-102');

      // Check booking status was updated to inConsultation
      final bAfter = await bookingsRepo.getBookingById('MED-102');
      expect(
        bAfter.getOrElse(() => const BookingModel()).status,
        BookingStatusEnum.inConsultation,
      );
    });

    test('fails when booking does not exist', () async {
      final res = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'NON_EXISTENT',
          patientId: 'PAT-000',
          branchId: 'branch_1',
          patientName: 'مجهول',
          doctorId: 'DOC-01',
          doctorName: 'د. حسام',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'booking_not_found'),
        (_) => fail('should fail'),
      );
    });

    test('Saga rollback: when upsertConsultationStart fails, reverts booking to previousStatus', () async {
      // In seed, MED-104 has finalized visit VIS-002, but let's say booking status was waiting
      // We'll test with a booking that has a finalized visit
      final bookingRes = await bookingsRepo.getBookingById('MED-104');
      final originalBooking = bookingRes.getOrElse(() => const BookingModel());
      final originalStatus = originalBooking.status; // completed

      // Attempt start consultation on MED-104 (its visit VIS-002 is finalized in VisitsRepo)
      final res = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'MED-104',
          patientId: 'PAT-000104',
          branchId: 'branch_1',
          patientName: 'طارق عبد العزيز',
          doctorId: 'DOC-01',
          doctorName: 'د. حسام الدين مصطفى',
        ),
      );

      // Must fail because finalized visit cannot be reopened
      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'finalized_cannot_be_reopened'),
        (_) => fail('should fail'),
      );

      // Verify Saga compensation: booking status was rolled back to original status
      final bookingAfter = await bookingsRepo.getBookingById('MED-104');
      expect(
        bookingAfter.getOrElse(() => const BookingModel()).status,
        originalStatus,
      );
    });
  });

  group('FinalizeVisitUseCase Saga Tests', () {
    test('happy path: changes booking to completed and finalizes visit', () async {
      // MED-101 has active visit VIS-001 in progress
      final res = await finalizeVisitUseCase(
        const VisitModel(
          id: 'VIS-001',
          bookingId: 'MED-101',
          diagnosis: 'تشخيص نهائي سليم',
          treatmentPlan: 'علاج مستمر',
        ),
      );

      expect(res.isRight(), isTrue);
      final visit = res.getOrElse(() => const VisitModel());
      expect(visit.status, VisitStatusEnum.finalized);

      // Booking status must be completed
      final booking = await bookingsRepo.getBookingById('MED-101');
      expect(
        booking.getOrElse(() => const BookingModel()).status,
        BookingStatusEnum.completed,
      );
    });

    test('fails if visit has no bookingId', () async {
      final res = await finalizeVisitUseCase(
        const VisitModel(id: 'VIS-001', diagnosis: 'بدون حجز'),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'booking_id_required_to_finalize'),
        (_) => fail('should fail'),
      );
    });

    test('Saga rollback: when finalizeVisit fails, reverts booking to inConsultation', () async {
      // VIS-002 is already finalized in visitsRepo
      final res = await finalizeVisitUseCase(
        const VisitModel(
          id: 'VIS-002',
          bookingId: 'MED-104',
          diagnosis: 'إعادة إغلاق',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'visit_already_finalized'),
        (_) => fail('should fail'),
      );

      // Compensation: booking status reverted to inConsultation
      final booking = await bookingsRepo.getBookingById('MED-104');
      expect(
        booking.getOrElse(() => const BookingModel()).status,
        BookingStatusEnum.inConsultation,
      );
    });
  });

  group('RecordVitalsUseCase Tests', () {
    test('happy path: records vitals for waiting booking today', () async {
      // MED-102 is waiting today in seed
      final res = await recordVitalsUseCase(
        const RecordVitalsParams(
          bookingId: 'MED-102',
          patientId: 'PAT-000102',
          branchId: 'branch_1',
          patientName: 'يوسف إبراهيم',
          doctorId: 'DOC-02',
          doctorName: 'د. أحمد الشافعي',
          vitals: VitalsModel(systolicBp: 118, diastolicBp: 78),
        ),
      );

      expect(res.isRight(), isTrue);
      final visit = res.getOrElse(() => const VisitModel());
      expect(visit.status, VisitStatusEnum.triage);
      expect(visit.vitals?.systolicBp, 118);
    });

    test('fails if booking does not exist', () async {
      final res = await recordVitalsUseCase(
        const RecordVitalsParams(
          bookingId: 'NON_EXISTENT',
          patientId: 'PAT-000',
          branchId: 'branch_1',
          patientName: 'مجهول',
          doctorId: 'DOC-01',
          doctorName: 'د. حسام',
          vitals: VitalsModel(systolicBp: 120),
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'booking_not_found'),
        (_) => fail('should fail'),
      );
    });

    test('fails if booking status is not waiting (e.g. inConsultation)', () async {
      // MED-101 is inConsultation in seed
      final res = await recordVitalsUseCase(
        const RecordVitalsParams(
          bookingId: 'MED-101',
          patientId: 'PAT-000101',
          branchId: 'branch_1',
          patientName: 'سارة',
          doctorId: 'DOC-01',
          doctorName: 'د. حسام',
          vitals: VitalsModel(systolicBp: 120),
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'vitals_only_allowed_for_waiting_bookings'),
        (_) => fail('should fail'),
      );
    });

    test('fails if branch does not match booking branch', () async {
      final res = await recordVitalsUseCase(
        const RecordVitalsParams(
          bookingId: 'MED-102',
          patientId: 'PAT-000102',
          branchId: 'branch_wrong',
          patientName: 'يوسف',
          doctorId: 'DOC-02',
          doctorName: 'د. أحمد',
          vitals: VitalsModel(systolicBp: 120),
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'branch_mismatch'),
        (_) => fail('should fail'),
      );
    });
  });
}
