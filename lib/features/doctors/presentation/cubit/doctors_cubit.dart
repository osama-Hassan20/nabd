import 'package:eyadty/core/base/safe_cubit.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/mixins/search_mixin.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/change_booking_status_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/reassign_technician_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';

import '../../data/models/doctor_break_time_model.dart';
import '../../data/models/doctor_leave_model.dart';
import '../../data/models/doctor_model.dart';
import '../../data/models/doctor_schedule_model.dart';
import '../../data/models/doctor_work_day_model.dart';
import '../../data/models/enums/doctor_gender_enum.dart';
import '../../data/models/enums/doctor_status_enum.dart';
import '../../data/models/enums/week_day_enum.dart';
import '../../domain/helpers/doctor_schedule_validator.dart';
import '../../domain/use_cases/add_doctor_leave_use_case.dart';
import '../../domain/use_cases/add_doctor_use_case.dart';
import '../../domain/use_cases/delete_doctor_leave_use_case.dart';
import '../../domain/use_cases/delete_doctor_use_case.dart';
import '../../domain/use_cases/get_doctor_by_id_use_case.dart';
import '../../domain/use_cases/get_doctor_leaves_use_case.dart';
import '../../domain/use_cases/get_doctor_schedule_use_case.dart';
import '../../domain/use_cases/get_doctors_use_case.dart';
import '../../domain/use_cases/save_doctor_schedule_use_case.dart';
import '../../domain/use_cases/update_doctor_use_case.dart';
import 'doctors_state.dart';

class DoctorsCubit extends SafeCubit<DoctorsState> with SearchMixin {
  final GetDoctorsUseCase getDoctorsUseCase;
  final GetDoctorByIdUseCase getDoctorByIdUseCase;
  final AddDoctorUseCase addDoctorUseCase;
  final UpdateDoctorUseCase updateDoctorUseCase;
  final DeleteDoctorUseCase deleteDoctorUseCase;
  final GetDoctorLeavesUseCase getDoctorLeavesUseCase;
  final AddDoctorLeaveUseCase addDoctorLeaveUseCase;
  final DeleteDoctorLeaveUseCase deleteDoctorLeaveUseCase;
  final GetDoctorScheduleUseCase getDoctorScheduleUseCase;
  final SaveDoctorScheduleUseCase saveDoctorScheduleUseCase;
  final GetBookingsUseCase getBookingsUseCase;
  final ChangeBookingStatusUseCase changeBookingStatusUseCase;
  final ReassignTechnicianUseCase reassignTechnicianUseCase;
  final DeleteBookingUseCase deleteBookingUseCase;

  DoctorsCubit({
    required this.getDoctorsUseCase,
    required this.getDoctorByIdUseCase,
    required this.addDoctorUseCase,
    required this.updateDoctorUseCase,
    required this.deleteDoctorUseCase,
    required this.getDoctorLeavesUseCase,
    required this.addDoctorLeaveUseCase,
    required this.deleteDoctorLeaveUseCase,
    required this.getDoctorScheduleUseCase,
    required this.saveDoctorScheduleUseCase,
    required this.getBookingsUseCase,
    required this.changeBookingStatusUseCase,
    required this.reassignTechnicianUseCase,
    required this.deleteBookingUseCase,
  }) : super(const DoctorsState());

  PaginationParams paginationParams = PaginationParams(page: 1, limit: 10);

  void init() {
    addSearchListener(() {
      fetchDoctors(resetPage: true);
    });
    fetchDoctors();
  }

  @override
  Future<void> close() {
    disposeSearch();
    return super.close();
  }

