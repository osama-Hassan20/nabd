import 'package:dartz/dartz.dart';

import '../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/params.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../bookings/data/models/enums/booking_status_enum.dart';
import '../../../bookings/data/repo/bookings_mock_repo_impl.dart';
import '../../../bookings/domain/contracts/active_visit_lookup.dart';
import '../../../bookings/domain/repo/bookings_repo.dart';
import '../../domain/repo/visits_repo.dart';
import '../models/consultation_queue_item_model.dart';
import '../models/enums/visit_status_enum.dart';
import '../models/visit_model.dart';
import '../models/vitals_model.dart';

class VisitsMockRepoImpl implements VisitsRepo, ActiveVisitLookup {
  final BookingsRepo? bookingsRepo;

  VisitsMockRepoImpl({this.bookingsRepo}) {
    initMockData();
  }

  BookingsRepo? get _effectiveBookingsRepo {
    if (bookingsRepo != null) return bookingsRepo;
    if (getIt.isRegistered<BookingsRepo>()) {
      return getIt<BookingsRepo>();
    }
    return null;
  }

  final List<VisitModel> _visits = [];

  List<VisitModel> get visits => List.unmodifiable(_visits);

  void initMockData() {
    _visits.clear();
    final now = CairoTimeHelper.now();
    final today = DateTime(now.year, now.month, now.day);

    _visits.addAll([
      // Seed 1: Active consultation for MED-101
      VisitModel(
        id: 'VIS-001',
        bookingId: 'MED-101',
        patientId: 'PAT-000101',
        branchId: 'branch_1',
        patientName: 'سارة أحمد عبد الله',
        patientPhone: '+201012345678',
        doctorId: 'DOC-01',
        doctorName: 'د. حسام الدين مصطفى',
        specialty: 'استشاري أمراض باطنة وسكري',
        status: VisitStatusEnum.inProgress,
        startedAt: today.add(const Duration(hours: 10, minutes: 0)),
        lastSavedAt: today.add(const Duration(hours: 10, minutes: 5)),
        vitals: VitalsModel(
          systolicBp: 145,
          diastolicBp: 92,
          heartRate: 88,
          temperature: 37.1,
          oxygenSaturation: 98,
          weightKg: 72.0,
          heightCm: 165.0,
          recordedAt: today.add(const Duration(hours: 9, minutes: 45)),
          recordedByUserId: 'USR-02',
        ),
        chiefComplaint: 'صداع نصفي متكرر وارتفاع في ضغط الدم منذ يومين',
        medicalHistory:
            'تاريخ عائلي لارتفاع ضغط الدم، لا توجد حساسيات دوائية معروفة',
      ),
      // Seed 2: Finalized visit for MED-104
      VisitModel(
        id: 'VIS-002',
        bookingId: 'MED-104',
        patientId: 'PAT-000104',
        branchId: 'branch_1',
        patientName: 'طارق عبد العزيز',
        patientPhone: '+201011223344',
        doctorId: 'DOC-01',
        doctorName: 'د. حسام الدين مصطفى',
        specialty: 'استشاري أمراض باطنة وسكري',
        status: VisitStatusEnum.finalized,
        startedAt: today.add(const Duration(hours: 9, minutes: 0)),
        finalizedAt: today.add(const Duration(hours: 9, minutes: 25)),
        lastSavedAt: today.add(const Duration(hours: 9, minutes: 25)),
        diagnosis: 'نزلة معوية حادة مع جفاف خفيف',
        treatmentPlan: 'محلول معالجة الجفاف + مضاد للتقلصات مع راحة تامة',
        followUpDays: 3,
      ),
      // Seed 3: Finalized visit for MED-107
      VisitModel(
        id: 'VIS-003',
        bookingId: 'MED-107',
        patientId: 'PAT-000102',
        branchId: 'branch_1',
        patientName: 'يوسف إبراهيم المنصوري',
        patientPhone: '+201123456789',
        doctorId: 'DOC-02',
        doctorName: 'د. أحمد الشافعي',
        specialty: 'أخصائي طب وجراحة العيون',
        status: VisitStatusEnum.finalized,
        startedAt: today.subtract(const Duration(days: 2)),
        finalizedAt: today.subtract(const Duration(days: 2)),
        lastSavedAt: today.subtract(const Duration(days: 2)),
        diagnosis: 'التهاب حاد في اللوزتين',
        treatmentPlan: 'مضاد حيوي مناسب للوزن + خافض حرارة عند اللزوم',
        followUpDays: 5,
      ),
    ]);
  }

