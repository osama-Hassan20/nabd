import '../../data/models/booking_model.dart';
import '../../data/models/enums/booking_status_enum.dart';
import '../../data/repo/bookings_mock_repo_impl.dart';
import '../../domain/repo/bookings_repo.dart';
import '../../../patients/domain/contracts/patient_balance_lookup.dart';

class BookingPatientBalanceLookupImpl implements PatientBalanceLookup {
  final BookingsRepo bookingsRepo;

  const BookingPatientBalanceLookupImpl(this.bookingsRepo);

  List<BookingModel> _getPatientBookings({
    required String patientId,
    String? fileNumber,
  }) {
    List<BookingModel> allBookings = const [];
    if (bookingsRepo is BookingsMockRepoImpl) {
      allBookings = (bookingsRepo as BookingsMockRepoImpl).bookings;
    }

    return allBookings.where((b) {
      return (b.patientId != null && b.patientId == patientId) ||
          (fileNumber != null &&
              b.fileNumber != null &&
              b.fileNumber == fileNumber) ||
          (b.customer?.id != null && b.customer!.id == patientId);
    }).toList();
  }

  @override
  num calculateOutstandingBalance({
    required String patientId,
    String? fileNumber,
  }) {
    final patientBookings = _getPatientBookings(
      patientId: patientId,
      fileNumber: fileNumber,
    );

    // RULE (M-5): Debt / Outstanding balance is calculated EXCLUSIVELY
    // from completed bookings. Uncompleted / upcoming bookings do not
    // generate an active overdue debt.
    final completedBookings = patientBookings
        .where((b) => b.status == BookingStatusEnum.completed)
        .toList();

    return completedBookings.fold<num>(
      0,
      (sum, b) {
        final fee = b.consultationFee ?? b.totalPrice ?? 0;
        final paid = b.paidAmount ?? 0;
        final due = fee - paid;
        return sum + (due > 0 ? due : 0);
      },
    );
  }

  @override
  num calculateTotalPaid({
    required String patientId,
    String? fileNumber,
  }) {
    final patientBookings = _getPatientBookings(
      patientId: patientId,
      fileNumber: fileNumber,
    );

    final nonCancelled = patientBookings
        .where((b) => b.status != BookingStatusEnum.cancelled)
        .toList();

    return nonCancelled.fold<num>(
      0,
      (sum, b) => sum + (b.paidAmount ?? 0),
    );
  }
}

