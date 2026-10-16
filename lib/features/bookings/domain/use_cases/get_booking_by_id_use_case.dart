import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/booking_model.dart';
import '../repo/bookings_repo.dart';

class GetBookingByIdUseCase implements UseCase<BookingModel, String> {
  final BookingsRepo repo;

  GetBookingByIdUseCase({required this.repo});

  @override
  Future<Either<Failures, BookingModel>> call(String bookingId) {
    return repo.getBookingById(bookingId);
  }
}
