import 'package:equatable/equatable.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';

import '../../data/models/doctor_break_time_model.dart';
import '../../data/models/doctor_leave_model.dart';
import '../../data/models/doctor_model.dart';
import '../../data/models/doctor_schedule_model.dart';
import '../../data/models/enums/doctor_gender_enum.dart';
import '../../data/models/enums/doctor_status_enum.dart';
import '../../data/models/enums/week_day_enum.dart';

class DoctorFormState extends Equatable {
  final String? doctorId;
  final String name;
  final String phone;
  final String specialty;
  final String? image;
  final DoctorGenderEnum? gender;

  const DoctorFormState({
    this.doctorId,
    this.name = '',
    this.phone = '',
    this.specialty = '',
    this.image,
    this.gender = DoctorGenderEnum.male,
  });

  DoctorFormState copyWith({
    String? doctorId,
    String? name,
    String? phone,
    String? specialty,
    String? image,
    DoctorGenderEnum? gender,
  }) {
    return DoctorFormState(
      doctorId: doctorId ?? this.doctorId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      specialty: specialty ?? this.specialty,
      image: image ?? this.image,
      gender: gender ?? this.gender,
    );
  }

  @override
  List<Object?> get props => [doctorId, name, phone, specialty, image, gender];
}

class DoctorLeaveFormState extends Equatable {
  final String? doctorId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final int? conflictingBookingsCount;
  final bool requiresConflictConfirmation;
  final String? validationError;

  const DoctorLeaveFormState({
    this.doctorId,
    required this.startDate,
    required this.endDate,
    this.reason = '',
    this.conflictingBookingsCount,
    this.requiresConflictConfirmation = false,
    this.validationError,
  });

  DoctorLeaveFormState copyWith({
    String? doctorId,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    int? conflictingBookingsCount,
    bool clearConflictingCount = false,
    bool? requiresConflictConfirmation,
    String? validationError,
    bool clearValidationError = false,
  }) {
    return DoctorLeaveFormState(
      doctorId: doctorId ?? this.doctorId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      conflictingBookingsCount: clearConflictingCount
          ? null
          : (conflictingBookingsCount ?? this.conflictingBookingsCount),
      requiresConflictConfirmation: requiresConflictConfirmation ??
          this.requiresConflictConfirmation,
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
    );
  }

  @override
  List<Object?> get props => [
        doctorId,
        startDate,
        endDate,
        reason,
        conflictingBookingsCount,
        requiresConflictConfirmation,
        validationError,
      ];
}

class WorkDayFormState extends Equatable {
  final WeekDayEnum dayOfWeek;
  final bool isWorking;
  final String startTime; // "HH:mm"
  final String endTime;   // "HH:mm"
  final List<DoctorBreakTimeModel> breaks;
  final String? errorMessage;

  const WorkDayFormState({
    required this.dayOfWeek,
    this.isWorking = false,
    this.startTime = '09:00',
    this.endTime = '17:00',
    this.breaks = const [],
    this.errorMessage,
  });

