import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../../visits/data/models/enums/visit_status_enum.dart';
import '../contracts/active_visit_lookup.dart';
import '../repo/bookings_repo.dart';

class DeleteBookingUseCase implements UseCase<Unit, String> {
  final BookingsRepo repo;
  final ActiveVisitLookup? activeVisitLookup;

  DeleteBookingUseCase({
    required this.repo,
    this.activeVisitLookup,
  });

  @override
  Future<Either<Failures, Unit>> call(String bookingId) async {
    if (activeVisitLookup != null) {
      final visitStatus =
          await activeVisitLookup!.getVisitStatusByBookingId(bookingId);
      if (visitStatus == VisitStatusEnum.inProgress ||
          visitStatus == VisitStatusEnum.triage) {
        return const Left(
          ValidationFailure(
            errMessage: 'booking_locked_cannot_delete_active_visit',
          ),
        );
      }
    }
    return repo.deleteBooking(bookingId);
  }
}
