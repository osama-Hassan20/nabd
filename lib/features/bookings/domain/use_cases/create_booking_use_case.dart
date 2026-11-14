import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../../users_management/data/repositories/staff_users_repo.dart';
import '../../data/models/enums/payment_status_enum.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/enums/discount_type_enum.dart';
import '../helpers/booking_discount_policy_resolver.dart';
import '../helpers/booking_discount_validator.dart';
import '../repo/bookings_repo.dart';

class CreateBookingUseCase implements UseCase<BookingModel, BookingModel> {
  final BookingsRepo repo;
  final StaffUsersRepo? staffUsersRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  CreateBookingUseCase({
    required this.repo,
    this.staffUsersRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  @override
  Future<Either<Failures, BookingModel>> call(
    BookingModel booking, {
    DateTime? customNow,
  }) async {
    // M-5 rule: paidAmount is locked to 0 on creation; payments are registered through cashier only
    var bookingToCreate = booking.copyWith(
      paidAmount: 0,
      paymentStatus: booking.isFreeConsultation
          ? PaymentStatusEnum.paid
          : PaymentStatusEnum.unpaid,
    );

    if (booking.discountType != null &&
        booking.discountType != DiscountTypeEnum.none) {
      final policy = await BookingDiscountPolicyResolver.resolve(
        currentUserProvider: currentUserProvider,
        permissionEvaluator: permissionEvaluator,
        staffUsersRepo: staffUsersRepo,
        branchId: booking.branchId,
      );

      final error = BookingDiscountValidator.validate(
        booking: bookingToCreate,
        discountType: bookingToCreate.discountType,
        discountValue: bookingToCreate.discountValue,
        reason: bookingToCreate.discountReason,
        isOwner: policy.isOwner,
        hasApplyPermission: policy.hasApplyPermission,
        maxDiscountPercent: policy.maxDiscountPercent,
        canGrantFreeConsultation: policy.canGrantFreeConsultation,
      );

      if (error != null) {
        return Left(ValidationFailure(errMessage: error));
      }

      bookingToCreate = bookingToCreate.copyWith(
        discountApprovedByUserId: policy.actor?.id,
        discountApprovedAt: CairoTimeHelper.now(),
      );
    }

    final createRes =
        await repo.createBooking(bookingToCreate, customNow: customNow);
    return createRes.fold(
      (failure) => Left(failure),
      (saved) {
        if (saved.discountType != null &&
            saved.discountType != DiscountTypeEnum.none) {
          auditLogger?.log(
            eventType: 'booking_discount_applied',
            targetUserId: saved.patientId,
            performedByUserId: saved.discountApprovedByUserId,
            branchId: saved.branchId,
            details:
                'Discount applied on booking creation: type ${saved.discountType?.value}, value ${saved.discountValue}, reason: ${saved.discountReason}',
          );
        }
        return Right(saved);
      },
    );
  }
}
