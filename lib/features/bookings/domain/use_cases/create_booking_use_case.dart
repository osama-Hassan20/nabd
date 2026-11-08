import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/booking_model.dart';
import '../repo/bookings_repo.dart';

class CreateBookingUseCase implements UseCase<BookingModel, BookingModel> {
  final BookingsRepo repo;

  CreateBookingUseCase({required this.repo});

  @override
  Future<Either<Failures, BookingModel>> call(
    BookingModel booking, {
    DateTime? customNow,
  }) {
    return repo.createBooking(booking, customNow: customNow);
  }
}
