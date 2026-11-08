import '../../../../core/base/safe_cubit.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/medical_service_model.dart';
import '../../domain/use_cases/add_medical_service_use_case.dart';
import '../../domain/use_cases/delete_medical_service_use_case.dart';
import '../../domain/use_cases/get_medical_services_use_case.dart';
import '../../domain/use_cases/params/get_medical_services_params.dart';
import '../../domain/use_cases/toggle_medical_service_status_use_case.dart';
import '../../domain/use_cases/update_medical_service_use_case.dart';
import 'medical_services_state.dart';

class MedicalServicesCubit extends SafeCubit<MedicalServicesState> {
  final GetMedicalServicesUseCase getMedicalServicesUseCase;
  final AddMedicalServiceUseCase addMedicalServiceUseCase;
  final UpdateMedicalServiceUseCase updateMedicalServiceUseCase;
  final ToggleMedicalServiceStatusUseCase toggleMedicalServiceStatusUseCase;
  final DeleteMedicalServiceUseCase deleteMedicalServiceUseCase;

  MedicalServicesCubit({
    required this.getMedicalServicesUseCase,
    required this.addMedicalServiceUseCase,
    required this.updateMedicalServiceUseCase,
    required this.toggleMedicalServiceStatusUseCase,
    required this.deleteMedicalServiceUseCase,
  }) : super(const MedicalServicesState());

  Future<void> loadServices({bool showLoading = true}) async {
    if (showLoading) {
      emit(state.copyWith(status: RequestStatusEnum.loading));
    }
    final result = await getMedicalServicesUseCase(
      const GetMedicalServicesParams(),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ),
      ),
      (services) => emit(
        state.copyWith(
          status: RequestStatusEnum.success,
          services: services,
        ),
      ),
    );
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setStatusFilter(String filter) {
    emit(state.copyWith(statusFilter: filter));
  }

  void setDoctorFilter(String? doctorId) {
    if (doctorId == null || doctorId.isEmpty) {
      emit(state.copyWith(clearDoctorFilter: true));
    } else {
      emit(state.copyWith(doctorFilter: doctorId));
    }
  }

  void selectService(MedicalServiceModel? service) {
    if (service == null) {
      emit(state.copyWith(clearSelectedService: true));
    } else {
      emit(state.copyWith(selectedService: service));
    }
  }

  // ─── Form Management ────────────────────────────────────────────────────────
  void initForm(MedicalServiceModel? service) {
    if (service != null) {
      emit(
        state.copyWith(
          formState: MedicalServiceFormState(
            serviceId: service.id,
            name: service.name ?? '',
            fee: service.consultationFee ?? 200,
            durationMinutes: service.durationMinutes ?? 20,
            assignedDoctorId: service.assignedDoctorId,
            assignedDoctorName: service.assignedDoctorName,
            description: service.description ?? '',
            isActive: service.isActive ?? true,
          ),
        ),
      );
    } else {
      emit(
        state.copyWith(
          formState: const MedicalServiceFormState(),
        ),
      );
    }
  }

  void updateFormDoctor({String? doctorId, String? doctorName}) {
    if (state.formState == null) return;
    if (doctorId == null || doctorId.isEmpty) {
      emit(
        state.copyWith(
          formState: state.formState!.copyWith(clearAssignedDoctor: true),
        ),
      );
    } else {
      emit(
        state.copyWith(
          formState: state.formState!.copyWith(
            assignedDoctorId: doctorId,
            assignedDoctorName: doctorName,
          ),
        ),
      );
    }
  }

  void updateFormIsActive(bool isActive) {
    if (state.formState == null) return;
    emit(
      state.copyWith(
        formState: state.formState!.copyWith(isActive: isActive),
      ),
    );
  }

  void clearForm() {
    emit(state.copyWith(clearFormState: true));
  }

  Future<bool> saveForm({
    required String name,
    required num fee,
    required int durationMinutes,
    String? description,
  }) async {
    final form = state.formState;
    if (form == null) return false;

    if (form.isEdit) {
      final updatedModel = MedicalServiceModel(
        id: form.serviceId,
        name: name,
        consultationFee: fee,
        durationMinutes: durationMinutes,
        assignedDoctorId: form.assignedDoctorId,
        assignedDoctorName: form.assignedDoctorName,
        description: description,
        isActive: form.isActive,
      );
      final success = await updateService(updatedModel);
      if (success) clearForm();
      return success;
    } else {
      final newModel = MedicalServiceModel(
        name: name,
        consultationFee: fee,
        durationMinutes: durationMinutes,
        assignedDoctorId: form.assignedDoctorId,
        assignedDoctorName: form.assignedDoctorName,
        description: description,
        isActive: form.isActive,
      );
      final success = await addService(newModel);
      if (success) clearForm();
      return success;
    }
  }

  Future<bool> addService(MedicalServiceModel service) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final result = await addMedicalServiceUseCase(service);
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (newService) {
        final updatedList = List<MedicalServiceModel>.from(state.services)
          ..insert(0, newService);
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            services: updatedList,
            successMessage: 'service_added_successfully',
          ),
        );
        return true;
      },
    );
  }

  Future<bool> updateService(MedicalServiceModel service) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final result = await updateMedicalServiceUseCase(service);
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (updatedService) {
        final updatedList = state.services.map((s) {
          return s.id == updatedService.id ? updatedService : s;
        }).toList();
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            services: updatedList,
            successMessage: 'service_updated_successfully',
          ),
        );
        return true;
      },
    );
  }

  Future<bool> toggleStatus(String id) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final result = await toggleMedicalServiceStatusUseCase(id);
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (updated) {
        final updatedList = state.services.map((s) {
          return s.id == updated.id ? updated : s;
        }).toList();
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            services: updatedList,
            successMessage: updated.isServiceActive
                ? 'service_activated_successfully'
                : 'service_deactivated_successfully',
          ),
        );
        return true;
      },
    );
  }

  Future<bool> deleteService(String id) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final result = await deleteMedicalServiceUseCase(id);
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (_) {
        final updatedList =
            state.services.where((s) => s.id != id).toList();
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            services: updatedList,
            successMessage: 'service_deleted_successfully',
          ),
        );
        return true;
      },
    );
  }
}
