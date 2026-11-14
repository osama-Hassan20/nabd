import '../../../../../core/base/safe_cubit.dart';
import '../../../../../core/services/permission_evaluator.dart';
import '../../../../../core/utils/enums/request_status_enum.dart';
import '../../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../../bookings/data/models/booking_model.dart';
import '../../../../patients/domain/repo/patients_repo.dart';
import '../../../data/models/consultation_queue_item_model.dart';
import '../../../data/models/visit_model.dart';
import '../../../domain/use_cases/get_doctor_queue_use_case.dart';
import '../../../domain/use_cases/start_consultation_use_case.dart';
import '../visits_state.dart';

mixin VisitQueueMixin on SafeCubit<VisitsState> {
  PermissionEvaluator get permissionEvaluator;
  GetDoctorQueueUseCase get getDoctorQueueUseCase;
  StartConsultationUseCase get startConsultationUseCase;
  PatientsRepo get patientsRepo;

  Future<void> loadDoctorQueue({
    String? doctorId,
    String? branchId,
    DateTime? date,
  }) async {
    final currentUser = permissionEvaluator.userProvider.currentUser;
    final targetBranch = branchId ??
        permissionEvaluator.userProvider.activeBranchId ??
        'branch_1';
    final targetDate = date ?? state.filterDate ?? CairoTimeHelper.now();

    String? effectiveDoctorId;
    if (currentUser != null &&
        currentUser.isPracticingDoctor &&
        currentUser.isOwner != true) {
      effectiveDoctorId = currentUser.linkedDoctorId;
    } else {
      effectiveDoctorId = doctorId ?? state.filterDoctorId;
    }

    emit(
      state.copyWith(
        queueStatus: RequestStatusEnum.loading,
        filterDoctorId: effectiveDoctorId,
        clearFilterDoctorId: effectiveDoctorId == null,
        filterDate: targetDate,
      ),
    );

    final res = await getDoctorQueueUseCase(
      GetDoctorQueueParams(
        doctorId: effectiveDoctorId,
        branchId: targetBranch,
        date: targetDate,
      ),
    );

    res.fold(
      (failure) {
        emit(
          state.copyWith(
            queueStatus: RequestStatusEnum.failure,
            errorMessage: failure.errMessage,
          ),
        );
      },
      (queue) {
        emit(
          state.copyWith(
            queueStatus: RequestStatusEnum.success,
            queue: queue,
            clearErrorMessage: true,
          ),
        );
      },
    );
  }

  void setFilterDoctorId(String? doctorId) {
    loadDoctorQueue(doctorId: doctorId);
  }

  void setFilterDate(DateTime date) {
    loadDoctorQueue(date: date);
  }

  Future<void> loadPatientAllergies(String patientId) async {
    final patientRes = await patientsRepo.getPatientById(id: patientId);
    patientRes.fold(
      (failure) => null,
      (patient) {
        emit(
          state.copyWith(
            patientAllergies: patient.allergies ?? const [],
          ),
        );
      },
    );
  }

  Future<VisitModel?> startConsultationForBooking(BookingModel booking) {
    return startConsultation(ConsultationQueueItemModel(booking: booking));
  }

  Future<VisitModel?> startConsultation(ConsultationQueueItemModel item) async {
    final booking = item.booking;
    if (booking == null) return null;

    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final res = await startConsultationUseCase(
      StartConsultationParams(
        bookingId: booking.id ?? '',
        patientId: booking.patientId ?? '',
        branchId: booking.branchId ?? 'branch_1',
        patientName: booking.patientName ?? '',
        patientPhone: booking.patientPhone,
        doctorId: booking.doctorId ?? '',
        doctorName: booking.doctorName ?? '',
        specialty: booking.specialty,
      ),
    );

    return res.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errorMessage: failure.errMessage,
          ),
        );
        return null;
      },
      (startedVisit) {
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        loadDoctorQueue();
        return startedVisit;
      },
    );
  }
}
