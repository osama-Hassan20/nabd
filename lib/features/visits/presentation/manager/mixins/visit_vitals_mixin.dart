import '../../../../../core/base/safe_cubit.dart';
import '../../../../../core/utils/enums/request_status_enum.dart';
import '../../../data/models/consultation_queue_item_model.dart';
import '../../../data/models/vitals_model.dart';
import '../../../domain/use_cases/record_vitals_use_case.dart';
import '../visits_state.dart';

mixin VisitVitalsMixin on SafeCubit<VisitsState> {
  RecordVitalsUseCase get recordVitalsUseCase;
  Future<void> loadDoctorQueue({String? doctorId, String? branchId, DateTime? date});
  Future<void> loadPatientAllergies(String patientId);

  void initRecordVitals(ConsultationQueueItemModel item) {
    final existingVitals = item.visit?.vitals ?? const VitalsModel();
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          vitals: existingVitals,
          isDirty: false,
        ),
        patientAllergies: const [],
      ),
    );
    if (item.booking?.patientId != null) {
      loadPatientAllergies(item.booking!.patientId!);
    }
  }

  void updateVitals(VitalsModel vitals) {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          vitals: vitals,
          isDirty: true,
        ),
      ),
    );
  }

  Future<bool> saveRecordedVitals(ConsultationQueueItemModel item) async {
    final booking = item.booking;
    if (booking == null) return false;

    return recordVitals(
      bookingId: booking.id ?? '',
      patientId: booking.patientId ?? '',
      branchId: booking.branchId ?? 'branch_1',
      patientName: booking.patientName ?? '',
      patientPhone: booking.patientPhone,
      doctorId: booking.doctorId ?? '',
      doctorName: booking.doctorName ?? '',
      specialty: booking.specialty,
      vitals: state.formState.vitals,
    );
  }

  Future<bool> recordVitals({
    required String bookingId,
    required String patientId,
    required String branchId,
    required String patientName,
    String? patientPhone,
    required String doctorId,
    required String doctorName,
    String? specialty,
    required VitalsModel vitals,
  }) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final res = await recordVitalsUseCase(
      RecordVitalsParams(
        bookingId: bookingId,
        patientId: patientId,
        branchId: branchId,
        patientName: patientName,
        patientPhone: patientPhone,
        doctorId: doctorId,
        doctorName: doctorName,
        specialty: specialty,
        vitals: vitals,
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
        return false;
      },
      (visit) {
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        loadDoctorQueue();
        return true;
      },
    );
  }
}