  @override
  Future<VisitStatusEnum?> getVisitStatusByBookingId(String bookingId) async {
    return _visits.where((v) => v.bookingId == bookingId).firstOrNull?.status;
  }

  @override
  Future<Either<Failures, VisitModel?>> getVisitByBookingId({
    required String bookingId,
  }) async {
    final visit =
        _visits.where((v) => v.bookingId == bookingId).firstOrNull;
    return Right(visit);
  }

  @override
  Future<Either<Failures, List<ConsultationQueueItemModel>>> getDoctorQueue({
    String? doctorId,
    required String branchId,
    required DateTime date,
  }) async {
    List<BookingModel> candidateBookings = [];
    final repo = _effectiveBookingsRepo;

    if (repo is BookingsMockRepoImpl) {
      candidateBookings = repo.bookings;
    } else if (repo != null) {
      final res = await repo.getBookings(
        const PaginationParams(page: 1, limit: 100),
      );
      res.fold(
        (l) => null,
        (r) => candidateBookings = r.bookings ?? [],
      );
    }

    final filtered = candidateBookings.where((b) {
      final bDate = b.date ?? b.appointmentTime;
      final dateMatch = bDate == null || CairoTimeHelper.isSameDay(bDate, date);
      final branchMatch = b.branchId == null || b.branchId == branchId;
      final doctorMatch = doctorId == null ||
          doctorId.isEmpty ||
          b.doctorId == doctorId ||
          b.technicians.any((t) => t.id == doctorId);
      final statusMatch = b.status != BookingStatusEnum.cancelled;
      return dateMatch && branchMatch && doctorMatch && statusMatch;
    }).toList();

    filtered.sort((a, b) {
      final aInConsult = a.status == BookingStatusEnum.inConsultation;
      final bInConsult = b.status == BookingStatusEnum.inConsultation;
      if (aInConsult && !bInConsult) return -1;
      if (!aInConsult && bInConsult) return 1;

      final aWaiting = a.status == BookingStatusEnum.waiting;
      final bWaiting = b.status == BookingStatusEnum.waiting;
      if (aWaiting && !bWaiting) return -1;
      if (!aWaiting && bWaiting) return 1;

      return (a.queueNumber ?? 999).compareTo(b.queueNumber ?? 999);
    });

    final items = filtered.map((b) {
      final visit = _visits.where((v) => v.bookingId == b.id).firstOrNull;
      return ConsultationQueueItemModel(booking: b, visit: visit);
    }).toList();

    return Right(items);
  }

  @override
  Future<Either<Failures, VisitModel>> upsertConsultationStart({
    required String bookingId,
    required String patientId,
    required String branchId,
    required String patientName,
    String? patientPhone,
    required String doctorId,
    required String doctorName,
    String? specialty,
  }) async {
    final index = _visits.indexWhere((v) => v.bookingId == bookingId);
    final now = CairoTimeHelper.now();

    if (index != -1) {
      final existing = _visits[index];
      if (existing.status == VisitStatusEnum.finalized) {
        return const Left(
          ValidationFailure(errMessage: 'finalized_cannot_be_reopened'),
        );
      }
      if (existing.status == VisitStatusEnum.inProgress) {
        return Right(existing);
      }
      if (existing.status == VisitStatusEnum.triage) {
        final updated = existing.copyWith(
          status: VisitStatusEnum.inProgress,
          doctorId: doctorId,
          doctorName: doctorName,
          specialty: specialty ?? existing.specialty,
          startedAt: existing.startedAt ?? now,
          lastSavedAt: now,
        );
        _visits[index] = updated;
        return Right(updated);
      }
    }

    final newId = 'VIS-${(_visits.length + 101).toString().padLeft(3, '0')}';
    final newVisit = VisitModel(
      id: newId,
      bookingId: bookingId,
      patientId: patientId,
      branchId: branchId,
      patientName: patientName,
      patientPhone: patientPhone,
      doctorId: doctorId,
      doctorName: doctorName,
      specialty: specialty,
      status: VisitStatusEnum.inProgress,
      startedAt: now,
      lastSavedAt: now,
    );
    _visits.add(newVisit);
    return Right(newVisit);
  }

