import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/enums/discount_type_enum.dart';
import '../repo/bookings_repo.dart';

class CreateBookingUseCase implements UseCase<BookingModel, BookingModel> {
  final BookingsRepo repo;
  final PermissionEvaluator? permissionEvaluator;

  CreateBookingUseCase({
    required this.repo,
    this.permissionEvaluator,
  });

  @override
  Future<Either<Failures, BookingModel>> call(
    BookingModel booking, {
    DateTime? customNow,
  }) async {
    if (booking.discountType != null &&
        booking.discountType != DiscountTypeEnum.none &&
        permissionEvaluator != null) {
      final hasPerm = permissionEvaluator!.can(
        StaffPermissionEnum.applyBookingDiscount,
        branchId: booking.branchId,
      );
      if (!hasPerm) {
        return const Left(
          ValidationFailure(errMessage: 'disc_validation_no_permission'),
        );
      }
    }

    return repo.createBooking(booking, customNow: customNow);
  }
}
