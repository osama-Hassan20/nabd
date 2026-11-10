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

class StartConsultationParams {
  final String bookingId;
  final String patientId;
  final String branchId;
  final String patientName;
  final String? patientPhone;
  final String doctorId;
  final String doctorName;
  final String? specialty;

  const StartConsultationParams({
    required this.bookingId,
    required this.patientId,
    required this.branchId,
    required this.patientName,
    this.patientPhone,
    required this.doctorId,
    required this.doctorName,
    this.specialty,
  });
}

class StartConsultationUseCase
    implements UseCase<VisitModel, StartConsultationParams> {
  final VisitsRepo visitsRepo;
  final BookingsRepo bookingsRepo;
  final PermissionEvaluator? permissionEvaluator;
  final AuditLogger? auditLogger;

  StartConsultationUseCase({
    required this.visitsRepo,
    required this.bookingsRepo,
    this.permissionEvaluator,
    this.auditLogger,
  });

  @override
  Future<Either<Failures, VisitModel>> call(
    StartConsultationParams params,
  ) async {
    // 1. Fetch current booking to verify existence and assigned doctor
    final bookingRes = await bookingsRepo.getBookingById(params.bookingId);
    if (bookingRes.isLeft()) {
      return const Left(ValidationFailure(errMessage: 'booking_not_found'));
    }

    final booking = bookingRes.getOrElse(() => throw StateError('unreachable'));
    final bookingDoctorId = booking.doctorId ?? params.doctorId;
    final previousStatus = booking.status ?? BookingStatusEnum.waiting;

    // 2. Strict Permission Evaluation:
    // Requires: startConsultation permission + user.linkedDoctorId == booking.doctorId
    // - Non-practicing owner: REJECTED
    // - Practicing owner for another doctor: REJECTED
    // - Medical director / other roles: REJECTED unless assigned doctor (linkedDoctorId == booking.doctorId)
    if (permissionEvaluator != null) {
      final user = permissionEvaluator!.userProvider.currentUser;
      final hasPermission = permissionEvaluator!.can(
        StaffPermissionEnum.startConsultation,
        branchId: params.branchId,
        patientDoctorIds: {bookingDoctorId},
      );
      final isAssignedDoctor = user != null &&
          user.canAuthenticate == true &&
          user.isPracticingDoctor &&
          user.linkedDoctorId == bookingDoctorId;

      if (!hasPermission || !isAssignedDoctor) {
        return const Left(
          ValidationFailure(errMessage: 'permission_denied_start_consultation'),
        );
      }
    }

    // 3. Step 1: Change booking status to inConsultation directly via BookingsRepo
    final changeRes = await bookingsRepo.changeBookingStatus(
      ChangeBookingStatusParams(
        bookingId: params.bookingId,
        newStatus: BookingStatusEnum.inConsultation,
      ),
    );

    if (changeRes.isLeft()) {
      return changeRes.fold(
        (failure) => Left(failure),
        (_) => throw StateError('unreachable'),
      );
    }

    // 4. Step 2: Upsert consultation start in visits repo
    final visitRes = await visitsRepo.upsertConsultationStart(
      bookingId: params.bookingId,
      patientId: params.patientId,
      branchId: params.branchId,
      patientName: params.patientName,
      patientPhone: params.patientPhone,
      doctorId: params.doctorId,
      doctorName: params.doctorName,
      specialty: params.specialty,
    );

    // 5. Compensation on failure of step 2
    if (visitRes.isLeft()) {
      await bookingsRepo.changeBookingStatus(
        ChangeBookingStatusParams(
          bookingId: params.bookingId,
          newStatus: previousStatus,
        ),
      );
      return visitRes;
    }

    final startedVisit =
        visitRes.getOrElse(() => throw StateError('unreachable'));

    // 6. Security Audit Log (Identifiers only, zero clinical content)
    auditLogger?.log(
      eventType: 'visit_started',
      performedByUserId:
          permissionEvaluator?.userProvider.currentUser?.id ?? params.doctorId,
      performedByUserName:
          permissionEvaluator?.userProvider.currentUser?.fullName ??
              params.doctorName,
      branchId: params.branchId,
      details:
          'visitId=${startedVisit.id}, bookingId=${params.bookingId}, patientId=${params.patientId}, doctorId=${params.doctorId}, branchId=${params.branchId}',
    );

    return visitRes;
  }
}