  WorkDayFormState copyWith({
    WeekDayEnum? dayOfWeek,
    bool? isWorking,
    String? startTime,
    String? endTime,
    List<DoctorBreakTimeModel>? breaks,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return WorkDayFormState(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isWorking: isWorking ?? this.isWorking,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breaks: breaks ?? this.breaks,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        dayOfWeek,
        isWorking,
        startTime,
        endTime,
        breaks,
        errorMessage,
      ];
}

class DoctorScheduleFormState extends Equatable {
  final String doctorId;
  final int slotDurationMinutes;
  final int bufferDurationMinutes;
  final bool isAcceptingWalkIns;
  final Map<WeekDayEnum, WorkDayFormState> workDays;
  final bool hasUnsavedChanges;
  final String? generalError;

  const DoctorScheduleFormState({
    required this.doctorId,
    this.slotDurationMinutes = 20,
    this.bufferDurationMinutes = 5,
    this.isAcceptingWalkIns = true,
    this.workDays = const {},
    this.hasUnsavedChanges = false,
    this.generalError,
  });

  bool get isValid {
    if (generalError != null) return false;
    if (slotDurationMinutes < 5 || slotDurationMinutes > 120) return false;
    if (bufferDurationMinutes < 0 || bufferDurationMinutes > 60) return false;

    for (final entry in workDays.values) {
      if (entry.isWorking && entry.errorMessage != null) {
        return false;
      }
    }
    return true;
  }

  DoctorScheduleFormState copyWith({
    String? doctorId,
    int? slotDurationMinutes,
    int? bufferDurationMinutes,
    bool? isAcceptingWalkIns,
    Map<WeekDayEnum, WorkDayFormState>? workDays,
    bool? hasUnsavedChanges,
    String? generalError,
    bool clearGeneralError = false,
  }) {
    return DoctorScheduleFormState(
      doctorId: doctorId ?? this.doctorId,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      bufferDurationMinutes:
          bufferDurationMinutes ?? this.bufferDurationMinutes,
      isAcceptingWalkIns: isAcceptingWalkIns ?? this.isAcceptingWalkIns,
      workDays: workDays ?? this.workDays,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      generalError: clearGeneralError
          ? null
          : (generalError ?? this.generalError),
    );
  }

  @override
  List<Object?> get props => [
        doctorId,
        slotDurationMinutes,
        bufferDurationMinutes,
        isAcceptingWalkIns,
        workDays,
        hasUnsavedChanges,
        generalError,
      ];
}

class DoctorsState extends Equatable {
  final RequestStatusEnum status;
  final RequestStatusEnum actionStatus;
  final RequestStatusEnum detailsStatus;
  final RequestStatusEnum scheduleActionStatus;
  final RequestStatusEnum scheduleDetailsStatus;
  final List<DoctorModel> items;
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final DoctorStatusEnum? selectedStatusFilter;
  final DoctorModel? selectedDoctor;
  final List<BookingModel> doctorBookings;
  final BookingStatusEnum? selectedBookingStatusFilter;
  final BookingStatusEnum? dialogStatus;
  final Set<String> dialogDoctorIds;
  final List<DoctorLeaveModel> doctorLeaves;
  final DoctorScheduleModel? selectedDoctorSchedule;
  final Map<String, DoctorScheduleModel?> doctorSchedules;
  final DoctorFormState? formState;
  final DoctorLeaveFormState? leaveFormState;
  final DoctorScheduleFormState? scheduleFormState;
  final String? errMessage;
  final String? successMessage;

  const DoctorsState({
    this.status = RequestStatusEnum.initial,
    this.actionStatus = RequestStatusEnum.initial,
    this.detailsStatus = RequestStatusEnum.initial,
    this.scheduleActionStatus = RequestStatusEnum.initial,
    this.scheduleDetailsStatus = RequestStatusEnum.initial,
    this.items = const [],
    this.totalCount = 0,
    this.totalPages = 1,
    this.currentPage = 1,
    this.selectedStatusFilter,
    this.selectedDoctor,
    this.doctorBookings = const [],
    this.selectedBookingStatusFilter,
    this.dialogStatus,
    this.dialogDoctorIds = const {},
    this.doctorLeaves = const [],
    this.selectedDoctorSchedule,
    this.doctorSchedules = const {},
    this.formState,
    this.leaveFormState,
    this.scheduleFormState,
    this.errMessage,
    this.successMessage,
  });

  List<BookingModel> get filteredDoctorBookings {
    if (selectedBookingStatusFilter == null) return doctorBookings;
    return doctorBookings
        .where((b) => b.status == selectedBookingStatusFilter)
        .toList();
  }

  DoctorsState copyWith({
    RequestStatusEnum? status,
    RequestStatusEnum? actionStatus,
    RequestStatusEnum? detailsStatus,
    RequestStatusEnum? scheduleActionStatus,
    RequestStatusEnum? scheduleDetailsStatus,
    List<DoctorModel>? items,
    int? totalCount,
    int? totalPages,
    int? currentPage,
    DoctorStatusEnum? selectedStatusFilter,
    bool clearStatusFilter = false,
    DoctorModel? selectedDoctor,
    bool clearSelectedDoctor = false,
    List<BookingModel>? doctorBookings,
    BookingStatusEnum? selectedBookingStatusFilter,
    bool clearBookingStatusFilter = false,
    BookingStatusEnum? dialogStatus,
    Set<String>? dialogDoctorIds,
    List<DoctorLeaveModel>? doctorLeaves,
    DoctorScheduleModel? selectedDoctorSchedule,
    bool clearSelectedDoctorSchedule = false,
    Map<String, DoctorScheduleModel?>? doctorSchedules,
    DoctorFormState? formState,
    bool clearFormState = false,
    DoctorLeaveFormState? leaveFormState,
    bool clearLeaveFormState = false,
    DoctorScheduleFormState? scheduleFormState,
    bool clearScheduleFormState = false,
    String? errMessage,
    bool clearErrMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return DoctorsState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      detailsStatus: detailsStatus ?? this.detailsStatus,
      scheduleActionStatus:
          scheduleActionStatus ?? this.scheduleActionStatus,
      scheduleDetailsStatus:
          scheduleDetailsStatus ?? this.scheduleDetailsStatus,
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      selectedStatusFilter: clearStatusFilter
          ? null
          : (selectedStatusFilter ?? this.selectedStatusFilter),
      selectedDoctor: clearSelectedDoctor
          ? null
          : (selectedDoctor ?? this.selectedDoctor),
      doctorBookings: doctorBookings ?? this.doctorBookings,
      selectedBookingStatusFilter: clearBookingStatusFilter
          ? null
          : (selectedBookingStatusFilter ?? this.selectedBookingStatusFilter),
      dialogStatus: dialogStatus ?? this.dialogStatus,
      dialogDoctorIds: dialogDoctorIds ?? this.dialogDoctorIds,
      doctorLeaves: doctorLeaves ?? this.doctorLeaves,
      selectedDoctorSchedule: clearSelectedDoctorSchedule
          ? null
          : (selectedDoctorSchedule ?? this.selectedDoctorSchedule),
      doctorSchedules: doctorSchedules ?? this.doctorSchedules,
      formState: clearFormState ? null : (formState ?? this.formState),
      leaveFormState:
          clearLeaveFormState ? null : (leaveFormState ?? this.leaveFormState),
      scheduleFormState: clearScheduleFormState
          ? null
          : (scheduleFormState ?? this.scheduleFormState),
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
        scheduleActionStatus,
        scheduleDetailsStatus,
        items,
        totalCount,
        totalPages,
        currentPage,
        selectedStatusFilter,
        selectedDoctor,
        doctorBookings,
        selectedBookingStatusFilter,
        dialogStatus,
        dialogDoctorIds,
        doctorLeaves,
        selectedDoctorSchedule,
        doctorSchedules,
        formState,
        leaveFormState,
        scheduleFormState,
        errMessage,
        successMessage,
      ];
}
