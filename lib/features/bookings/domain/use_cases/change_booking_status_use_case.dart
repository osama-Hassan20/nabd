import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../repo/bookings_repo.dart';
import 'params/change_booking_status_params.dart';

class ChangeBookingStatusUseCase implements UseCase<Unit, ChangeBookingStatusParams> {
  final BookingsRepo repo;

  ChangeBookingStatusUseCase({required this.repo});

  @override
  Future<Either<Failures, Unit>> call(ChangeBookingStatusParams params) {
    return repo.changeBookingStatus(params);
  }
}
