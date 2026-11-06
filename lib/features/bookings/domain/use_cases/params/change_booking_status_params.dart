import 'package:equatable/equatable.dart';
import '../../../data/models/enums/booking_status_enum.dart';

class ChangeBookingStatusParams extends Equatable {
  final String bookingId;
  final BookingStatusEnum newStatus;

  // Postponement details
  final DateTime? rescheduledTo;
  final String? postponeReason;

  // Cancellation details
  final String? cancelReason;
  final String? cancelledBy; // 'patient' or 'clinic'
  final DateTime? cancelledAt;

  // Arrival details (e.g. converting back from noShow to waiting)
  final DateTime? arrivalTime;

  const ChangeBookingStatusParams({
    required this.bookingId,
    required this.newStatus,
    this.rescheduledTo,
    this.postponeReason,
    this.cancelReason,
    this.cancelledBy,
    this.cancelledAt,
    this.arrivalTime,
  });

  @override
  List<Object?> get props => [
        bookingId,
        newStatus,
        rescheduledTo,
        postponeReason,
        cancelReason,
        cancelledBy,
        cancelledAt,
        arrivalTime,
      ];
}