  // ─── List & Filters ────────────────────────────────────────────────────────
  Future<void> fetchDoctors({bool resetPage = false}) async {
    if (resetPage) {
      paginationParams = paginationParams.copyWith(page: 1);
    }

    final filters = <FilterParam>[
      if (searchQuery.trim().isNotEmpty)
        FilterParam(key: 'search', value: searchQuery.trim()),
      if (state.selectedStatusFilter != null)
        FilterParam(key: 'status', value: state.selectedStatusFilter!.value),
    ];

    paginationParams = paginationParams.copyWith(filterList: filters);

    emit(state.copyWith(status: RequestStatusEnum.loading));

    final result = await getDoctorsUseCase(paginationParams);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ),
      ),
      (response) {
        emit(
          state.copyWith(
            status: (response.items?.isEmpty ?? true)
                ? RequestStatusEnum.empty
                : RequestStatusEnum.success,
            items: response.items ?? [],
            totalCount: response.totalCount ?? 0,
            totalPages: response.totalPages ?? 1,
            currentPage: response.currentPage ?? 1,
          ),
        );
        // Pre-fetch schedules for listed doctors
        if (response.items != null && response.items!.isNotEmpty) {
          fetchAllDoctorSchedules(
            response.items!.map((d) => d.id ?? '').where((id) => id.isNotEmpty).toList(),
          );
        }
      },
    );
  }

  void filterByStatus(DoctorStatusEnum? status) {
    emit(
      state.copyWith(
        selectedStatusFilter: status,
        clearStatusFilter: status == null,
      ),
    );
    fetchDoctors(resetPage: true);
  }

  void setStatusFilter(DoctorStatusEnum? status) => filterByStatus(status);

  void changePage(int page) {
    paginationParams = paginationParams.copyWith(page: page);
    fetchDoctors();
  }

  // ─── Details Flow ──────────────────────────────────────────────────────────
  Future<void> fetchDoctorDetails(String id) async {
    emit(state.copyWith(detailsStatus: RequestStatusEnum.loading));

    final docResult = await getDoctorByIdUseCase(id);

    await docResult.fold(
      (failure) async {
        emit(
          state.copyWith(
            detailsStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
      },
      (doc) async {
        // Parallel data fetch: bookings, leaves, schedule
        final bookingsFuture = getBookingsUseCase(
          PaginationParams(
            page: 1,
            limit: 100,
            filterList: [FilterParam(key: 'technicianId', value: id)],
          ),
        );
        final leavesFuture = getDoctorLeavesUseCase(id);
        final scheduleFuture = getDoctorScheduleUseCase(id);

        final results = await Future.wait([
          bookingsFuture,
          leavesFuture,
          scheduleFuture,
        ]);

        List<BookingModel> bookings = [];
        (results[0] as dynamic).fold(
          (_) {},
          (resp) {
            bookings = resp.bookings ?? [];
          },
        );

        List<DoctorLeaveModel> leaves = [];
        (results[1] as dynamic).fold(
          (_) {},
          (resp) {
            leaves = resp;
          },
        );

        DoctorScheduleModel? schedule;
        (results[2] as dynamic).fold(
          (_) {},
          (resp) {
            schedule = resp;
          },
        );

        // Derive metrics
        final now = CairoTimeHelper.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

        final todayTasks = bookings.where((b) {
          final bDate = b.date;
          if (bDate == null) return false;
          return bDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
              bDate.isBefore(todayEnd.add(const Duration(seconds: 1)));
        }).length;

        final upcoming = bookings.where((b) {
          final bDate = b.date;
          return bDate != null && bDate.isAfter(todayEnd);
        }).length;

        final completed = bookings
            .where((b) => b.status == BookingStatusEnum.completed)
            .length;

        // Dynamic status check
        final hasActiveLeave = leaves.any((l) => l.isCurrentlyActive(now));
        final hasActiveBookingToday = todayTasks > 0;

        DoctorStatusEnum effectiveStatus = DoctorStatusEnum.available;
        if (hasActiveLeave) {
          effectiveStatus = DoctorStatusEnum.onLeave;
        } else if (hasActiveBookingToday) {
          effectiveStatus = DoctorStatusEnum.busy;
        }

        final updatedDoc = doc.copyWith(
          todayTasksCount: todayTasks,
          upcomingBookingsCount: upcoming,
          completedBookingsCount: completed,
          status: effectiveStatus,
        );

        final currentMap = Map<String, DoctorScheduleModel?>.from(
          state.doctorSchedules,
        );
        currentMap[id] = schedule;

        emit(
          state.copyWith(
            detailsStatus: RequestStatusEnum.success,
            selectedDoctor: updatedDoc,
            doctorBookings: bookings,
            doctorLeaves: leaves,
            selectedDoctorSchedule: schedule,
            doctorSchedules: currentMap,
          ),
        );
      },
    );
  }

  // ─── Add / Edit Doctor Flow ───────────────────────────────────────────────
  void initDoctorForm([DoctorModel? doctor]) {
    emit(
      state.copyWith(
        formState: DoctorFormState(
          doctorId: doctor?.id,
          name: doctor?.name ?? '',
          phone: doctor?.phone ?? '',
          specialty: doctor?.specialty ?? '',
          gender: doctor?.gender ?? DoctorGenderEnum.male,
          image: doctor?.image,
        ),
      ),
    );
  }

  Future<bool> saveDoctor({
    required String name,
    required String phone,
    String? specialty,
    DoctorGenderEnum? gender,
    String? image,
  }) async {
    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final form = state.formState;
    final isEdit = form?.doctorId != null;

    final model = DoctorModel(
      id: form?.doctorId,
      name: name,
      phone: phone,
      specialty: specialty ?? form?.specialty,
      gender: gender ?? form?.gender ?? DoctorGenderEnum.male,
      image: image,
    );

    final result = isEdit
        ? await updateDoctorUseCase(model)
        : await addDoctorUseCase(model);

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
      (savedDoc) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            clearFormState: true,
            successMessage: isEdit
                ? 'doctor_updated_successfully'
                : 'doctor_added_successfully',
          ),
        );
        fetchDoctors();
        if (state.selectedDoctor?.id == savedDoc.id) {
          emit(state.copyWith(selectedDoctor: savedDoc));
        }
        return true;
      },
    );
  }

  Future<bool> deleteDoctor(String id) async {
    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final result = await deleteDoctorUseCase(id);

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
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            successMessage: 'doctor_deleted_successfully',
          ),
        );
        fetchDoctors();
        return true;
      },
    );
  }

  // ─── Schedule Flow ─────────────────────────────────────────────────────────
  Future<void> fetchDoctorSchedule(String doctorId) async {
    emit(state.copyWith(scheduleDetailsStatus: RequestStatusEnum.loading));
    final res = await getDoctorScheduleUseCase(doctorId);
    res.fold(
      (failure) => emit(
        state.copyWith(
          scheduleDetailsStatus: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ),
      ),
      (schedule) {
        final currentMap = Map<String, DoctorScheduleModel?>.from(
          state.doctorSchedules,
        );
        currentMap[doctorId] = schedule;
        emit(
          state.copyWith(
            scheduleDetailsStatus: RequestStatusEnum.success,
            selectedDoctorSchedule: schedule,
            doctorSchedules: currentMap,
          ),
        );
      },
    );
  }

  Future<void> fetchAllDoctorSchedules(List<String> doctorIds) async {
    final currentMap = Map<String, DoctorScheduleModel?>.from(
      state.doctorSchedules,
    );
    for (final docId in doctorIds) {
      final res = await getDoctorScheduleUseCase(docId);
      res.fold((_) {}, (schedule) {
        currentMap[docId] = schedule;
      });
    }
    emit(state.copyWith(doctorSchedules: currentMap));
  }

  Future<void> initScheduleForm(String doctorId) async {
    DoctorScheduleModel? existing = state.doctorSchedules[doctorId];
    if (existing == null) {
      final res = await getDoctorScheduleUseCase(doctorId);
      existing = res.fold((_) => null, (s) => s);
    }

    final workDaysMap = <WeekDayEnum, WorkDayFormState>{};
    for (final day in WeekDayEnum.values) {
      final existingDay = existing?.workDays?.firstWhere(
        (w) => w.dayOfWeek == day,
        orElse: () => DoctorWorkDayModel(dayOfWeek: day),
      );

      final isWorking = existingDay?.isWorking ?? false;
      final startTime = existingDay?.startTime ?? '09:00';
      final endTime = existingDay?.endTime ?? '17:00';
      final breaks = existingDay?.breaks ?? const [];

      final dummyDay = DoctorWorkDayModel(
        dayOfWeek: day,
        isWorking: isWorking,
        startTime: startTime,
        endTime: endTime,
        breaks: breaks,
      );
      final errMsg = DoctorScheduleValidator.validateWorkDay(dummyDay);

      workDaysMap[day] = WorkDayFormState(
        dayOfWeek: day,
        isWorking: isWorking,
        startTime: startTime,
        endTime: endTime,
        breaks: breaks,
        errorMessage: errMsg,
      );
    }

    emit(
      state.copyWith(
        scheduleFormState: DoctorScheduleFormState(
          doctorId: doctorId,
          slotDurationMinutes: existing?.slotDurationMinutes ?? 20,
          bufferDurationMinutes: existing?.bufferDurationMinutes ?? 5,
          isAcceptingWalkIns: existing?.isAcceptingWalkIns ?? true,
          workDays: workDaysMap,
          hasUnsavedChanges: false,
        ),
      ),
    );
  }

  void updateScheduleSlotDuration(int minutes) {
    if (state.scheduleFormState == null) return;
    emit(
      state.copyWith(
        scheduleFormState: state.scheduleFormState!.copyWith(
          slotDurationMinutes: minutes,
          hasUnsavedChanges: true,
        ),
      ),
    );
  }

  void updateScheduleBufferDuration(int minutes) {
    if (state.scheduleFormState == null) return;
    emit(
      state.copyWith(
        scheduleFormState: state.scheduleFormState!.copyWith(
          bufferDurationMinutes: minutes,
          hasUnsavedChanges: true,
        ),
      ),
    );
  }

  void updateScheduleWalkIns(bool allow) {
    if (state.scheduleFormState == null) return;
    emit(
      state.copyWith(
        scheduleFormState: state.scheduleFormState!.copyWith(
          isAcceptingWalkIns: allow,
          hasUnsavedChanges: true,
        ),
      ),
    );
  }

  void toggleDayWorking(WeekDayEnum day, bool isWorking) {
    final form = state.scheduleFormState;
    if (form == null) return;
    final currentDays = Map<WeekDayEnum, WorkDayFormState>.from(form.workDays);
    final dayState = currentDays[day] ?? WorkDayFormState(dayOfWeek: day);

    final updatedDay = dayState.copyWith(
      isWorking: isWorking,
      clearErrorMessage: !isWorking,
    );

    String? errMsg;
    if (isWorking) {
      errMsg = DoctorScheduleValidator.validateWorkDay(
        DoctorWorkDayModel(
          dayOfWeek: day,
          isWorking: true,
          startTime: updatedDay.startTime,
          endTime: updatedDay.endTime,
          breaks: updatedDay.breaks,
        ),
      );
    }

    currentDays[day] = updatedDay.copyWith(
      errorMessage: errMsg,
      clearErrorMessage: errMsg == null,
    );

    emit(
      state.copyWith(
        scheduleFormState: form.copyWith(
          workDays: currentDays,
          hasUnsavedChanges: true,
        ),
      ),
    );
  }

  void updateDayHours(WeekDayEnum day, String startTime, String endTime) {
    final form = state.scheduleFormState;
    if (form == null) return;
    final currentDays = Map<WeekDayEnum, WorkDayFormState>.from(form.workDays);
    final dayState = currentDays[day] ?? WorkDayFormState(dayOfWeek: day);

    final dummyDay = DoctorWorkDayModel(
      dayOfWeek: day,
      isWorking: dayState.isWorking,
      startTime: startTime,
      endTime: endTime,
      breaks: dayState.breaks,
    );
    final errMsg = DoctorScheduleValidator.validateWorkDay(dummyDay);

    currentDays[day] = dayState.copyWith(
      startTime: startTime,
      endTime: endTime,
      errorMessage: errMsg,
      clearErrorMessage: errMsg == null,
    );

    emit(
      state.copyWith(
        scheduleFormState: form.copyWith(
          workDays: currentDays,
          hasUnsavedChanges: true,
        ),
      ),
    );
  }

  void addDayBreak(WeekDayEnum day, DoctorBreakTimeModel breakTime) {
    final form = state.scheduleFormState;
    if (form == null) return;
    final currentDays = Map<WeekDayEnum, WorkDayFormState>.from(form.workDays);
    final dayState = currentDays[day] ?? WorkDayFormState(dayOfWeek: day);

    final updatedBreaks = List<DoctorBreakTimeModel>.from(dayState.breaks)
      ..add(breakTime);

    final dummyDay = DoctorWorkDayModel(
      dayOfWeek: day,
      isWorking: dayState.isWorking,
      startTime: dayState.startTime,
      endTime: dayState.endTime,
      breaks: updatedBreaks,
    );
    final errMsg = DoctorScheduleValidator.validateWorkDay(dummyDay);

    currentDays[day] = dayState.copyWith(
      breaks: updatedBreaks,
      errorMessage: errMsg,
      clearErrorMessage: errMsg == null,
    );

    emit(
      state.copyWith(
        scheduleFormState: form.copyWith(
          workDays: currentDays,
          hasUnsavedChanges: true,
        ),
      ),
    );
  }

  void removeDayBreak(WeekDayEnum day, int breakIndex) {
    final form = state.scheduleFormState;
    if (form == null) return;
    final currentDays = Map<WeekDayEnum, WorkDayFormState>.from(form.workDays);
    final dayState = currentDays[day] ?? WorkDayFormState(dayOfWeek: day);

    if (breakIndex < 0 || breakIndex >= dayState.breaks.length) return;
    final updatedBreaks = List<DoctorBreakTimeModel>.from(dayState.breaks)
      ..removeAt(breakIndex);

    final dummyDay = DoctorWorkDayModel(
      dayOfWeek: day,
      isWorking: dayState.isWorking,
      startTime: dayState.startTime,
      endTime: dayState.endTime,
      breaks: updatedBreaks,
    );
    final errMsg = DoctorScheduleValidator.validateWorkDay(dummyDay);

    currentDays[day] = dayState.copyWith(
      breaks: updatedBreaks,
      errorMessage: errMsg,
      clearErrorMessage: errMsg == null,
    );

    emit(
      state.copyWith(
        scheduleFormState: form.copyWith(
          workDays: currentDays,
          hasUnsavedChanges: true,
        ),
      ),
    );
  }

  void copyDayToOtherWorkDays(WeekDayEnum sourceDay) {
    final form = state.scheduleFormState;
    if (form == null) return;
    final source = form.workDays[sourceDay];
    if (source == null) return;

    final currentDays = Map<WeekDayEnum, WorkDayFormState>.from(form.workDays);

    for (final day in WeekDayEnum.values) {
      if (day == sourceDay) continue;
      final existing = currentDays[day];
      if (existing == null || !existing.isWorking) continue;

      final dummyDay = DoctorWorkDayModel(
        dayOfWeek: day,
        isWorking: true,
        startTime: source.startTime,
        endTime: source.endTime,
        breaks: source.breaks,
      );
      final errMsg = DoctorScheduleValidator.validateWorkDay(dummyDay);

      currentDays[day] = existing.copyWith(
        startTime: source.startTime,
        endTime: source.endTime,
        breaks: List<DoctorBreakTimeModel>.from(source.breaks),
        errorMessage: errMsg,
        clearErrorMessage: errMsg == null,
      );
    }

    emit(
      state.copyWith(
        scheduleFormState: form.copyWith(
          workDays: currentDays,
          hasUnsavedChanges: true,
        ),
      ),
    );
  }

  Future<bool> saveSchedule() async {
    final form = state.scheduleFormState;
    if (form == null || !form.isValid) return false;

    emit(
      state.copyWith(
        scheduleActionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final workDaysList = form.workDays.values.map((w) {
      return DoctorWorkDayModel(
        dayOfWeek: w.dayOfWeek,
        isWorking: w.isWorking,
        startTime: w.isWorking ? w.startTime : null,
        endTime: w.isWorking ? w.endTime : null,
        breaks: w.isWorking ? w.breaks : null,
      );
    }).toList();

    final model = DoctorScheduleModel(
      id: 'SCHED-${form.doctorId}',
      doctorId: form.doctorId,
      slotDurationMinutes: form.slotDurationMinutes,
      bufferDurationMinutes: form.bufferDurationMinutes,
      isAcceptingWalkIns: form.isAcceptingWalkIns,
      workDays: workDaysList,
    );

    final result = await saveDoctorScheduleUseCase(model);

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            scheduleActionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (savedSchedule) {
        final currentMap = Map<String, DoctorScheduleModel?>.from(
          state.doctorSchedules,
        );
        currentMap[form.doctorId] = savedSchedule;

        emit(
          state.copyWith(
            scheduleActionStatus: RequestStatusEnum.success,
            selectedDoctorSchedule: savedSchedule,
            doctorSchedules: currentMap,
            clearScheduleFormState: true,
            successMessage: 'schedule_saved_successfully',
          ),
        );

        if (state.selectedDoctor?.id == form.doctorId) {
          fetchDoctorDetails(form.doctorId);
        }
        return true;
      },
    );
  }

  // ─── Leaves Flow ───────────────────────────────────────────────────────────
  void initLeaveForm(String doctorId) {
    final now = CairoTimeHelper.now();
    emit(
      state.copyWith(
        leaveFormState: DoctorLeaveFormState(
          doctorId: doctorId,
          startDate: now,
          endDate: now.add(const Duration(days: 1)),
        ),
      ),
    );
  }

  void updateLeaveStartDate(DateTime date) {
    if (state.leaveFormState == null) return;
    final currentEnd = state.leaveFormState!.endDate;
    final newEnd = currentEnd.isBefore(date) ? date : currentEnd;

    emit(
      state.copyWith(
        leaveFormState: state.leaveFormState!.copyWith(
          startDate: date,
          endDate: newEnd,
          clearValidationError: true,
          clearConflictingCount: true,
          requiresConflictConfirmation: false,
        ),
      ),
    );
  }

  void updateLeaveEndDate(DateTime date) {
    if (state.leaveFormState == null) return;
    emit(
      state.copyWith(
        leaveFormState: state.leaveFormState!.copyWith(
          endDate: date,
          clearValidationError: true,
          clearConflictingCount: true,
          requiresConflictConfirmation: false,
        ),
      ),
    );
  }

  void updateLeaveReason(String reason) {
    if (state.leaveFormState == null) return;
    emit(
      state.copyWith(
        leaveFormState: state.leaveFormState!.copyWith(reason: reason),
      ),
    );
  }

  void clearLeaveConflict() {
    if (state.leaveFormState == null) return;
    emit(
      state.copyWith(
        leaveFormState: state.leaveFormState!.copyWith(
          clearConflictingCount: true,
          requiresConflictConfirmation: false,
        ),
      ),
    );
  }

  Future<bool> saveLeave({bool force = false}) async {
    final form = state.leaveFormState;
    if (form == null || form.doctorId == null) return false;

    final model = DoctorLeaveModel(
      doctorId: form.doctorId,
      startDate: form.startDate,
      endDate: form.endDate,
      reason: form.reason,
    );

    final validationErr = DoctorScheduleValidator.validateLeave(
      leave: model,
      existingLeaves: state.doctorLeaves,
    );
    if (validationErr != null) {
      emit(
        state.copyWith(
          leaveFormState: form.copyWith(validationError: validationErr),
          errMessage: validationErr,
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final result = await addDoctorLeaveUseCase(model, force: force);

    return result.fold(
      (failure) {
        if (failure is ConflictingBookingsFailure) {
          emit(
            state.copyWith(
              actionStatus: RequestStatusEnum.initial,
              leaveFormState: form.copyWith(
                conflictingBookingsCount: failure.conflictingCount,
                requiresConflictConfirmation: true,
              ),
            ),
          );
          return false;
        }

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (newLeave) {
        final currentLeaves = List<DoctorLeaveModel>.from(
          state.doctorLeaves,
        );
        currentLeaves.insert(0, newLeave);

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            doctorLeaves: currentLeaves,
            clearLeaveFormState: true,
            successMessage: 'leave_added_successfully',
          ),
        );
        if (state.selectedDoctor != null) {
          fetchDoctorDetails(state.selectedDoctor!.id!);
        }
        fetchDoctors();
        return true;
      },
    );
  }

  Future<bool> deleteLeave(String leaveId) async {
    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final result = await deleteDoctorLeaveUseCase(leaveId);

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
        final currentLeaves = List<DoctorLeaveModel>.from(
          state.doctorLeaves,
        )..removeWhere((l) => l.id == leaveId);

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            doctorLeaves: currentLeaves,
            successMessage: 'leave_deleted_successfully',
          ),
        );
        if (state.selectedDoctor != null) {
          fetchDoctorDetails(state.selectedDoctor!.id!);
        }
        fetchDoctors();
        return true;
      },
    );
  }

  // ─── Doctor Bookings Management ──────────────────────────────────────────
  void filterDoctorBookingsByStatus(BookingStatusEnum? status) {
    emit(
      state.copyWith(
        selectedBookingStatusFilter: status,
        clearBookingStatusFilter: status == null,
      ),
    );
  }

  void initChangeStatusDialog(BookingStatusEnum currentStatus) {
    emit(state.copyWith(dialogStatus: currentStatus));
  }

  void selectStatusToChange(BookingStatusEnum newStatus) {
    emit(state.copyWith(dialogStatus: newStatus));
  }

  Future<bool> changeBookingStatus(
    String bookingId,
    BookingStatusEnum newStatus,
  ) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await changeBookingStatusUseCase(
      ChangeBookingStatusParams(
        bookingId: bookingId,
        newStatus: newStatus,
      ),
    );

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
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        if (state.selectedDoctor?.id != null) {
          fetchDoctorDetails(state.selectedDoctor!.id!);
        }
        return true;
      },
    );
  }

  Future<bool> reassignDoctor(String bookingId, String newDoctorId) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await reassignTechnicianUseCase(
      ReassignTechnicianParams(
        bookingId: bookingId,
        newTechnicianId: newDoctorId,
      ),
    );

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
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        if (state.selectedDoctor?.id != null) {
          fetchDoctorDetails(state.selectedDoctor!.id!);
        }
        return true;
      },
    );
  }

  Future<bool> deleteBooking(String bookingId) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await deleteBookingUseCase(bookingId);

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
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        if (state.selectedDoctor?.id != null) {
          fetchDoctorDetails(state.selectedDoctor!.id!);
        }
        return true;
      },
    );
  }

  void initReassignDoctorsDialog(List<String>? initialIds) {
    emit(state.copyWith(dialogDoctorIds: (initialIds ?? []).toSet()));
  }

  void toggleReassignDoctor(String doctorId) {
    final current = Set<String>.from(state.dialogDoctorIds);
    if (current.contains(doctorId)) {
      current.remove(doctorId);
    } else {
      current.add(doctorId);
    }
    emit(state.copyWith(dialogDoctorIds: current));
  }

  Future<bool> reassignDoctors(
    String bookingId,
    List<String> doctorIds,
    List<String> doctorNames,
  ) async {
    final primaryId = doctorIds.isNotEmpty ? doctorIds.first : '';
    return reassignDoctor(bookingId, primaryId);
  }
}
