import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/consultation_queue_item_model.dart';
import '../../data/models/visit_addendum_model.dart';
import '../../data/models/visit_model.dart';
import '../../data/models/vitals_model.dart';

abstract class VisitsRepo {
  Future<Either<Failures, List<ConsultationQueueItemModel>>> getDoctorQueue({
    String? doctorId,
    required String branchId,
    required DateTime date,
  });

  Future<Either<Failures, VisitModel?>> getVisitByBookingId({
    required String bookingId,
  });

  Future<Either<Failures, VisitModel?>> getVisitById({
    required String visitId,
  });

  Future<Either<Failures, VisitModel>> upsertConsultationStart({
    required String bookingId,
    required String patientId,
    required String branchId,
    required String patientName,
    String? patientPhone,
    required String doctorId,
    required String doctorName,
    String? specialty,
  });

  Future<Either<Failures, VisitModel>> saveVisitDraft({
    required VisitModel draft,
  });

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
  });

  Future<Either<Failures, VisitModel>> finalizeVisit({
    required VisitModel finalContent,
  });

  Future<Either<Failures, VisitModel>> addVisitAddendum({
    required String visitId,
    required VisitAddendumModel addendum,
  });
}