  @override
  Future<Either<Failures, VisitModel>> recordVitals({
    required String bookingId,
    required String patientId,
    required String branchId,
    required String patientName,
    String? patientPhone,
    required String doctorId,
    required String doctorName,
    String? specialty,
    required VitalsModel vitals,
  }) async {
    final index = _visits.indexWhere((v) => v.bookingId == bookingId);
    final now = CairoTimeHelper.now();

    if (index != -1) {
      final existing = _visits[index];
      if (existing.status == VisitStatusEnum.inProgress ||
          existing.status == VisitStatusEnum.finalized) {
        return const Left(
          ValidationFailure(
            errMessage: 'cannot_record_vitals_on_active_or_finalized_visit',
          ),
        );
      }
      final updated = existing.copyWith(
        vitals: vitals,
        lastSavedAt: now,
      );
      _visits[index] = updated;
      return Right(updated);
    }

    final newId = 'VIS-${(_visits.length + 101).toString().padLeft(3, '0')}';
    final newVisit = VisitModel(
      id: newId,
      bookingId: bookingId,
      patientId: patientId,
      branchId: branchId,
      patientName: patientName,
      patientPhone: patientPhone,
      doctorId: doctorId,
      doctorName: doctorName,
      specialty: specialty,
      status: VisitStatusEnum.triage,
      vitals: vitals,
      triageAt: now,
      lastSavedAt: now,
    );
    _visits.add(newVisit);
    return Right(newVisit);
  }

  @override
  Future<Either<Failures, VisitModel>> saveVisitDraft({
    required VisitModel draft,
  }) async {
    final index = _visits.indexWhere(
      (v) =>
          (draft.id != null && v.id == draft.id) ||
          (draft.bookingId != null && v.bookingId == draft.bookingId),
    );

    if (index == -1) {
      return const Left(ValidationFailure(errMessage: 'visit_not_found'));
    }

    final existing = _visits[index];
    if (existing.status == VisitStatusEnum.finalized) {
      return const Left(
        ValidationFailure(errMessage: 'cannot_edit_finalized_visit'),
      );
    }

    final updated = draft.copyWith(
      id: existing.id,
      bookingId: existing.bookingId,
      patientId: existing.patientId,
      branchId: existing.branchId,
      status: VisitStatusEnum.inProgress,
      lastSavedAt: CairoTimeHelper.now(),
    );
    _visits[index] = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failures, VisitModel>> finalizeVisit({
    required VisitModel finalContent,
  }) async {
    final index = _visits.indexWhere(
      (v) =>
          (finalContent.id != null && v.id == finalContent.id) ||
          (finalContent.bookingId != null &&
              v.bookingId == finalContent.bookingId),
    );

    if (index == -1) {
      return const Left(ValidationFailure(errMessage: 'visit_not_found'));
    }

    final existing = _visits[index];
    if (existing.status == VisitStatusEnum.finalized) {
      return const Left(
        ValidationFailure(errMessage: 'visit_already_finalized'),
      );
    }

    final now = CairoTimeHelper.now();
    final updated = finalContent.copyWith(
      id: existing.id,
      bookingId: existing.bookingId,
      patientId: existing.patientId,
      branchId: existing.branchId,
      status: VisitStatusEnum.finalized,
      finalizedAt: now,
      lastSavedAt: now,
    );
    _visits[index] = updated;
    return Right(updated);
  }
}
