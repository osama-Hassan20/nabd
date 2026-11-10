import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../../users_management/data/repositories/staff_users_repo.dart';
import '../../data/models/booking_model.dart';
import '../helpers/booking_discount_policy_resolver.dart';
import '../repo/bookings_repo.dart';
import 'params/remove_discount_params.dart';

class RemoveBookingDiscountUseCase
    implements UseCase<BookingModel, RemoveDiscountParams> {
  final BookingsRepo bookingsRepo;
  final StaffUsersRepo? staffUsersRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  RemoveBookingDiscountUseCase({
    required this.bookingsRepo,
    this.staffUsersRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  @override
  Future<Either<Failures, BookingModel>> call(
    RemoveDiscountParams params,
  ) async {
    // 1. Reason required
    if (params.reason == null || params.reason!.trim().isEmpty) {
      return const Left(
        ValidationFailure(errMessage: 'disc_validation_reason_required'),
      );
    }

    // 2. Fetch booking
    final bookingRes =
        await bookingsRepo.getBookingById(params.bookingId ?? '');
    if (bookingRes.isLeft()) {
      return const Left(ValidationFailure(errMessage: 'booking_not_found'));
    }
    final booking = bookingRes.getOrElse(() => throw StateError(''));

    // 3. Resolve actor policy from session
    final policy = await BookingDiscountPolicyResolver.resolve(
      currentUserProvider: currentUserProvider,
      permissionEvaluator: permissionEvaluator,
      staffUsersRepo: staffUsersRepo,
      branchId: booking.branchId,
      fallbackUserId: params.removedByUserId,
    );

    if (policy.actor == null) {
      return const Left(ValidationFailure(errMessage: 'staff_user_not_found'));
    }

    if (!policy.isOwner && !policy.hasApplyPermission) {
      return const Left(
        ValidationFailure(errMessage: 'disc_validation_no_permission'),
      );
    }

    final prevType = booking.discountType;
    final prevVal = booking.discountValue;

    // 4. Remove discount via repo using actor's ID (ignoring caller-passed removedByUserId)
    final effectiveParams = RemoveDiscountParams(
      bookingId: params.bookingId,
      reason: params.reason,
      removedByUserId: policy.actor!.id,
    );

    final removeRes = await bookingsRepo.removeDiscount(effectiveParams);
    return removeRes.fold(
      (failure) => Left(failure),
      (updated) {
        auditLogger?.log(
          eventType: 'booking_discount_removed',
          targetUserId: booking.patientId,
          performedByUserId: policy.actor!.id,
          branchId: booking.branchId,
          details:
              'Discount removed: previousType ${prevType?.value}, previousValue $prevVal, reason: ${params.reason}',
        );
        return Right(updated);
      },
    );
  }
}
