import 'package:equatable/equatable.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import '../../data/models/enums/technician_gender_enum.dart';
import '../../data/models/enums/technician_status_enum.dart';
import '../../data/models/technician_leave_model.dart';
import '../../data/models/technician_model.dart';

class TechnicianFormState extends Equatable {
  final String? technicianId;
  final String name;
  final String phone;
  final String? image;
  final TechnicianGenderEnum? gender;

  const TechnicianFormState({
    this.technicianId,
    this.name = '',
    this.phone = '',
    this.image,
    this.gender = TechnicianGenderEnum.male,
  });

  TechnicianFormState copyWith({
    String? technicianId,
    String? name,
    String? phone,
    String? image,
    TechnicianGenderEnum? gender,
  }) {
    return TechnicianFormState(
      technicianId: technicianId ?? this.technicianId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      gender: gender ?? this.gender,
    );
  }

  @override
  List<Object?> get props => [technicianId, name, phone, image, gender];
}

class LeaveFormState extends Equatable {
  final String? technicianId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;

  const LeaveFormState({
    this.technicianId,
    required this.startDate,
    required this.endDate,
    this.reason = '',
  });

  LeaveFormState copyWith({
    String? technicianId,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
  }) {
    return LeaveFormState(
      technicianId: technicianId ?? this.technicianId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
    );
  }

  @override
  List<Object?> get props => [technicianId, startDate, endDate, reason];
}

class TechniciansState extends Equatable {
  final RequestStatusEnum status;
  final RequestStatusEnum actionStatus;
  final RequestStatusEnum detailsStatus;
  final List<TechnicianModel> items;
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final TechnicianStatusEnum? selectedStatusFilter;
  final TechnicianModel? selectedTechnician;
  final List<BookingModel> technicianBookings;
  final BookingStatusEnum? selectedBookingStatusFilter;
  final BookingStatusEnum? dialogStatus;
  final Set<String> dialogTechnicianIds;
  final List<TechnicianLeaveModel> technicianLeaves;
  final TechnicianFormState? formState;
  final LeaveFormState? leaveFormState;
  final String? errMessage;
  final String? successMessage;

  const TechniciansState({
    this.status = RequestStatusEnum.initial,
    this.actionStatus = RequestStatusEnum.initial,
    this.detailsStatus = RequestStatusEnum.initial,
    this.items = const [],
    this.totalCount = 0,
    this.totalPages = 1,
    this.currentPage = 1,
    this.selectedStatusFilter,
    this.selectedTechnician,
    this.technicianBookings = const [],
    this.selectedBookingStatusFilter,
    this.dialogStatus,
    this.dialogTechnicianIds = const {},
    this.technicianLeaves = const [],
    this.formState,
    this.leaveFormState,
    this.errMessage,
    this.successMessage,
  });

  List<BookingModel> get filteredTechnicianBookings {
    if (selectedBookingStatusFilter == null) return technicianBookings;
    return technicianBookings
        .where((b) => b.status == selectedBookingStatusFilter)
        .toList();
  }

  TechniciansState copyWith({
    RequestStatusEnum? status,
    RequestStatusEnum? actionStatus,
    RequestStatusEnum? detailsStatus,
    List<TechnicianModel>? items,
    int? totalCount,
    int? totalPages,
    int? currentPage,
    TechnicianStatusEnum? selectedStatusFilter,
    bool clearStatusFilter = false,
    TechnicianModel? selectedTechnician,
    bool clearSelectedTechnician = false,
    List<BookingModel>? technicianBookings,
    BookingStatusEnum? selectedBookingStatusFilter,
    bool clearBookingStatusFilter = false,
    BookingStatusEnum? dialogStatus,
    Set<String>? dialogTechnicianIds,
    List<TechnicianLeaveModel>? technicianLeaves,
    TechnicianFormState? formState,
    bool clearFormState = false,
    LeaveFormState? leaveFormState,
    bool clearLeaveFormState = false,
    String? errMessage,
    bool clearErrMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return TechniciansState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      detailsStatus: detailsStatus ?? this.detailsStatus,
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      selectedStatusFilter: clearStatusFilter
          ? null
          : (selectedStatusFilter ?? this.selectedStatusFilter),
      selectedTechnician: clearSelectedTechnician
          ? null
          : (selectedTechnician ?? this.selectedTechnician),
      technicianBookings: technicianBookings ?? this.technicianBookings,
      selectedBookingStatusFilter: clearBookingStatusFilter
          ? null
          : (selectedBookingStatusFilter ?? this.selectedBookingStatusFilter),
      dialogStatus: dialogStatus ?? this.dialogStatus,
      dialogTechnicianIds: dialogTechnicianIds ?? this.dialogTechnicianIds,
      technicianLeaves: technicianLeaves ?? this.technicianLeaves,
      formState: clearFormState ? null : (formState ?? this.formState),
      leaveFormState:
          clearLeaveFormState ? null : (leaveFormState ?? this.leaveFormState),
      errMessage: clearErrMessage ? null : (errMessage ?? this.errMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        detailsStatus,
        items,
        totalCount,
        totalPages,
        currentPage,
        selectedStatusFilter,
        selectedTechnician,
        technicianBookings,
        selectedBookingStatusFilter,
        dialogStatus,
        dialogTechnicianIds,
        technicianLeaves,
        formState,
        leaveFormState,
        errMessage,
        successMessage,
      ];
}
