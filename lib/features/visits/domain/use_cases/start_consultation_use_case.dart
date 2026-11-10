import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
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

  StartConsultationUseCase({
    required this.visitsRepo,
    required this.bookingsRepo,
  });

  @override
  Future<Either<Failures, VisitModel>> call(
    StartConsultationParams params,
  ) async {
    // 1. Fetch current booking to know previous status for rollback
    final bookingRes = await bookingsRepo.getBookingById(params.bookingId);
    if (bookingRes.isLeft()) {
      return const Left(ValidationFailure(errMessage: 'booking_not_found'));
    }

    final booking = bookingRes.getOrElse(() => throw StateError('unreachable'));
    final previousStatus = booking.status ?? BookingStatusEnum.waiting;

    // 2. Step 1: Change booking status to inConsultation directly via BookingsRepo
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

    // 3. Step 2: Upsert consultation start in visits repo
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

    // 4. Compensation on failure of step 2
    if (visitRes.isLeft()) {
      await bookingsRepo.changeBookingStatus(
        ChangeBookingStatusParams(
          bookingId: params.bookingId,
          newStatus: previousStatus,
        ),
      );
      return visitRes;
    }

    return visitRes;
  }
}
