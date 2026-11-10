import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../../bookings/data/models/enums/booking_status_enum.dart';
import '../../../bookings/domain/repo/bookings_repo.dart';
import '../../../bookings/domain/use_cases/params/change_booking_status_params.dart';
import '../../data/models/visit_model.dart';
import '../repo/visits_repo.dart';

class FinalizeVisitUseCase implements UseCase<VisitModel, VisitModel> {
  final VisitsRepo visitsRepo;
  final BookingsRepo bookingsRepo;

  FinalizeVisitUseCase({
    required this.visitsRepo,
    required this.bookingsRepo,
  });

  @override
  Future<Either<Failures, VisitModel>> call(VisitModel finalContent) async {
    final bookingId = finalContent.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      return const Left(
        ValidationFailure(errMessage: 'booking_id_required_to_finalize'),
      );
    }

    // 1. Step 1: Change booking status to completed directly via BookingsRepo
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

    // 2. Step 2: Finalize visit in VisitsRepo
    final visitRes = await visitsRepo.finalizeVisit(
      finalContent: finalContent,
    );

    // 3. Compensation on failure of step 2: revert booking to inConsultation
    if (visitRes.isLeft()) {
      await bookingsRepo.changeBookingStatus(
        ChangeBookingStatusParams(
          bookingId: bookingId,
          newStatus: BookingStatusEnum.inConsultation,
        ),
      );
      return visitRes;
    }

    return visitRes;
  }
}
