import 'package:equatable/equatable.dart';
import '../../../data/models/enums/discount_type_enum.dart';

class ApplyDiscountParams extends Equatable {
  final String? bookingId;
  final DiscountTypeEnum? discountType;
  final num? discountValue;
  final String? reason;
  final String? approvedByUserId;

  const ApplyDiscountParams({
    this.bookingId,
    this.discountType,
    this.discountValue,
    this.reason,
    this.approvedByUserId,
  });

  @override
  List<Object?> get props => [
        bookingId,
        discountType,
        discountValue,
        reason,
        approvedByUserId,
      ];
}
