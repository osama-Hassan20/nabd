import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/medical_service_model.dart';

class MedicalServiceFormState extends Equatable {
  final String? serviceId;
  final String name;
  final num fee;
  final int durationMinutes;
  final String? assignedDoctorId;
  final String? assignedDoctorName;
  final String description;
  final bool isActive;

  const MedicalServiceFormState({
    this.serviceId,
    this.name = '',
    this.fee = 200,
    this.durationMinutes = 20,
    this.assignedDoctorId,
    this.assignedDoctorName,
    this.description = '',
    this.isActive = true,
  });

  bool get isEdit => serviceId != null;

  MedicalServiceFormState copyWith({
    String? serviceId,
    String? name,
    num? fee,
    int? durationMinutes,
    String? assignedDoctorId,
    bool clearAssignedDoctor = false,
    String? assignedDoctorName,
    String? description,
    bool? isActive,
  }) {
    return MedicalServiceFormState(
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      fee: fee ?? this.fee,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      assignedDoctorId: clearAssignedDoctor
          ? null
          : (assignedDoctorId ?? this.assignedDoctorId),
      assignedDoctorName: clearAssignedDoctor
          ? null
          : (assignedDoctorName ?? this.assignedDoctorName),
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        serviceId,
        name,
        fee,
        durationMinutes,
        assignedDoctorId,
        assignedDoctorName,
        description,
        isActive,
      ];
}

class MedicalServicesState extends Equatable {
  final RequestStatusEnum status;
  final RequestStatusEnum actionStatus;
  final List<MedicalServiceModel> services;
  final String searchQuery;
  final String statusFilter; // 'all', 'active', 'inactive'
  final String? doctorFilter;
  final MedicalServiceModel? selectedService;
  final MedicalServiceFormState? formState;
  final String? errMessage;
  final String? successMessage;

  const MedicalServicesState({
    this.status = RequestStatusEnum.initial,
    this.actionStatus = RequestStatusEnum.initial,
    this.services = const [],
    this.searchQuery = '',
    this.statusFilter = 'all',
    this.doctorFilter,
    this.selectedService,
    this.formState,
    this.errMessage,
    this.successMessage,
  });

  List<MedicalServiceModel> get filteredServices {
    var result = List<MedicalServiceModel>.from(services);

    if (statusFilter == 'active') {
      result = result.where((s) => s.isServiceActive).toList();
    } else if (statusFilter == 'inactive') {
      result = result.where((s) => !s.isServiceActive).toList();
    }

    if (doctorFilter != null && doctorFilter!.isNotEmpty) {
      result = result.where((s) {
        return s.assignedDoctorId == null ||
            s.assignedDoctorId!.isEmpty ||
            s.assignedDoctorId == doctorFilter;
      }).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      result = result.where((s) {
        final name = (s.name ?? '').toLowerCase();
        final desc = (s.description ?? '').toLowerCase();
        final doc = (s.assignedDoctorName ?? '').toLowerCase();
        return name.contains(q) || desc.contains(q) || doc.contains(q);
      }).toList();
    }

    return result;
  }

  MedicalServicesState copyWith({
    RequestStatusEnum? status,
    RequestStatusEnum? actionStatus,
    List<MedicalServiceModel>? services,
    String? searchQuery,
    String? statusFilter,
    String? doctorFilter,
    bool clearDoctorFilter = false,
    MedicalServiceModel? selectedService,
    bool clearSelectedService = false,
    MedicalServiceFormState? formState,
    bool clearFormState = false,
    String? errMessage,
    String? successMessage,
  }) {
    return MedicalServicesState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      services: services ?? this.services,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      doctorFilter:
          clearDoctorFilter ? null : (doctorFilter ?? this.doctorFilter),
      selectedService: clearSelectedService
          ? null
          : (selectedService ?? this.selectedService),
      formState: clearFormState ? null : (formState ?? this.formState),
      errMessage: errMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        services,
        searchQuery,
        statusFilter,
        doctorFilter,
        selectedService,
        formState,
        errMessage,
        successMessage,
      ];
}
