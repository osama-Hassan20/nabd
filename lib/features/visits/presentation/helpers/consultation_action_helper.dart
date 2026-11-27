import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../bookings/data/models/enums/booking_status_enum.dart';
import '../../data/models/enums/visit_status_enum.dart';
import '../../data/models/visit_model.dart';

/// Centralized helper governing action permissions and visibility
/// across Visits queue, Bookings table, and Booking details.
class ConsultationActionHelper {
  ConsultationActionHelper._();

  /// Validates whether a booking is scheduled for today in Cairo timezone.
  static bool isTodayBooking(DateTime? appointmentTime) {
    if (appointmentTime == null) return false;
    return CairoTimeHelper.isToday(appointmentTime);
  }

  /// Validates whether a booking belongs to the user's active branch.
  static bool isCurrentBranch(String? bookingBranchId, String? activeBranchId) {
    if (bookingBranchId == null || activeBranchId == null) return false;
    return bookingBranchId == activeBranchId;
  }

  /// Checks if the current user can start consultation for a waiting booking:
  /// - Booking status is waiting
  /// - Booking is today (CairoTimeHelper)
  /// - Booking is in active branch
  /// - User has startConsultation permission
  /// - User is a practicing doctor assigned to this booking (linkedDoctorId == booking.doctorId)
  static bool canStartConsultation({
    required BookingModel? booking,
    required VisitModel? visit,
    required PermissionEvaluator evaluator,
  }) {
    if (booking == null) return false;
    if (booking.status != BookingStatusEnum.waiting) return false;
    if (visit != null && visit.status != VisitStatusEnum.triage) return false;
    if (!isTodayBooking(booking.appointmentTime)) return false;
    if (!isCurrentBranch(
      booking.branchId,
      evaluator.userProvider.activeBranchId,
    )) {
      return false;
    }

    final user = evaluator.userProvider.currentUser;
    if (user == null || !user.isPracticingDoctor) return false;
    if (user.linkedDoctorId == null || user.linkedDoctorId != booking.doctorId) {
      return false;
    }

    return evaluator.can(
      StaffPermissionEnum.startConsultation,
      branchId: booking.branchId,
      patientDoctorIds: booking.doctorId != null ? {booking.doctorId!} : null,
    );
  }

  /// Checks if the current user can continue an in-progress consultation:
  /// - Booking is inConsultation OR visit is inProgress
  /// - Booking is today (CairoTimeHelper)
  /// - Booking is in active branch
  /// - User has startConsultation permission
  /// - User is a practicing doctor assigned to this booking
  static bool canContinueConsultation({
    required BookingModel? booking,
    required VisitModel? visit,
    required PermissionEvaluator evaluator,
  }) {
    if (booking == null) return false;
    final isInProgress = booking.status == BookingStatusEnum.inConsultation ||
        visit?.status == VisitStatusEnum.inProgress;
    if (!isInProgress) return false;
    if (booking.status == BookingStatusEnum.completed ||
        visit?.status == VisitStatusEnum.finalized) {
      return false;
    }
    if (!isTodayBooking(booking.appointmentTime)) return false;
    if (!isCurrentBranch(
      booking.branchId,
      evaluator.userProvider.activeBranchId,
    )) {
      return false;
    }

    final user = evaluator.userProvider.currentUser;
    if (user == null || !user.isPracticingDoctor) return false;
    if (user.linkedDoctorId == null || user.linkedDoctorId != booking.doctorId) {
      return false;
    }

    return evaluator.can(
      StaffPermissionEnum.startConsultation,
      branchId: booking.branchId,
      patientDoctorIds: booking.doctorId != null ? {booking.doctorId!} : null,
    );
  }

  /// Checks if the current user can record/update vital signs:
  /// - Booking status is waiting (visit is null or triage)
  /// - Booking is today (CairoTimeHelper)
  /// - Booking is in active branch
  /// - User has recordVitals permission
  static bool canRecordVitals({
    required BookingModel? booking,
    required VisitModel? visit,
    required PermissionEvaluator evaluator,
  }) {
    if (booking == null) return false;
    if (booking.status != BookingStatusEnum.waiting &&
        booking.status != BookingStatusEnum.scheduled) {
      return false;
    }
    if (visit != null && visit.status != VisitStatusEnum.triage) return false;
    if (!isTodayBooking(booking.appointmentTime ?? booking.date)) return false;
    if (booking.branchId != null &&
        evaluator.userProvider.activeBranchId != null &&
        booking.branchId != evaluator.userProvider.activeBranchId) {
      return false;
    }

    final user = evaluator.userProvider.currentUser;
    if (user != null && user.isOwner == true && !user.isPracticingDoctor) {
      return false; // Non-practicing owner does not record vitals in UI
    }

    return evaluator.can(
      StaffPermissionEnum.recordVitals,
      branchId: booking.branchId,
    );
  }

  /// Checks if the current user can view a finalized consultation:
  /// - Booking is completed AND Visit is finalized (both must exist, visit not null)
  /// - User has viewConsultationNotes permission in that branch
  static bool canViewConsultation({
    required BookingModel? booking,
    required VisitModel? visit,
    required PermissionEvaluator evaluator,
  }) {
    if (booking == null || visit == null) return false;
    if (visit.status != VisitStatusEnum.finalized) return false;

    return evaluator.can(
      StaffPermissionEnum.viewConsultationNotes,
      branchId: booking.branchId,
    );
  }

  /// Returns the localization key for the consultation action button:
  /// - 'visits_complete_vitals' if triage visit exists
  /// - 'visits_start_consultation' if waiting without visit
  /// - 'visits_continue_consultation' if in progress
  static String getConsultationButtonKey({
    required BookingModel? booking,
    required VisitModel? visit,
  }) {
    if (booking?.status == BookingStatusEnum.inConsultation ||
        visit?.status == VisitStatusEnum.inProgress) {
      return 'visits_continue_consultation';
    }
    if (visit?.status == VisitStatusEnum.triage) {
      return 'visits_complete_vitals';
    }
    return 'visits_start_consultation';
  }
}

