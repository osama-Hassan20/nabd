import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../../bookings/data/models/enums/booking_status_enum.dart';
import '../../../bookings/domain/repo/bookings_repo.dart';
import '../../../bookings/domain/use_cases/params/change_booking_status_params.dart';
import '../../data/models/visit_model.dart';
import '../repo/visits_repo.dart';

class FinalizeVisitUseCase implements UseCase<VisitModel, VisitModel> {
  final VisitsRepo visitsRepo;
  final BookingsRepo bookingsRepo;
  final PermissionEvaluator? permissionEvaluator;
  final AuditLogger? auditLogger;

  FinalizeVisitUseCase({
    required this.visitsRepo,
    required this.bookingsRepo,
    this.permissionEvaluator,
    this.auditLogger,
  });

  @override
  Future<Either<Failures, VisitModel>> call(VisitModel finalContent) async {
    // 1. Permission Evaluation: Requires editMedicalDiagnosis + assigned doctor
    if (permissionEvaluator != null) {
      final canFinalize = permissionEvaluator!.can(
        StaffPermissionEnum.editMedicalDiagnosis,
        branchId: finalContent.branchId,
        patientDoctorIds:
            finalContent.doctorId != null ? {finalContent.doctorId!} : null,
      );
      if (!canFinalize) {
        return const Left(
          ValidationFailure(errMessage: 'permission_denied_finalize_visit'),
        );
      }
    }

    final bookingId = finalContent.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      return const Left(
        ValidationFailure(errMessage: 'booking_id_required_to_finalize'),
      );
    }

    // Validation: Chief complaint and diagnosis are mandatory to finalize
    final chiefComplaint = finalContent.chiefComplaint?.trim();
    final diagnosis = finalContent.diagnosis?.trim();
    if (chiefComplaint == null ||
        chiefComplaint.isEmpty ||
        diagnosis == null ||
        diagnosis.isEmpty) {
      return const Left(
        ValidationFailure(errMessage: 'visits_finalize_missing_fields'),
      );
    }

    // 2. Step 1: Change booking status to completed directly via BookingsRepo
    final changeRes = await bookingsRepo.changeBookingStatus(
      ChangeBookingStatusParams(
        bookingId: bookingId,
        newStatus: BookingStatusEnum.completed,
      ),
    );

    if (changeRes.isLeft()) {
      return changeRes.fold(
        (failure) => Left(failure),
        (_) => throw StateError('unreachable'),
      );
    }

    // 3. Step 2: Finalize visit in VisitsRepo
    final visitRes = await visitsRepo.finalizeVisit(
      finalContent: finalContent,
    );

    // 4. Compensation on failure of step 2: revert booking to inConsultation
    if (visitRes.isLeft()) {
      await bookingsRepo.changeBookingStatus(
        ChangeBookingStatusParams(
          bookingId: bookingId,
          newStatus: BookingStatusEnum.inConsultation,
        ),
      );
      return visitRes;
    }

    final finalizedVisit =
        visitRes.getOrElse(() => throw StateError('unreachable'));

    // 5. Security Audit Log (Identifiers only, zero clinical content)
    auditLogger?.log(
      eventType: 'visit_finalized',
      performedByUserId:
          permissionEvaluator?.userProvider.currentUser?.id ??
              finalContent.doctorId,
      performedByUserName:
          permissionEvaluator?.userProvider.currentUser?.fullName ??
              finalContent.doctorName,
      branchId: finalContent.branchId,
      details:
          'visitId=${finalizedVisit.id}, bookingId=${finalContent.bookingId}, doctorId=${finalContent.doctorId}, finalizedAt=${finalizedVisit.finalizedAt?.toIso8601String()}',
    );

    return visitRes;
  }
}
