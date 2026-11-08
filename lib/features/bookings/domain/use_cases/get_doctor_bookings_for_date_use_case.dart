import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';

class GetDoctorBookingsForDateUseCase {
  final BookingsRepo repo;

  GetDoctorBookingsForDateUseCase({required this.repo});

  Future<Either<Failures, List<BookingModel>>> call({
    required String doctorId,
    required DateTime date,
  }) {
    return repo.getDoctorBookingsForDate(doctorId: doctorId, date: date);
  }
}

