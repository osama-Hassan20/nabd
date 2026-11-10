import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../../users_management/data/models/staff_user_model.dart';
import '../../../users_management/data/repositories/staff_users_repo.dart';
import '../../data/models/booking_model.dart';
import '../repo/bookings_repo.dart';
import 'params/remove_discount_params.dart';

class RemoveBookingDiscountUseCase
    implements UseCase<BookingModel, RemoveDiscountParams> {
  final BookingsRepo bookingsRepo;
  final StaffUsersRepo? staffUsersRepo;
  final PermissionEvaluator? permissionEvaluator;
  final AuditLogger? auditLogger;

  RemoveBookingDiscountUseCase({
    required this.bookingsRepo,
    this.staffUsersRepo,
    this.permissionEvaluator,
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

    // 3. Permission check
    if (staffUsersRepo != null && params.removedByUserId != null) {
      final actorRes =
          await staffUsersRepo!.getStaffUserById(params.removedByUserId!);
      StaffUserModel? actor;
      actorRes.fold((_) => null, (u) => actor = u);
      if (actor != null && actor!.isOwner != true) {
        if (permissionEvaluator != null &&
            !permissionEvaluator!.can(
              StaffPermissionEnum.applyBookingDiscount,
              branchId: booking.branchId,
            )) {
          return const Left(
            ValidationFailure(errMessage: 'disc_validation_no_permission'),
          );
        }
      }
    }

    final prevType = booking.discountType;
    final prevVal = booking.discountValue;

    // 4. Remove discount via repo
    final removeRes = await bookingsRepo.removeDiscount(params);
    return removeRes.fold(
      (failure) => Left(failure),
      (updated) {
        auditLogger?.log(
          eventType: 'booking_discount_removed',
          targetUserId: booking.patientId,
          performedByUserId: params.removedByUserId,
          branchId: booking.branchId,
          details:
              'Discount removed: previousType ${prevType?.value}, previousValue $prevVal, reason: ${params.reason}',
        );
        return Right(updated);
      },
    );
  }
}
