import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../../users_management/data/models/role_definition_model.dart';
import '../../../users_management/data/repositories/staff_users_repo.dart';
import '../../data/models/booking_model.dart';
import '../helpers/booking_discount_validator.dart';
import '../repo/bookings_repo.dart';
import 'params/apply_discount_params.dart';

class ApplyBookingDiscountUseCase
    implements UseCase<BookingModel, ApplyDiscountParams> {
  final BookingsRepo bookingsRepo;
  final StaffUsersRepo staffUsersRepo;
  final PermissionEvaluator? permissionEvaluator;
  final AuditLogger? auditLogger;

  ApplyBookingDiscountUseCase({
    required this.bookingsRepo,
    required this.staffUsersRepo,
    this.permissionEvaluator,
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

    // 2. Fetch actor
    final actorRes =
        await staffUsersRepo.getStaffUserById(params.approvedByUserId ?? '');
    if (actorRes.isLeft()) {
      return const Left(ValidationFailure(errMessage: 'staff_user_not_found'));
    }
    final actor = actorRes.getOrElse(() => throw StateError(''));

    // 3. Resolve permissions & role policy
    final isOwner = actor.isOwner == true;
    bool hasApplyPermission = isOwner;
    num? maxDiscountPercent;
    bool? canGrantFreeConsultation;

    if (!isOwner) {
      if (permissionEvaluator != null) {
        hasApplyPermission = permissionEvaluator!.can(
          StaffPermissionEnum.applyBookingDiscount,
          branchId: booking.branchId,
        );
      }

      final rolesRes = await staffUsersRepo.getRoles();
      List<RoleDefinitionModel> allRoles = [];
      rolesRes.fold((_) => null, (r) => allRoles = r);

      final branchAssignment = actor.branchAssignments
              ?.where((b) => b.branchId == booking.branchId)
              .firstOrNull ??
          actor.branchAssignments?.firstOrNull;

      final roleIds = branchAssignment?.roleIds ?? [];
      for (final rId in roleIds) {
        final roleDef = allRoles.where((r) => r.id == rId).firstOrNull;
        if (roleDef != null) {
          if (permissionEvaluator == null &&
              (roleDef.permissions
                      ?.contains(StaffPermissionEnum.applyBookingDiscount) ??
                  false)) {
            hasApplyPermission = true;
          }
          final p = roleDef.maxDiscountPercent;
          if (p != null) {
            maxDiscountPercent = maxDiscountPercent == null
                ? p
                : (p > maxDiscountPercent ? p : maxDiscountPercent);
          }
          if (roleDef.canGrantFreeConsultation == true) {
            canGrantFreeConsultation = true;
          }
        }
      }
    } else {
      hasApplyPermission = true;
      maxDiscountPercent = 100;
      canGrantFreeConsultation = true;
    }

    // 4. Validate
    final error = BookingDiscountValidator.validate(
      booking: booking,
      discountType: params.discountType,
      discountValue: params.discountValue,
      reason: params.reason,
      isOwner: isOwner,
      hasApplyPermission: hasApplyPermission,
      maxDiscountPercent: maxDiscountPercent,
      canGrantFreeConsultation: canGrantFreeConsultation,
    );

    if (error != null) {
      return Left(ValidationFailure(errMessage: error));
    }

    // 5. Apply discount via repo
    final applyRes = await bookingsRepo.applyDiscount(params);
    return applyRes.fold(
      (failure) => Left(failure),
      (updated) {
        auditLogger?.log(
          eventType: 'booking_discount_applied',
          targetUserId: booking.patientId,
          performedByUserId: params.approvedByUserId,
          branchId: booking.branchId,
          details:
              'Discount applied: type ${params.discountType?.value}, value ${params.discountValue}, netAmount ${updated.netAmount}, reason: ${params.reason}',
        );
        return Right(updated);
      },
    );
  }
}
