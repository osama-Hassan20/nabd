import '../../data/models/booking_model.dart';
import '../../data/models/enums/booking_status_enum.dart';
import '../../data/models/enums/discount_type_enum.dart';

class BookingDiscountValidator {
  BookingDiscountValidator._();

  static String? validate({
    required BookingModel booking,
    required DiscountTypeEnum? discountType,
    required num? discountValue,
    required String? reason,
    required bool isOwner,
    required bool hasApplyPermission,
    num? maxDiscountPercent,
    bool? canGrantFreeConsultation,
  }) {
    // 1. Permission check
    if (!isOwner && !hasApplyPermission) {
      return 'disc_validation_no_permission';
    }

    // 2. Cancelled booking check
    if (booking.status == BookingStatusEnum.cancelled) {
      return 'disc_validation_cancelled_booking';
    }

    // 3. Reason check
    final effectiveType = discountType ?? DiscountTypeEnum.none;
    if (effectiveType == DiscountTypeEnum.free) {
      if (reason == null || reason.trim().isEmpty) {
        return 'disc_validation_free_reason_required';
      }
    } else if (effectiveType != DiscountTypeEnum.none) {
      if (reason == null || reason.trim().isEmpty) {
        return 'disc_validation_reason_required';
      }
    }

    final fee = booking.consultationFee ?? 0;

    // 4. Value ranges
    if (effectiveType == DiscountTypeEnum.percentage) {
      final val = discountValue ?? 0;
      if (val < 0 || val > 100) {
        return 'disc_validation_pct_range';
      }
    } else if (effectiveType == DiscountTypeEnum.fixedAmount) {
      final val = discountValue ?? 0;
      if (val < 0 || val > fee) {
        return 'disc_validation_fixed_range';
      }
    }

    // 5. Free consultation / 100% evaluation
    final isFree = effectiveType == DiscountTypeEnum.free ||
        (effectiveType == DiscountTypeEnum.percentage &&
            (discountValue ?? 0) >= 100) ||
        (effectiveType == DiscountTypeEnum.fixedAmount &&
            (discountValue ?? 0) >= fee &&
            fee > 0);

    if (isFree && !isOwner) {
      if (canGrantFreeConsultation != true) {
        return 'disc_validation_free_required';
      }
    }

    // 6. Max discount limit check (convert fixed to percentage)
    if (!isOwner) {
      num effectivePct = 0;
      if (effectiveType == DiscountTypeEnum.percentage) {
        effectivePct = discountValue ?? 0;
      } else if (effectiveType == DiscountTypeEnum.fixedAmount) {
        effectivePct = fee > 0 ? ((discountValue ?? 0) / fee) * 100 : 0;
      } else if (effectiveType == DiscountTypeEnum.free) {
        effectivePct = 100;
      }

      final limit = maxDiscountPercent ?? 0;
      if (effectivePct > limit) {
        return 'disc_validation_max_exceeded';
      }
    }

    // 7. Net amount cannot be less than paid amount
    num calcDiscount = 0;
    if (effectiveType == DiscountTypeEnum.free) {
      calcDiscount = fee;
    } else if (effectiveType == DiscountTypeEnum.percentage) {
      final pct = (discountValue ?? 0).clamp(0, 100);
      calcDiscount = (fee * pct / 100);
    } else if (effectiveType == DiscountTypeEnum.fixedAmount) {
      calcDiscount = (discountValue ?? 0).clamp(0, fee);
    }
    final netAmount = (fee - calcDiscount).clamp(0, double.infinity);
    final paid = booking.paidAmount ?? 0;
    if (netAmount < paid) {
      return 'disc_validation_below_paid';
    }

    return null;
  }
}

