import 'package:equatable/equatable.dart';
import '../../../data/models/enums/booking_status_enum.dart';

class ChangeBookingStatusParams extends Equatable {
  final String bookingId;
  final BookingStatusEnum newStatus;

  const ChangeBookingStatusParams({
    required this.bookingId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [bookingId, newStatus];
}
