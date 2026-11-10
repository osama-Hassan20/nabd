import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../bookings/data/models/enums/booking_status_enum.dart';
import '../../../bookings/domain/repo/bookings_repo.dart';
import '../../data/models/visit_model.dart';
import '../../data/models/vitals_model.dart';
import '../repo/visits_repo.dart';

class RecordVitalsParams {
  final String bookingId;
  final String patientId;
  final String branchId;
  final String patientName;
  final String? patientPhone;
  final String doctorId;
  final String doctorName;
  final String? specialty;
  final VitalsModel vitals;

  const RecordVitalsParams({
    required this.bookingId,
    required this.patientId,
    required this.branchId,
    required this.patientName,
    this.patientPhone,
    required this.doctorId,
    required this.doctorName,
    this.specialty,
    required this.vitals,
  });
}

class RecordVitalsUseCase implements UseCase<VisitModel, RecordVitalsParams> {
  final VisitsRepo visitsRepo;
  final BookingsRepo bookingsRepo;

  RecordVitalsUseCase({
    required this.visitsRepo,
    required this.bookingsRepo,
  });

  @override
  Future<Either<Failures, VisitModel>> call(RecordVitalsParams params) async {
    final bookingRes = await bookingsRepo.getBookingById(params.bookingId);
    BookingStatusEnum? status;
    String? bBranchId;
    DateTime? bDate;

    bookingRes.fold(
      (failure) => null,
      (booking) {
        status = booking.status;
        bBranchId = booking.branchId;
        bDate = booking.date ?? booking.appointmentTime;
      },
    );

    if (bookingRes.isLeft()) {
      return const Left(ValidationFailure(errMessage: 'booking_not_found'));
    }

    if (status != BookingStatusEnum.waiting) {
      return const Left(
        ValidationFailure(
          errMessage: 'vitals_only_allowed_for_waiting_bookings',
        ),
      );
    }

    if (bBranchId != null && bBranchId != params.branchId) {
      return const Left(ValidationFailure(errMessage: 'branch_mismatch'));
    }

    if (bDate != null &&
        !CairoTimeHelper.isSameDay(bDate!, CairoTimeHelper.now())) {
      return const Left(
        ValidationFailure(errMessage: 'vitals_only_allowed_for_today_bookings'),
      );
    }

    return visitsRepo.recordVitals(
      bookingId: params.bookingId,
      patientId: params.patientId,
      branchId: params.branchId,
      patientName: params.patientName,
      patientPhone: params.patientPhone,
      doctorId: params.doctorId,
      doctorName: params.doctorName,
      specialty: params.specialty,
      vitals: params.vitals,
    );
  }
}
