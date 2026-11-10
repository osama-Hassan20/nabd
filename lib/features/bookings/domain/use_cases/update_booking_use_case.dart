import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/booking_model.dart';
import '../repo/bookings_repo.dart';

class UpdateBookingUseCase implements UseCase<BookingModel, BookingModel> {
  final BookingsRepo repo;
  final PermissionEvaluator? permissionEvaluator;

  UpdateBookingUseCase({
    required this.repo,
    this.permissionEvaluator,
  });

  @override
  Future<Either<Failures, BookingModel>> call(
    BookingModel booking, {
    DateTime? customNow,
  }) async {
    if (booking.id != null && permissionEvaluator != null) {
      final existingRes = await repo.getBookingById(booking.id!);
      BookingModel? existing;
      existingRes.fold((_) => null, (b) => existing = b);

      if (existing != null) {
        final discountChanged =
            existing!.discountType != booking.discountType ||
            existing!.discountValue != booking.discountValue;

        if (discountChanged) {
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
      }
    }

    return repo.updateBooking(booking, customNow: customNow);
  }
}
