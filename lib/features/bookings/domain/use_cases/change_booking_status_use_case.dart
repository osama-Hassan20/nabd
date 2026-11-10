import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../../visits/data/models/enums/visit_status_enum.dart';
import '../../data/models/enums/booking_status_enum.dart';
import '../contracts/active_visit_lookup.dart';
import '../repo/bookings_repo.dart';
import 'params/change_booking_status_params.dart';

class ChangeBookingStatusUseCase
    implements UseCase<Unit, ChangeBookingStatusParams> {
  final BookingsRepo repo;
  final ActiveVisitLookup? activeVisitLookup;

  ChangeBookingStatusUseCase({
    required this.repo,
    this.activeVisitLookup,
  });

  @override
  Future<Either<Failures, Unit>> call(ChangeBookingStatusParams params) async {
    if (activeVisitLookup != null) {
      final visitStatus =
          await activeVisitLookup!.getVisitStatusByBookingId(params.bookingId);
      if (visitStatus == VisitStatusEnum.inProgress) {
        if (params.newStatus == BookingStatusEnum.cancelled ||
            params.newStatus == BookingStatusEnum.noShow ||
            params.newStatus == BookingStatusEnum.postponed ||
            params.newStatus == BookingStatusEnum.waiting) {
          return const Left(
            ValidationFailure(
              errMessage: 'booking_locked_consultation_in_progress',
            ),
          );
        }
      }
    }
    return repo.changeBookingStatus(params);
  }
}
