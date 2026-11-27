import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_repo_impl.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/data/models/vitals_model.dart';
import 'package:eyadty/features/visits/data/repo/visits_repo_impl.dart';

void main() {
  late BookingsRepoImpl bookingsRepo;
  late VisitsRepoImpl visitsRepo;

  setUp(() {
    bookingsRepo = BookingsRepoImpl(apiConsumer: LocalServerApiConsumer());
    visitsRepo = VisitsRepoImpl(apiConsumer: LocalServerApiConsumer(), bookingsRepo: bookingsRepo);
  });

  group('VisitsRepoImpl Seed & ActiveVisitLookup Tests', () {
    test('seed data contains initial visits VIS-001, VIS-002, VIS-003', () async {


      final vis001 = (await visitsRepo.getVisitById(visitId: 'VIS-001')).getOrElse(() => null)!;
      expect(vis001.bookingId, 'MED-101');
      expect(vis001.status, VisitStatusEnum.inProgress);
      expect(vis001.doctorId, 'DOC-01');

      final vis002 = (await visitsRepo.getVisitById(visitId: 'VIS-002')).getOrElse(() => null)!;
      expect(vis002.bookingId, 'MED-104');
      expect(vis002.status, VisitStatusEnum.finalized);

      final vis003 = (await visitsRepo.getVisitById(visitId: 'VIS-003')).getOrElse(() => null)!;
      expect(vis003.bookingId, 'MED-107');
      expect(vis003.status, VisitStatusEnum.finalized);
    });

    test('getVisitStatusByBookingId returns correct status via lookup', () async {
      expect(
        await visitsRepo.getVisitStatusByBookingId('MED-101'),
        VisitStatusEnum.inProgress,
      );
      expect(
        await visitsRepo.getVisitStatusByBookingId('MED-104'),
        VisitStatusEnum.finalized,
      );
      expect(
        await visitsRepo.getVisitStatusByBookingId('NON_EXISTENT'),
        isNull,
      );
    });

    test('getVisitByBookingId returns visit or null wrapped in Right', () async {
      final res1 = await visitsRepo.getVisitByBookingId(bookingId: 'MED-101');
      expect(res1.isRight(), isTrue);
      expect(res1.getOrElse(() => null)?.id, 'VIS-001');

      final res2 = await visitsRepo.getVisitByBookingId(bookingId: 'NON_EXISTENT');
      expect(res2.isRight(), isTrue);
      expect(res2.getOrElse(() => null), isNull);
    });
  });

  group('getDoctorQueue Tests', () {
    test('returns sorted queue with inConsultation first, then waiting by queueNumber', () async {
      final now = CairoTimeHelper.now();
      final res = await visitsRepo.getDoctorQueue(
        branchId: 'branch_1',
        date: now,
      );

      expect(res.isRight(), isTrue);
      final queue = res.getOrElse(() => []);
      expect(queue, isNotEmpty);

      // In the seed, MED-101 is inConsultation
      expect(queue.first.bookingId, 'MED-101');
      expect(queue.first.hasActiveVisit, isTrue);

      // Subsequent items should be waiting or completed, with queue number ordered
      final waitingItems = queue.where((i) => i.booking?.status?.name == 'waiting').toList();
      for (int i = 0; i < waitingItems.length - 1; i++) {
        expect(
          (waitingItems[i].queueNumber ?? 0) <= (waitingItems[i + 1].queueNumber ?? 0),
          isTrue,
        );
      }
    });

    test('filters queue by doctorId when provided', () async {
      final now = CairoTimeHelper.now();
      final res = await visitsRepo.getDoctorQueue(
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        date: now,
      );

      expect(res.isRight(), isTrue);
      final queue = res.getOrElse(() => []);
      for (final item in queue) {
        final matchesDoc = item.booking?.doctorId == 'DOC-01' ||
            (item.booking?.technicians.any((t) => t.id == 'DOC-01') ?? false);
        expect(matchesDoc, isTrue);
      }
    });

    test('filters queue by branchId', () async {
      final now = CairoTimeHelper.now();
      final res = await visitsRepo.getDoctorQueue(
        branchId: 'branch_non_existent',
        date: now,
      );

      expect(res.isRight(), isTrue);
      expect(res.getOrElse(() => []), isEmpty);
    });
  });

  group('recordVitals Tests', () {
    test('creates new triage visit when no visit exists for booking', () async {
      const vitals = VitalsModel(systolicBp: 120, diastolicBp: 80);
      final res = await visitsRepo.recordVitals(
        bookingId: 'MED-NEW-01',
        patientId: 'PAT-999',
        branchId: 'branch_1',
        patientName: 'مريض جديد',
        doctorId: 'DOC-01',
        doctorName: 'د. حسام',
        vitals: vitals,
      );

      expect(res.isRight(), isTrue);
      final visit = res.getOrElse(() => const VisitModel());
      expect(visit.status, VisitStatusEnum.triage);
      expect(visit.vitals?.systolicBp, 120);
      expect(visit.triageAt, isNotNull);
    });

    test('updates existing triage visit vitals', () async {
      const vitals1 = VitalsModel(systolicBp: 110);
      await visitsRepo.recordVitals(
        bookingId: 'MED-NEW-02',
        patientId: 'PAT-999',
        branchId: 'branch_1',
        patientName: 'مريض تجربة',
        doctorId: 'DOC-01',
        doctorName: 'د. حسام',
        vitals: vitals1,
      );

      const vitals2 = VitalsModel(systolicBp: 130, diastolicBp: 85);
      final res = await visitsRepo.recordVitals(
        bookingId: 'MED-NEW-02',
        patientId: 'PAT-999',
        branchId: 'branch_1',
        patientName: 'مريض تجربة',
        doctorId: 'DOC-01',
        doctorName: 'د. حسام',
        vitals: vitals2,
      );

      expect(res.isRight(), isTrue);
      final visit = res.getOrElse(() => const VisitModel());
      expect(visit.vitals?.systolicBp, 130);
      expect(visit.vitals?.diastolicBp, 85);
      expect(visit.status, VisitStatusEnum.triage);
    });

    test('rejects recording vitals on inProgress visit', () async {
      const vitals = VitalsModel(systolicBp: 120);
      final res = await visitsRepo.recordVitals(
        bookingId: 'MED-101', // Has inProgress visit VIS-001
        patientId: 'PAT-000101',
        branchId: 'branch_1',
        patientName: 'سارة',
        doctorId: 'DOC-01',
        doctorName: 'د. حسام',
        vitals: vitals,
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'cannot_record_vitals_on_active_or_finalized_visit'),
        (_) => fail('should fail'),
      );
    });

    test('rejects recording vitals on finalized visit', () async {
      const vitals = VitalsModel(systolicBp: 120);
      final res = await visitsRepo.recordVitals(
        bookingId: 'MED-104', // Has finalized visit VIS-002
        patientId: 'PAT-000104',
        branchId: 'branch_1',
        patientName: 'طارق',
        doctorId: 'DOC-01',
        doctorName: 'د. حسام',
        vitals: vitals,
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'cannot_record_vitals_on_active_or_finalized_visit'),
        (_) => fail('should fail'),
      );
    });
  });

  group('upsertConsultationStart Tests', () {
    test('converts triage visit to inProgress and updates doctor snapshot', () async {
      // 1. Create triage visit first
      const vitals = VitalsModel(systolicBp: 120);
      await visitsRepo.recordVitals(
        bookingId: 'MED-TRIAGE-01',
        patientId: 'PAT-111',
        branchId: 'branch_1',
        patientName: 'مريض الفرز',
        doctorId: 'DOC-OLD',
        doctorName: 'طبيب قديم',
        specialty: 'تخصص قديم',
        vitals: vitals,
      );

      // 2. Start consultation with new doctor
      final startRes = await visitsRepo.upsertConsultationStart(
        bookingId: 'MED-TRIAGE-01',
        patientId: 'PAT-111',
        branchId: 'branch_1',
        patientName: 'مريض الفرز',
        doctorId: 'DOC-NEW',
        doctorName: 'د. عصام الجديد',
        specialty: 'استشاري قلب',
      );

      expect(startRes.isRight(), isTrue);
      final started = startRes.getOrElse(() => const VisitModel());
      expect(started.status, VisitStatusEnum.inProgress);
      expect(started.doctorId, 'DOC-NEW');
      expect(started.doctorName, 'د. عصام الجديد');
      expect(started.specialty, 'استشاري قلب');
      expect(started.vitals?.systolicBp, 120); // Vitals preserved
      expect(started.startedAt, isNotNull);
    });

    test('is idempotent when visit is already inProgress', () async {
      final res = await visitsRepo.upsertConsultationStart(
        bookingId: 'MED-101', // Already inProgress
        patientId: 'PAT-000101',
        branchId: 'branch_1',
        patientName: 'سارة',
        doctorId: 'DOC-01',
        doctorName: 'د. حسام',
      );

      expect(res.isRight(), isTrue);
      final visit = res.getOrElse(() => const VisitModel());
      expect(visit.id, 'VIS-001');
      expect(visit.status, VisitStatusEnum.inProgress);
    });

    test('creates new inProgress visit when no prior visit existed', () async {
      final res = await visitsRepo.upsertConsultationStart(
        bookingId: 'MED-FRESH-01',
        patientId: 'PAT-333',
        branchId: 'branch_1',
        patientName: 'مريض جديد',
        doctorId: 'DOC-01',
        doctorName: 'د. حسام',
      );

      expect(res.isRight(), isTrue);
      final visit = res.getOrElse(() => const VisitModel());
      expect(visit.status, VisitStatusEnum.inProgress);
      expect(visit.bookingId, 'MED-FRESH-01');
    });

    test('rejects starting consultation if visit is already finalized', () async {
      final res = await visitsRepo.upsertConsultationStart(
        bookingId: 'MED-104', // Finalized VIS-002
        patientId: 'PAT-000104',
        branchId: 'branch_1',
        patientName: 'طارق',
        doctorId: 'DOC-01',
        doctorName: 'د. حسام',
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'finalized_cannot_be_reopened'),
        (_) => fail('should fail'),
      );
    });
  });

  group('saveVisitDraft & finalizeVisit Tests', () {
    test('saveVisitDraft updates draft fields and lastSavedAt', () async {
      final draft = const VisitModel(
        id: 'VIS-001',
        bookingId: 'MED-101',
        diagnosis: 'صداع نصفي متقدم',
        treatmentPlan: 'علاج دوائي وراحة',
      );

      final res = await visitsRepo.saveVisitDraft(draft: draft);
      expect(res.isRight(), isTrue);
      final saved = res.getOrElse(() => const VisitModel());
      expect(saved.diagnosis, 'صداع نصفي متقدم');
      expect(saved.treatmentPlan, 'علاج دوائي وراحة');
      expect(saved.lastSavedAt, isNotNull);
    });

    test('saveVisitDraft rejects if visit is finalized', () async {
      final draft = const VisitModel(
        id: 'VIS-002',
        bookingId: 'MED-104',
        diagnosis: 'تعديل غير مسموح',
      );

      final res = await visitsRepo.saveVisitDraft(draft: draft);
      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'cannot_edit_finalized_visit'),
        (_) => fail('should fail'),
      );
    });

    test('saveVisitDraft rejects if visit not found', () async {
      final draft = const VisitModel(
        id: 'NON_EXISTENT',
        bookingId: 'NON_EXISTENT',
      );

      final res = await visitsRepo.saveVisitDraft(draft: draft);
      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'visit_not_found'),
        (_) => fail('should fail'),
      );
    });

    test('finalizeVisit marks status as finalized with timestamps', () async {
      final content = const VisitModel(
        id: 'VIS-001',
        bookingId: 'MED-101',
        diagnosis: 'تشخيص نهائي للكشف',
        treatmentPlan: 'خطة علاجية نهائية',
      );

      final res = await visitsRepo.finalizeVisit(finalContent: content);
      expect(res.isRight(), isTrue);
      final fin = res.getOrElse(() => const VisitModel());
      expect(fin.status, VisitStatusEnum.finalized);
      expect(fin.finalizedAt, isNotNull);
      expect(fin.lastSavedAt, isNotNull);
    });

    test('finalizeVisit rejects if already finalized', () async {
      final content = const VisitModel(
        id: 'VIS-002',
        bookingId: 'MED-104',
      );

      final res = await visitsRepo.finalizeVisit(finalContent: content);
      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'visit_already_finalized'),
        (_) => fail('should fail'),
      );
    });
  });
}
