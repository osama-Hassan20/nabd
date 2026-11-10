import 'package:equatable/equatable.dart';

class RemoveDiscountParams extends Equatable {
  final String? bookingId;
  final String? reason;
  final String? removedByUserId;

  const RemoveDiscountParams({
    this.bookingId,
    this.reason,
    this.removedByUserId,
  });

  @override
  List<Object?> get props => [
        bookingId,
        reason,
        removedByUserId,
      ];
}
