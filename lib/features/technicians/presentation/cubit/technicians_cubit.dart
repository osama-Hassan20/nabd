import 'package:eyadty/core/base/safe_cubit.dart';
import 'package:eyadty/core/mixins/search_mixin.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/change_booking_status_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/reassign_technician_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import '../../data/models/enums/technician_gender_enum.dart';
import '../../data/models/enums/technician_status_enum.dart';
import '../../data/models/technician_leave_model.dart';
import '../../data/models/technician_model.dart';
import '../../domain/use_cases/add_technician_leave_use_case.dart';
import '../../domain/use_cases/add_technician_use_case.dart';
import '../../domain/use_cases/delete_technician_leave_use_case.dart';
import '../../domain/use_cases/delete_technician_use_case.dart';
import '../../domain/use_cases/get_technician_by_id_use_case.dart';
import '../../domain/use_cases/get_technician_leaves_use_case.dart';
import '../../domain/use_cases/get_technicians_use_case.dart';
import '../../domain/use_cases/update_technician_use_case.dart';
import 'technicians_state.dart';

class TechniciansCubit extends SafeCubit<TechniciansState> with SearchMixin {
  final GetTechniciansUseCase getTechniciansUseCase;
  final GetTechnicianByIdUseCase getTechnicianByIdUseCase;
  final AddTechnicianUseCase addTechnicianUseCase;
  final UpdateTechnicianUseCase updateTechnicianUseCase;
  final DeleteTechnicianUseCase deleteTechnicianUseCase;
  final GetTechnicianLeavesUseCase getTechnicianLeavesUseCase;
  final AddTechnicianLeaveUseCase addTechnicianLeaveUseCase;
  final DeleteTechnicianLeaveUseCase deleteTechnicianLeaveUseCase;
  final GetBookingsUseCase getBookingsUseCase;
  final ChangeBookingStatusUseCase changeBookingStatusUseCase;
  final ReassignTechnicianUseCase reassignTechnicianUseCase;
  final DeleteBookingUseCase deleteBookingUseCase;

  TechniciansCubit({
    required this.getTechniciansUseCase,
    required this.getTechnicianByIdUseCase,
    required this.addTechnicianUseCase,
    required this.updateTechnicianUseCase,
    required this.deleteTechnicianUseCase,
    required this.getTechnicianLeavesUseCase,
    required this.addTechnicianLeaveUseCase,
    required this.deleteTechnicianLeaveUseCase,
    required this.getBookingsUseCase,
    required this.changeBookingStatusUseCase,
    required this.reassignTechnicianUseCase,
    required this.deleteBookingUseCase,
  }) : super(const TechniciansState());

  PaginationParams paginationParams = PaginationParams(page: 1, limit: 10);

  void init() {
    addSearchListener(() {
      fetchTechnicians(resetPage: true);
    });
    fetchTechnicians();
  }

  @override
  Future<void> close() {
    disposeSearch();
    return super.close();
  }

