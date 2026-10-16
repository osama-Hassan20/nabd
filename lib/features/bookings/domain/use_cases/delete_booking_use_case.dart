import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../repo/bookings_repo.dart';

class DeleteBookingUseCase implements UseCase<Unit, String> {
  final BookingsRepo repo;

  DeleteBookingUseCase({required this.repo});

  @override
  Future<Either<Failures, Unit>> call(String bookingId) {
    return repo.deleteBooking(bookingId);
  }
}
