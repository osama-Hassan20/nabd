import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../../visits/data/models/enums/visit_status_enum.dart';
import '../contracts/active_visit_lookup.dart';
import '../repo/bookings_repo.dart';
import 'params/reassign_technician_params.dart';

class ReassignTechnicianUseCase
    implements UseCase<Unit, ReassignTechnicianParams> {
  final BookingsRepo repo;
  final ActiveVisitLookup? activeVisitLookup;

  ReassignTechnicianUseCase({
    required this.repo,
    this.activeVisitLookup,
  });

  @override
  Future<Either<Failures, Unit>> call(ReassignTechnicianParams params) async {
    if (activeVisitLookup != null) {
      final visitStatus =
          await activeVisitLookup!.getVisitStatusByBookingId(params.bookingId);
      if (visitStatus == VisitStatusEnum.inProgress) {
        return const Left(
          ValidationFailure(
            errMessage: 'booking_locked_cannot_reassign_in_progress',
          ),
        );
      }
    }
    return repo.reassignTechnician(params);
  }
}
