import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../../users_management/data/repositories/staff_users_repo.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/enums/discount_type_enum.dart';
import '../helpers/booking_discount_policy_resolver.dart';
import '../helpers/booking_discount_validator.dart';
import '../repo/bookings_repo.dart';

class UpdateBookingResult {
  final BookingModel booking;
  final String? discountResetKey;

  const UpdateBookingResult({
    required this.booking,
    this.discountResetKey,
  });
}

class UpdateBookingUseCase
    implements UseCase<UpdateBookingResult, BookingModel> {
  final BookingsRepo repo;
  final StaffUsersRepo? staffUsersRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  UpdateBookingUseCase({
    required this.repo,
    this.staffUsersRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  @override
  Future<Either<Failures, UpdateBookingResult>> call(
    BookingModel booking, {
    DateTime? customNow,
  }) async {
    final existingRes = await repo.getBookingById(booking.id ?? '');
    if (existingRes.isLeft()) {
      return const Left(ValidationFailure(errMessage: 'booking_not_found'));
    }
    final existing = existingRes.getOrElse(() => throw StateError(''));

    final policy = await BookingDiscountPolicyResolver.resolve(
      currentUserProvider: currentUserProvider,
      permissionEvaluator: permissionEvaluator,
      staffUsersRepo: staffUsersRepo,
      branchId: booking.branchId,
    );

    final existingHadDiscount = existing.discountType != null &&
        existing.discountType != DiscountTypeEnum.none;
    final newHasDiscount = booking.discountType != null &&
        booking.discountType != DiscountTypeEnum.none;

    final discountChanged = existing.discountType != booking.discountType ||
        existing.discountValue != booking.discountValue ||
        existing.discountReason != booking.discountReason;

    final feeChanged = existing.consultationFee != booking.consultationFee;

    // M-5 rule: prevent manual tampering of paidAmount and paymentStatus from booking update
    var bookingToUpdate = booking.copyWith(
      paidAmount: existing.paidAmount,
      paymentStatus: existing.paymentStatus,
    );
    bool discountResetOccurred = false;

    // Rule 1: Changing fee on a booking with active discount requires applyBookingDiscount
    if (feeChanged && existingHadDiscount) {
      if (!policy.hasApplyPermission) {
        return const Left(
          ValidationFailure(errMessage: 'disc_validation_no_permission'),
        );
      }
    }

    // Rule 2: If discount fields changed
    if (discountChanged) {
      if (!policy.hasApplyPermission) {
        return const Left(
          ValidationFailure(errMessage: 'disc_validation_no_permission'),
        );
      }

      if (newHasDiscount) {
        final error = BookingDiscountValidator.validate(
          booking: bookingToUpdate,
          discountType: bookingToUpdate.discountType,
          discountValue: bookingToUpdate.discountValue,
          reason: bookingToUpdate.discountReason,
          isOwner: policy.isOwner,
          hasApplyPermission: policy.hasApplyPermission,
          maxDiscountPercent: policy.maxDiscountPercent,
          canGrantFreeConsultation: policy.canGrantFreeConsultation,
        );
        if (error != null) {
          return Left(ValidationFailure(errMessage: error));
        }
        bookingToUpdate = bookingToUpdate.copyWith(
          discountApprovedByUserId: policy.actor?.id,
          discountApprovedAt: CairoTimeHelper.now(),
        );
      } else if (existingHadDiscount && !newHasDiscount) {
        if (bookingToUpdate.discountRemovedReason == null ||
            bookingToUpdate.discountRemovedReason!.trim().isEmpty) {
          return const Left(
            ValidationFailure(errMessage: 'disc_validation_reason_required'),
          );
        }
      }
    }

    // Rule 3: Re-validate discount if fee changed on a discounted booking
    if (feeChanged && (existingHadDiscount || newHasDiscount)) {
      final error = BookingDiscountValidator.validate(
        booking: bookingToUpdate,
        discountType: bookingToUpdate.discountType,
        discountValue: bookingToUpdate.discountValue,
        reason: bookingToUpdate.discountReason,
        isOwner: policy.isOwner,
        hasApplyPermission: policy.hasApplyPermission,
        maxDiscountPercent: policy.maxDiscountPercent,
        canGrantFreeConsultation: policy.canGrantFreeConsultation,
      );

      if (error != null) {
        discountResetOccurred = true;
        final prevType = bookingToUpdate.discountType;
        final prevVal = bookingToUpdate.discountValue;

        bookingToUpdate = bookingToUpdate.copyWith(
          discountType: DiscountTypeEnum.none,
          discountValue: 0,
          clearDiscountReason: true,
          discountApprovedByUserId: null,
          discountApprovedAt: null,
          discountRemovedReason: 'fee_changed',
        );

        auditLogger?.log(
          eventType: 'booking_discount_removed',
          targetUserId: existing.patientId,
          performedByUserId: policy.actor?.id,
          branchId: existing.branchId,
          details:
              'Discount removed due to consultation fee change: previousType ${prevType?.value}, previousValue $prevVal, reason: fee_changed',
        );
      }
    }

    final updateRes =
        await repo.updateBooking(bookingToUpdate, customNow: customNow);
    return updateRes.fold(
      (failure) => Left(failure),
      (saved) {
        if (discountChanged &&
            newHasDiscount &&
            saved.discountRemovedReason != 'fee_changed') {
          auditLogger?.log(
            eventType: 'booking_discount_applied',
            targetUserId: existing.patientId,
            performedByUserId: policy.actor?.id,
            branchId: existing.branchId,
            details:
                'Discount updated: type ${saved.discountType?.value}, value ${saved.discountValue}, reason: ${saved.discountReason}',
          );
        } else if (discountChanged &&
            existingHadDiscount &&
            !newHasDiscount &&
            saved.discountRemovedReason != 'fee_changed') {
          auditLogger?.log(
            eventType: 'booking_discount_removed',
            targetUserId: existing.patientId,
            performedByUserId: policy.actor?.id,
            branchId: existing.branchId,
            details:
                'Discount removed on update: reason: ${saved.discountRemovedReason}',
          );
        }
        return Right(
          UpdateBookingResult(
            booking: saved,
            discountResetKey: discountResetOccurred
                ? 'disc_removed_due_to_fee_change'
                : null,
          ),
        );
      },
    );
  }
}