  // ─── List & Filters ────────────────────────────────────────────────────────
  Future<void> fetchTechnicians({bool resetPage = false}) async {
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

    final result = await getTechniciansUseCase(paginationParams);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ),
      ),
      (response) => emit(
        state.copyWith(
          status: response.items.isEmpty
              ? RequestStatusEnum.empty
              : RequestStatusEnum.success,
          items: response.items,
          totalPages: response.totalPages,
          totalCount: response.totalCount,
          currentPage: response.currentPage,
        ),
      ),
    );
  }

  void setStatusFilter(TechnicianStatusEnum? filter) {
    if (state.selectedStatusFilter == filter) return;
    emit(state.copyWith(
      selectedStatusFilter: filter,
      clearStatusFilter: filter == null,
    ));
    fetchTechnicians(resetPage: true);
  }

  void changePage(int page) {
    if (page < 1 || page > state.totalPages) return;
    paginationParams = paginationParams.copyWith(page: page);
    fetchTechnicians();
  }

  // ─── Details Flow ──────────────────────────────────────────────────────────
  Future<void> fetchTechnicianDetails(String id) async {
    emit(state.copyWith(detailsStatus: RequestStatusEnum.loading));

    final techResult = await getTechnicianByIdUseCase(id);

    await techResult.fold(
      (failure) async {
        emit(
          state.copyWith(
            detailsStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
      },
      (tech) async {
        // Fetch bookings & leaves in parallel
        final bookingsResult = await getBookingsUseCase(
          PaginationParams(
            page: 1,
            limit: 100,
            filterList: [FilterParam(key: 'technician_id', value: id)],
          ),
        );
        final leavesResult = await getTechnicianLeavesUseCase(id);

        List<BookingModel> bookings = [];
        bookingsResult.fold(
          (_) {},
          (resp) {
            bookings = resp.bookings ?? [];
          },
        );

        List<TechnicianLeaveModel> leaves = [];
        leavesResult.fold(
          (_) {},
          (resp) {
            leaves = resp;
          },
        );

        // Derive metrics
        final now = DateTime.now();
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

        TechnicianStatusEnum effectiveStatus = TechnicianStatusEnum.available;
        if (hasActiveLeave) {
          effectiveStatus = TechnicianStatusEnum.onLeave;
        } else if (hasActiveBookingToday) {
          effectiveStatus = TechnicianStatusEnum.busy;
        }

        final updatedTech = tech.copyWith(
          todayTasksCount: todayTasks,
          upcomingBookingsCount: upcoming,
          completedBookingsCount: completed,
          status: effectiveStatus,
        );

        emit(
          state.copyWith(
            detailsStatus: RequestStatusEnum.success,
            selectedTechnician: updatedTech,
            technicianBookings: bookings,
            technicianLeaves: leaves,
          ),
        );
      },
    );
  }

  // ─── Add / Edit Technician Flow ────────────────────────────────────────────
  void initTechnicianForm([TechnicianModel? technician]) {
    emit(
      state.copyWith(
        formState: TechnicianFormState(
          technicianId: technician?.id,
          name: technician?.name ?? '',
          phone: technician?.phone ?? '',
          gender: technician?.gender ?? TechnicianGenderEnum.male,
          image: technician?.image,
        ),
      ),
    );
  }

  Future<bool> saveTechnician({
    required String name,
    required String phone,
    TechnicianGenderEnum? gender,
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
    final isEdit = form?.technicianId != null;

    final model = TechnicianModel(
      id: form?.technicianId,
      name: name,
      phone: phone,
      gender: gender ?? form?.gender ?? TechnicianGenderEnum.male,
      image: image,
    );

    final result = isEdit
        ? await updateTechnicianUseCase(model)
        : await addTechnicianUseCase(model);

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
      (savedTech) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            clearFormState: true,
            successMessage: isEdit
                ? 'technician_updated_successfully'
                : 'technician_added_successfully',
          ),
        );
        fetchTechnicians();
        if (state.selectedTechnician?.id == savedTech.id) {
          emit(state.copyWith(selectedTechnician: savedTech));
        }
        return true;
      },
    );
  }

  Future<bool> deleteTechnician(String id) async {
    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final result = await deleteTechnicianUseCase(id);

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
            successMessage: 'technician_deleted_successfully',
          ),
        );
        fetchTechnicians();
        return true;
      },
    );
  }

  // ─── Leaves Flow ───────────────────────────────────────────────────────────
  void initLeaveForm(String technicianId) {
    final now = DateTime.now();
    emit(
      state.copyWith(
        leaveFormState: LeaveFormState(
          technicianId: technicianId,
          startDate: now,
          endDate: now.add(const Duration(days: 1)),
        ),
      ),
    );
  }

  void updateLeaveFormDates({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (state.leaveFormState == null) return;
    emit(
      state.copyWith(
        leaveFormState: state.leaveFormState!.copyWith(
          startDate: startDate,
          endDate: endDate,
        ),
      ),
    );
  }

  Future<bool> saveLeave({required String reason}) async {
    final form = state.leaveFormState;
    if (form == null || form.technicianId == null) return false;

    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final model = TechnicianLeaveModel(
      technicianId: form.technicianId,
      startDate: form.startDate,
      endDate: form.endDate,
      reason: reason,
    );

    final result = await addTechnicianLeaveUseCase(model);

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
      (newLeave) {
        final currentLeaves = List<TechnicianLeaveModel>.from(
          state.technicianLeaves,
        );
        currentLeaves.insert(0, newLeave);

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            technicianLeaves: currentLeaves,
            clearLeaveFormState: true,
            successMessage: 'leave_added_successfully',
          ),
        );
        if (state.selectedTechnician != null) {
          fetchTechnicianDetails(state.selectedTechnician!.id!);
        }
        fetchTechnicians();
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

    final result = await deleteTechnicianLeaveUseCase(leaveId);

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
        final currentLeaves = List<TechnicianLeaveModel>.from(
          state.technicianLeaves,
        )..removeWhere((l) => l.id == leaveId);

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            technicianLeaves: currentLeaves,
            successMessage: 'leave_deleted_successfully',
          ),
        );
        if (state.selectedTechnician != null) {
          fetchTechnicianDetails(state.selectedTechnician!.id!);
        }
        fetchTechnicians();
        return true;
      },
    );
  }

  // ─── Technician Bookings Management (Parity with Customer Details) ─────────
  void filterTechnicianBookingsByStatus(BookingStatusEnum? status) {
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
        if (state.selectedTechnician?.id != null) {
          fetchTechnicianDetails(state.selectedTechnician!.id!);
        }
        return true;
      },
    );
  }

  void initReassignTechniciansDialog(List<String>? currentIds) {
    emit(state.copyWith(dialogTechnicianIds: currentIds?.toSet() ?? {}));
  }

  void toggleReassignTechnician(String techId) {
    final updated = Set<String>.from(state.dialogTechnicianIds);
    if (updated.contains(techId)) {
      if (updated.length > 1) updated.remove(techId);
    } else {
      updated.add(techId);
    }
    emit(state.copyWith(dialogTechnicianIds: updated));
  }

  Future<bool> reassignTechnicians(
    String bookingId,
    List<String> technicianIds,
    List<String> technicianNames,
  ) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await reassignTechnicianUseCase(
      ReassignTechnicianParams(
        bookingId: bookingId,
        newTechnicianIds: technicianIds,
        newTechnicianNames: technicianNames,
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
        if (state.selectedTechnician?.id != null) {
          fetchTechnicianDetails(state.selectedTechnician!.id!);
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
        if (state.selectedTechnician?.id != null) {
          fetchTechnicianDetails(state.selectedTechnician!.id!);
        }
        return true;
      },
    );
  }
}
