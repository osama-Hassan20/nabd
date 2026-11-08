import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/params.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/booking_summary_model.dart';
import '../../data/models/bookings_response_model.dart';
import '../use_cases/params/change_booking_status_params.dart';
import '../use_cases/params/reassign_technician_params.dart';

abstract class BookingsRepo {
  Future<Either<Failures, BookingSummaryModel>> getBookingSummary({
    DateTime? date,
    String? branchId,
  });
  Future<Either<Failures, BookingsResponseModel>> getBookings(
    PaginationParams params,
  );
  Future<Either<Failures, BookingModel>> getBookingById(String id);
  Future<Either<Failures, BookingModel>> createBooking(
    BookingModel booking, {
    DateTime? customNow,
  });
  Future<Either<Failures, BookingModel>> updateBooking(
    BookingModel booking, {
    DateTime? customNow,
  });
  Future<Either<Failures, List<BookingModel>>> getDoctorBookingsForDate({
    required String doctorId,
    required DateTime date,
  });
  Future<Either<Failures, Unit>> changeBookingStatus(
    ChangeBookingStatusParams params,
  );
  Future<Either<Failures, Unit>> reassignTechnician(
    ReassignTechnicianParams params,
  );
  Future<Either<Failures, Unit>> deleteBooking(String bookingId);
}
