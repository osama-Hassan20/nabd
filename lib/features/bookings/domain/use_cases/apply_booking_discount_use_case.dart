import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../../users_management/data/repositories/staff_users_repo.dart';
import '../../data/models/booking_model.dart';
import '../helpers/booking_discount_policy_resolver.dart';
import '../helpers/booking_discount_validator.dart';
import '../repo/bookings_repo.dart';
import 'params/apply_discount_params.dart';

class ApplyBookingDiscountUseCase
    implements UseCase<BookingModel, ApplyDiscountParams> {
  final BookingsRepo bookingsRepo;
  final StaffUsersRepo staffUsersRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  ApplyBookingDiscountUseCase({
    required this.bookingsRepo,
    required this.staffUsersRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  @override
  Future<Either<Failures, BookingModel>> call(
    ApplyDiscountParams params,
  ) async {
    // 1. Fetch booking
    final bookingRes =
        await bookingsRepo.getBookingById(params.bookingId ?? '');
    if (bookingRes.isLeft()) {
      return const Left(ValidationFailure(errMessage: 'booking_not_found'));
    }
    final booking = bookingRes.getOrElse(() => throw StateError(''));

    // 2. Resolve actor policy strictly from session
    final policy = await BookingDiscountPolicyResolver.resolve(
      currentUserProvider: currentUserProvider,
      permissionEvaluator: permissionEvaluator,
      staffUsersRepo: staffUsersRepo,
      branchId: booking.branchId,
      fallbackUserId: params.approvedByUserId,
    );

    if (policy.actor == null) {
      return const Left(ValidationFailure(errMessage: 'staff_user_not_found'));
    }

    // 3. Validate discount constraints
    final error = BookingDiscountValidator.validate(
      booking: booking,
      discountType: params.discountType,
      discountValue: params.discountValue,
      reason: params.reason,
      isOwner: policy.isOwner,
      hasApplyPermission: policy.hasApplyPermission,
      maxDiscountPercent: policy.maxDiscountPercent,
      canGrantFreeConsultation: policy.canGrantFreeConsultation,
    );

    if (error != null) {
      return Left(ValidationFailure(errMessage: error));
    }

    // 4. Apply discount via repo using actor's id (ignoring caller-passed approvedByUserId)
    final effectiveParams = ApplyDiscountParams(
      bookingId: params.bookingId,
      discountType: params.discountType,
      discountValue: params.discountValue,
      reason: params.reason,
      approvedByUserId: policy.actor!.id,
    );

    final applyRes = await bookingsRepo.applyDiscount(effectiveParams);
    return applyRes.fold(
      (failure) => Left(failure),
      (updated) {
        auditLogger?.log(
          eventType: 'booking_discount_applied',
          targetUserId: booking.patientId,
          performedByUserId: policy.actor!.id,
          branchId: booking.branchId,
          details:
              'Discount applied: type ${params.discountType?.value}, value ${params.discountValue}, netAmount ${updated.netAmount}, reason: ${params.reason}',
        );
        return Right(updated);
      },
    );
  }
}
