import 'dart:async';
import 'package:eyadty/core/base/safe_cubit.dart';
import 'package:eyadty/core/mixins/search_mixin.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_form_options_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/create_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_by_id_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_summary_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/change_booking_status_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/reassign_technician_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/update_booking_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/get_patients_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctors_use_case.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/features/bookings/data/models/enums/slot_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/time_slot_model.dart';
import 'package:eyadty/features/bookings/domain/helpers/slot_generator_helper.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_doctor_bookings_for_date_use_case.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_leaves_use_case.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_schedule_use_case.dart';
import 'package:eyadty/features/settings/data/models/special_holiday_model.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_company_settings_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_medical_services_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/params/get_medical_services_params.dart';
import 'package:eyadty/shared/services/app_branch_service.dart';

import 'bookings_state.dart';

typedef GetTechniciansUseCase = GetDoctorsUseCase;

class BookingsCubit extends SafeCubit<BookingsState> with SearchMixin {
  final GetBookingSummaryUseCase getBookingSummaryUseCase;
  final GetBookingsUseCase getBookingsUseCase;
  final GetBookingByIdUseCase getBookingByIdUseCase;
  final CreateBookingUseCase createBookingUseCase;
  final UpdateBookingUseCase updateBookingUseCase;
  final ChangeBookingStatusUseCase changeBookingStatusUseCase;
  final ReassignTechnicianUseCase reassignTechnicianUseCase;
  final DeleteBookingUseCase deleteBookingUseCase;
  final GetDoctorsUseCase? getDoctorsUseCase;
  final GetPatientsUseCase? getPatientsUseCase;
  final GetMedicalServicesUseCase? getMedicalServicesUseCase;
  final GetDoctorScheduleUseCase? getDoctorScheduleUseCase;
  final GetDoctorLeavesUseCase? getDoctorLeavesUseCase;
  final GetCompanySettingsUseCase? getCompanySettingsUseCase;
  final GetDoctorBookingsForDateUseCase? getDoctorBookingsForDateUseCase;

  Timer? _noShowTimer;

  BookingsCubit({
    required this.getBookingSummaryUseCase,
    required this.getBookingsUseCase,
    required this.getBookingByIdUseCase,
    required this.createBookingUseCase,
    required this.updateBookingUseCase,
    required this.changeBookingStatusUseCase,
    required this.reassignTechnicianUseCase,
    required this.deleteBookingUseCase,
    GetDoctorsUseCase? getDoctorsUseCase,
    GetDoctorsUseCase? getTechniciansUseCase,
    GetPatientsUseCase? getPatientsUseCase,
    GetPatientsUseCase? getCustomersUseCase,
    this.getMedicalServicesUseCase,
    this.getDoctorScheduleUseCase,
    this.getDoctorLeavesUseCase,
    this.getCompanySettingsUseCase,
    this.getDoctorBookingsForDateUseCase,
  })  : getDoctorsUseCase = getDoctorsUseCase ?? getTechniciansUseCase,
        getPatientsUseCase = getPatientsUseCase ?? getCustomersUseCase,
        super(const BookingsState()) {
    _initBranchListener();
    _startPeriodicNoShowTimer();
    _initFormOptions();
    fetchTechnicians();
    fetchCustomers();
    fetchMedicalServices();
  }

  String? _currentBookingId;

  void _initBranchListener() {
    emit(state.copyWith(
      selectedBranchId: AppBranchService.instance.currentBranchId,
    ));
    AppBranchService.instance.selectedBranchNotifier
        .addListener(_onGlobalBranchChanged);
  }

  void _onGlobalBranchChanged() {
    final newBranch = AppBranchService.instance.currentBranchId;
    if (state.selectedBranchId != newBranch) {
      emit(state.copyWith(selectedBranchId: newBranch, currentPage: 1));
      fetchBookingSummary();
      fetchBookings(resetPage: true);
    }
  }

  void _startPeriodicNoShowTimer() {
    _noShowTimer?.cancel();
    _noShowTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isClosed) return;
      final isViewingToday = state.selectedDate == null ||
          CairoTimeHelper.isToday(state.selectedDate);
      if (isViewingToday) {
        fetchBookingSummary();
        fetchBookings(resetPage: false);
      }
    });
  }

  void init() {
    _initFormOptions();
    addSearchListener(() {
      emit(state.copyWith(searchQuery: searchQuery));
      fetchBookings(resetPage: true);
    });
    fetchBookingSummary();
    fetchBookings(resetPage: true);
  }

  void _initFormOptions() {
    emit(
      state.copyWith(
        customers: state.customers.isNotEmpty
            ? state.customers
            : BookingsState.initialCustomers,
        technicians: state.technicians.isNotEmpty
            ? state.technicians
            : BookingsState.initialTechnicians,
      ),
    );
  }

  Future<void> fetchTechnicians() async {
    if (getDoctorsUseCase == null) return;
    final result = await getDoctorsUseCase!(
      const PaginationParams(page: 1, limit: 100),
    );
    result.fold(
      (_) {},
      (response) {
        final items = response.items ?? [];
        if (items.isNotEmpty) {
          final options = items
              .map(
                (t) => BookingTechnicianOption(
                  id: t.id ?? '',
                  name: t.name ?? '',
                ),
              )
              .where((t) => t.id.isNotEmpty && t.name.isNotEmpty)
              .toList();
          if (options.isNotEmpty) {
            emit(state.copyWith(technicians: options));
          }
        }
      },
    );
  }

  Future<void> fetchCustomers() async {
    if (getPatientsUseCase == null) return;
    final result = await getPatientsUseCase!(
      const PaginationParams(page: 1, limit: 100),
    );
    result.fold(
      (_) {},
      (response) {
        final items = response.items ?? [];
        if (items.isNotEmpty) {
          final options = items
              .map(
                (c) => BookingPatientOption(
                  id: c.id ?? '',
                  name: c.name ?? '',
                  phone: c.phone ?? '',
                  address: c.address ?? '',
                ),
              )
              .where((c) => c.id.isNotEmpty && c.name.isNotEmpty)
              .toList();
          if (options.isNotEmpty) {
            emit(state.copyWith(customers: options));
          }
        }
      },
    );
  }

  void addCustomerOption(BookingCustomerOption customer) {
    final updated = [customer, ...state.customers];
    emit(state.copyWith(customers: updated));
  }

  Future<void> fetchBookingSummary() async {
    emit(state.copyWith(summaryStatus: RequestStatusEnum.loading));
    final result = await getBookingSummaryUseCase(
      GetBookingSummaryParams(
        date: state.selectedDate ?? CairoTimeHelper.now(),
        branchId: state.selectedBranchId,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          summaryStatus: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ),
      ),
      (summary) => emit(
        state.copyWith(
          summaryStatus: RequestStatusEnum.success,
          summary: summary,
        ),
      ),
    );
  }

  Future<void> fetchBookings({bool resetPage = false}) async {
    final page = resetPage ? 1 : state.currentPage;
    emit(
      state.copyWith(
        bookingsStatus: RequestStatusEnum.loading,
        currentPage: page,
      ),
    );

    final List<FilterParam> filters = [];
    if (state.searchQuery.isNotEmpty) {
      filters.add(FilterParam(key: 'search', value: state.searchQuery));
    }
    // Filter by branch
    filters.add(
      FilterParam(key: 'branchId', value: state.selectedBranchId),
    );
    // Filter by active tab (one_time or recurring)
    filters.add(
      FilterParam(key: 'bookingType', value: state.activeBookingTypeTab.value),
    );

    if (state.selectedStatus != null) {
      filters.add(
        FilterParam(key: 'status', value: state.selectedStatus!.value),
      );
    }

    if (state.activeBookingTypeTab == BookingTypeEnum.oneTime) {
      final effectiveDate = state.selectedDate ?? CairoTimeHelper.now();
      if (state.selectedDate != null || !state.isMonthFilterActive) {
        final d = effectiveDate;
        final dateStr =
            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        filters.add(FilterParam(key: 'date', value: dateStr));
      } else if (state.isMonthFilterActive && state.selectedMonth != null) {
        final m = state.selectedMonth!;
        final monthStr = "${m.year}-${m.month.toString().padLeft(2, '0')}";
        filters.add(FilterParam(key: 'date', value: monthStr));
      }
    } else {
      if (state.selectedDayOfWeek != null &&
          state.selectedDayOfWeek!.isNotEmpty) {
        filters.add(
          FilterParam(key: 'dayOfWeek', value: state.selectedDayOfWeek!),
        );
      }
    }

    final params = PaginationParams(page: page, limit: 8, filterList: filters);

    final result = await getBookingsUseCase(params);
    result.fold(
      (failure) => emit(
        state.copyWith(
          bookingsStatus: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ),
      ),
      (response) {
        final bookings = response.bookings ?? [];
        emit(
          state.copyWith(
            bookingsStatus: bookings.isEmpty
                ? RequestStatusEnum.empty
                : RequestStatusEnum.success,
            bookings: bookings,
            pagination: response.pagination,
          ),
        );
      },
    );
  }

  void onPageChanged(int newPage) {
    if (newPage == state.currentPage) return;
    emit(state.copyWith(currentPage: newPage));
    fetchBookings(resetPage: false);
  }

  void switchBookingTypeTab(BookingTypeEnum tab) {
    if (state.activeBookingTypeTab == tab) return;
    emit(
      state.copyWith(
        activeBookingTypeTab: tab,
        clearSelectedDate: true,
        clearSelectedDayOfWeek: true,
        isMonthFilterActive: false,
        currentPage: 1,
      ),
    );
    fetchBookings(resetPage: true);
  }

  void onDayOfWeekFilterChanged(String? day) {
    emit(
      state.copyWith(
        selectedDayOfWeek: day,
        clearSelectedDayOfWeek: day == null,
      ),
    );
    fetchBookings(resetPage: true);
  }

  void onStatusFilterChanged(BookingStatusEnum? status) {
    emit(
      state.copyWith(
        selectedStatus: status,
        clearSelectedStatus: status == null,
      ),
    );
    fetchBookings(resetPage: true);
  }

  void toggleStatusFilterFromCard(BookingStatusEnum? status) {
    if (status == null) {
      emit(state.copyWith(clearSelectedStatus: true));
    } else if (state.selectedStatus == status) {
      emit(state.copyWith(clearSelectedStatus: true));
    } else {
      emit(state.copyWith(selectedStatus: status));
    }
    fetchBookings(resetPage: true);
  }

  void onMonthSelected(DateTime? month, {bool filterByWholeMonth = false}) {
    if (month == null) {
      emit(
        state.copyWith(
          clearSelectedMonth: true,
          clearSelectedDate: true,
          isMonthFilterActive: false,
        ),
      );
    } else {
      final firstDay = DateTime(month.year, month.month, 1);
      emit(
        state.copyWith(
          selectedMonth: firstDay,
          selectedDate: filterByWholeMonth ? null : firstDay,
          clearSelectedDate: filterByWholeMonth,
          isMonthFilterActive: filterByWholeMonth,
        ),
      );
    }
    fetchBookingSummary();
    fetchBookings(resetPage: true);
  }

  void nextCalendarMonth() {
    final current = state.selectedMonth ?? state.selectedDate ?? CairoTimeHelper.now();
    final nextMonth = DateTime(current.year, current.month + 1, 1);
    final firstDay = DateTime(nextMonth.year, nextMonth.month, 1);
    emit(
      state.copyWith(
        selectedMonth: nextMonth,
        selectedDate: firstDay,
        isMonthFilterActive: false,
      ),
    );
    fetchBookingSummary();
    fetchBookings(resetPage: true);
  }

  void previousCalendarMonth() {
    final current = state.selectedMonth ?? state.selectedDate ?? CairoTimeHelper.now();
    final prevMonth = DateTime(current.year, current.month - 1, 1);
    final firstDay = DateTime(prevMonth.year, prevMonth.month, 1);
    emit(
      state.copyWith(
        selectedMonth: prevMonth,
        selectedDate: firstDay,
        isMonthFilterActive: false,
      ),
    );
    fetchBookingSummary();
    fetchBookings(resetPage: true);
  }

  void setCalendarYear(int year) {
    final current = state.selectedMonth ?? state.selectedDate ?? CairoTimeHelper.now();
    final newMonth = DateTime(year, current.month, 1);
    final firstDay = DateTime(year, current.month, 1);

    emit(
      state.copyWith(
        selectedMonth: newMonth,
        selectedDate: firstDay,
        isMonthFilterActive: false,
      ),
    );
    fetchBookingSummary();
    fetchBookings(resetPage: true);
  }

  void nextCalendarDay() {
    final now = CairoTimeHelper.now();
    final current =
        state.selectedDate ??
        state.selectedMonth ??
        DateTime(now.year, now.month, now.day);
    final next = DateTime(current.year, current.month, current.day + 1);
    onDateSelected(next);
  }

  void previousCalendarDay() {
    final now = CairoTimeHelper.now();
    final current =
        state.selectedDate ??
        state.selectedMonth ??
        DateTime(now.year, now.month, now.day);
    final prev = DateTime(current.year, current.month, current.day - 1);
    onDateSelected(prev);
  }

  void goToToday() {
    final now = CairoTimeHelper.now();
    final today = DateTime(now.year, now.month, now.day);
    onDateSelected(today);
  }

  void onDateSelected(DateTime? date) {
    emit(
      state.copyWith(
        selectedDate: date,
        clearSelectedDate: date == null,
        selectedMonth: date != null
            ? DateTime(date.year, date.month, 1)
            : state.selectedMonth,
        isMonthFilterActive: false,
      ),
    );
    fetchBookingSummary();
    fetchBookings(resetPage: true);
  }

  void clearDateFilter() {
    emit(
      state.copyWith(
        clearSelectedDate: true,
        clearSelectedMonth: true,
        isMonthFilterActive: false,
      ),
    );
    fetchBookingSummary();
    fetchBookings(resetPage: true);
  }

  void selectBookingForEdit(BookingModel? booking) {
    emit(
      state.copyWith(
        selectedBooking: booking,
        clearSelectedBooking: booking == null,
      ),
    );
  }

  // ─── Booking Form State Management (Clean Cubit Logic) ────────────────────

  void initBookingForm(BookingModel? booking) {
    if (booking != null) {
      BookingCustomerOption? cust;
      if (booking.customerId != null) {
        cust = BookingCustomerOption(
          id: booking.customerId!,
          name: booking.customerName ?? '',
          phone: booking.customerPhone ?? '',
          address: booking.customerAddress ?? '',
        );
      }
      final List<BookingTechnicianOption> techs = [];
      if (booking.technicianIds.isNotEmpty) {
        for (int i = 0; i < booking.technicianIds.length; i++) {
          final id = booking.technicianIds[i];
          final name = i < booking.technicianNames.length
              ? booking.technicianNames[i]
              : id;
          techs.add(BookingTechnicianOption(id: id, name: name));
        }
      } else if (booking.technicianId != null) {
        techs.add(
          BookingTechnicianOption(
            id: booking.technicianId!,
            name: booking.technicianName ?? '',
          ),
        );
      }

      emit(
        state.copyWith(
          formState: BookingFormState(
            bookingId: booking.id,
            customer: cust,
            technicians: techs,
            serviceId: booking.serviceId,
            serviceName: booking.serviceName ?? '',
            bookingType: booking.bookingType ?? BookingTypeEnum.oneTime,
            date: booking.date ?? CairoTimeHelper.now(),
            startTime: booking.startTime ?? '',
            endTime: booking.endTime ?? '',
            durationMinutes: booking.durationMinutes ?? 0,
            consultationFee: booking.consultationFee ?? booking.totalPrice ?? 0,
            totalPrice: booking.totalPrice ?? booking.consultationFee ?? 0,
            status: booking.status ?? BookingStatusEnum.waiting,
            paymentStatus: booking.paymentStatus ?? PaymentStatusEnum.unpaid,
            notes: booking.notes ?? '',
          ),
          hasPatientTimeConflict: false,
          hasPatientSameDayNotice: false,
          isPatientConflictConfirmed: false,
        ),
      );
      loadSlotsForCurrentForm();
    } else {
      emit(
        state.copyWith(
          formState: BookingFormState(
            customer: null,
            technicians: const [],
            serviceId: null,
            serviceName: '',
            bookingType: state.activeBookingTypeTab,
            date: CairoTimeHelper.now(),
            startTime: '',
            endTime: '',
            durationMinutes: 0,
            consultationFee: 0,
            totalPrice: 0,
            status: BookingStatusEnum.waiting,
            paymentStatus: PaymentStatusEnum.unpaid,
            notes: '',
          ),
          slotsStatus: RequestStatusEnum.initial,
          availableSlots: const [],
          clearSelectedDayAvailability: true,
          hasPatientTimeConflict: false,
          hasPatientSameDayNotice: false,
          isPatientConflictConfirmed: false,
          clearPatientConflictingBooking: true,
          clearPatientSameDayBooking: true,
        ),
      );
    }
  }

  void updateFormCustomer(BookingCustomerOption? customer) {
    if (state.formState == null) return;
    emit(
      state.copyWith(
        formState: state.formState!.copyWith(customer: customer),
        isPatientConflictConfirmed: false,
      ),
    );
    _checkPatientConflict();
  }

  void updateFormTechnicians(List<BookingTechnicianOption> technicians) {
    if (state.formState == null) return;
    emit(
      state.copyWith(
        formState: state.formState!.copyWith(
          technicians: technicians,
          startTime: '',
          endTime: '',
        ),
        availableSlots: const [],
        slotsStatus: RequestStatusEnum.initial,
      ),
    );
    loadSlotsForCurrentForm();
  }

  void toggleFormTechnician(BookingTechnicianOption technician) {
    if (state.formState == null) return;
    final current = List<BookingTechnicianOption>.from(
      state.formState!.technicians,
    );
    final index = current.indexWhere((t) => t.id == technician.id);
    if (index >= 0) {
      current.removeAt(index);
    } else {
      current.add(technician);
    }
    emit(
      state.copyWith(
        formState: state.formState!.copyWith(
          technicians: current,
          startTime: '',
          endTime: '',
        ),
        availableSlots: const [],
        slotsStatus: RequestStatusEnum.initial,
      ),
    );

    // If selected service is tied to a specific doctor and that doctor is no longer selected, clear service
    if (state.formState?.serviceId != null) {
      final currentService = state.medicalServices.firstWhere(
        (s) => s.id == state.formState!.serviceId,
        orElse: () => const MedicalServiceModel(),
      );
      if (currentService.assignedDoctorId != null &&
          currentService.assignedDoctorId!.isNotEmpty &&
          !current.any((t) => t.id == currentService.assignedDoctorId)) {
        updateFormService(null);
        return;
      }
    }
    loadSlotsForCurrentForm();
  }

  void addFormTechnician(BookingTechnicianOption technician) {
    if (state.formState == null) return;
    final current = List<BookingTechnicianOption>.from(
      state.formState!.technicians,
    );
    if (!current.any((t) => t.id == technician.id)) {
      current.add(technician);
      emit(
        state.copyWith(
          formState: state.formState!.copyWith(
            technicians: current,
            startTime: '',
            endTime: '',
          ),
          availableSlots: const [],
          slotsStatus: RequestStatusEnum.initial,
        ),
      );
      loadSlotsForCurrentForm();
    }
  }

  void removeFormTechnician(String technicianId) {
    if (state.formState == null) return;
    final current = List<BookingTechnicianOption>.from(
      state.formState!.technicians,
    );
    current.removeWhere((t) => t.id == technicianId);
    emit(
      state.copyWith(
        formState: state.formState!.copyWith(
          technicians: current,
          startTime: '',
          endTime: '',
        ),
        availableSlots: const [],
        slotsStatus: RequestStatusEnum.initial,
      ),
    );

    // If selected service is tied to a specific doctor and that doctor is no longer selected, clear service
    if (state.formState?.serviceId != null) {
      final currentService = state.medicalServices.firstWhere(
        (s) => s.id == state.formState!.serviceId,
        orElse: () => const MedicalServiceModel(),
      );
      if (currentService.assignedDoctorId != null &&
          currentService.assignedDoctorId!.isNotEmpty &&
          !current.any((t) => t.id == currentService.assignedDoctorId)) {
        updateFormService(null);
        return;
      }
    }
    loadSlotsForCurrentForm();
  }

  void updateFormTechnician(BookingTechnicianOption? technician) {
    if (state.formState == null) return;
    if (technician == null) {
      emit(
        state.copyWith(
          formState: state.formState!.copyWith(
            clearTechnicians: true,
            startTime: '',
            endTime: '',
          ),
          availableSlots: const [],
          slotsStatus: RequestStatusEnum.initial,
        ),
      );
    } else {
      toggleFormTechnician(technician);
    }
  }

  void updateFormServiceName(String name) {
    if (state.formState == null) return;
    emit(
      state.copyWith(formState: state.formState!.copyWith(serviceName: name)),
    );
  }

  void updateFormBookingType(BookingTypeEnum type) {
    if (state.formState == null) return;
    emit(
      state.copyWith(formState: state.formState!.copyWith(bookingType: type)),
    );
  }

  void updateFormStatus(BookingStatusEnum status) {
    if (state.formState == null) return;
    emit(state.copyWith(formState: state.formState!.copyWith(status: status)));
  }

  void updateFormPaymentStatus(PaymentStatusEnum paymentStatus) {
    if (state.formState == null) return;
    emit(
      state.copyWith(
        formState: state.formState!.copyWith(paymentStatus: paymentStatus),
      ),
    );
  }

  void updateFormDate(DateTime date) {
    if (state.formState == null) return;
    emit(
      state.copyWith(
        formState: state.formState!.copyWith(
          date: date,
          startTime: '',
          endTime: '',
        ),
      ),
    );
    loadSlotsForCurrentForm();
  }

  void updateFormStartTime(String startTime) {
    if (state.formState == null) return;
    final startMinutes = _timeToMinutes(startTime);
    final duration = state.formState!.durationMinutes;

    String newEndTime = state.formState!.endTime;
    int diff = duration;

    if (duration > 0) {
      newEndTime = _minutesToTime(startMinutes + duration);
      diff = duration;
    } else {
      final hasEnd = state.formState!.endTime.isNotEmpty;
      final endMinutes = hasEnd ? _timeToMinutes(state.formState!.endTime) : 0;
      diff = (hasEnd && endMinutes > startMinutes)
          ? endMinutes - startMinutes
          : 0;
    }

    emit(
      state.copyWith(
        formState: state.formState!.copyWith(
          startTime: startTime,
          endTime: newEndTime,
          durationMinutes: diff,
        ),
      ),
    );
    _checkPatientConflict();
  }

  String _minutesToTime(int totalMinutes) {
    final h = (totalMinutes ~/ 60) % 24;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<void> fetchMedicalServices() async {
    if (getMedicalServicesUseCase == null) return;
    final res =
        await getMedicalServicesUseCase!(const GetMedicalServicesParams());
    res.fold(
      (_) {},
      (services) => emit(state.copyWith(medicalServices: services)),
    );
  }

  void updateFormService(MedicalServiceModel? service) {
    if (state.formState == null) return;
    if (service == null) {
      emit(
        state.copyWith(
          formState: state.formState!.copyWith(
            clearServiceId: true,
            serviceName: '',
            startTime: '',
            endTime: '',
            durationMinutes: 0,
          ),
          availableSlots: const [],
          slotsStatus: RequestStatusEnum.initial,
        ),
      );
      return;
    }

    final duration = service.durationMinutes ?? 0;
    final fee = service.consultationFee ?? 0;

    emit(
      state.copyWith(
        formState: state.formState!.copyWith(
          serviceId: service.id,
          serviceName: service.name ?? '',
          consultationFee: fee,
          totalPrice: fee,
          durationMinutes: duration,
          startTime: '',
          endTime: '',
        ),
      ),
    );
    loadSlotsForCurrentForm();
  }

  // ─── Phase 4B: Slot Picker & Conflict Detection ────────────────────────────

  Future<void> loadSlotsForCurrentForm({
    bool forceRefresh = false,
    DateTime? customNow,
  }) async {
    final form = state.formState;
    if (form == null) return;

    final doctorId =
        form.technicians.isNotEmpty ? form.technicians.first.id : null;
    final serviceId = form.serviceId;
    final date = form.date;

    // تتطلب العملية تحديد الطبيب والخدمة واليوم
    if (doctorId == null ||
        doctorId.isEmpty ||
        serviceId == null ||
        serviceId.isEmpty) {
      emit(
        state.copyWith(
          slotsStatus: RequestStatusEnum.initial,
          availableSlots: const [],
          clearSelectedDayAvailability: true,
          clearSlotsErrMessage: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        slotsStatus: RequestStatusEnum.loading,
        errMessage: state.errMessage,
      ),
    );

    try {
      final scheduleFuture = getDoctorScheduleUseCase != null
          ? getDoctorScheduleUseCase!(doctorId)
          : (getIt.isRegistered<GetDoctorScheduleUseCase>()
              ? getIt<GetDoctorScheduleUseCase>()(doctorId)
              : null);

      final leavesFuture = getDoctorLeavesUseCase != null
          ? getDoctorLeavesUseCase!(doctorId)
          : (getIt.isRegistered<GetDoctorLeavesUseCase>()
              ? getIt<GetDoctorLeavesUseCase>()(doctorId)
              : null);

      final holidaysFuture = getCompanySettingsUseCase != null
          ? getCompanySettingsUseCase!(NoParams())
          : (getIt.isRegistered<GetCompanySettingsUseCase>()
              ? getIt<GetCompanySettingsUseCase>()(NoParams())
              : null);

      final bookingsFuture = getDoctorBookingsForDateUseCase != null
          ? getDoctorBookingsForDateUseCase!(doctorId: doctorId, date: date)
          : (getIt.isRegistered<GetDoctorBookingsForDateUseCase>()
              ? getIt<GetDoctorBookingsForDateUseCase>()(
                  doctorId: doctorId,
                  date: date,
                )
              : null);

      DoctorScheduleModel? schedule;
      if (scheduleFuture != null) {
        final res = await scheduleFuture;
        schedule = res.fold((_) => null, (r) => r);
      }

      List<DoctorLeaveModel>? leaves;
      if (leavesFuture != null) {
        final res = await leavesFuture;
        leaves = res.fold((_) => null, (r) => r);
      }

      List<SpecialHolidayModel>? holidays;
      if (holidaysFuture != null) {
        final res = await holidaysFuture;
        holidays = res.fold((_) => null, (r) => r.specialHolidays);
      }

      List<BookingModel> doctorBookings = [];
      if (bookingsFuture != null) {
        final res = await bookingsFuture;
        doctorBookings = res.fold((_) => [], (r) => r);
      } else {
        doctorBookings = state.bookings.where((b) {
          final bDoc = b.doctorId ??
              (b.technicians.isNotEmpty ? b.technicians.first.id : null);
          return bDoc == doctorId &&
              CairoTimeHelper.isSameDay(b.date ?? b.appointmentTime, date);
        }).toList();
      }

      // 5. مدة الخدمة
      final service = state.medicalServices.firstWhere(
        (s) => s.id == serviceId,
        orElse: () => const MedicalServiceModel(),
      );
      final duration =
          (service.durationMinutes != null && service.durationMinutes! > 0)
              ? service.durationMinutes!
              : (form.durationMinutes > 0 ? form.durationMinutes : 20);

      // 6. توليد الفترات عبر SlotGeneratorHelper
      final result = SlotGeneratorHelper.generateSlots(
        schedule: schedule,
        leaves: leaves,
        holidays: holidays,
        doctorBookings: doctorBookings,
        serviceDurationMinutes: duration,
        date: date,
        customNow: customNow,
        excludeBookingId: form.bookingId,
        currentBookingStartTime:
            form.startTime.isNotEmpty ? form.startTime : null,
        currentBookingEndTime:
            form.endTime.isNotEmpty ? form.endTime : null,
      );

      final currentForm = state.formState;
      if (currentForm == null) return;

      // إذا كانت الفترة المحددة سابقاً أصبحت غير متاحة، نقوم بمسحها
      String newStartTime = currentForm.startTime;
      String newEndTime = currentForm.endTime;
      if (newStartTime.isNotEmpty && !forceRefresh) {
        final matchingSlot = result.slots.firstWhere(
          (s) => s.startTime == newStartTime,
          orElse: () => const TimeSlotModel(),
        );
        if (matchingSlot.startTime == null ||
            matchingSlot.status != SlotStatusEnum.available) {
          if (matchingSlot.isCurrentBookingSlot != true) {
            newStartTime = '';
            newEndTime = '';
          }
        }
      }

      emit(
        state.copyWith(
          slotsStatus: RequestStatusEnum.success,
          errMessage: state.errMessage,
          availableSlots: result.slots,
          selectedDayAvailability: result.dayAvailability,
          currentDoctorSchedule: schedule,
          currentDoctorLeaves: leaves,
          facilityHolidays: holidays,
          formState: currentForm.copyWith(
            startTime: newStartTime,
            endTime: newEndTime,
            durationMinutes: duration,
          ),
        ),
      );

      _checkPatientConflict();
    } catch (e) {
      emit(
        state.copyWith(
          slotsStatus: RequestStatusEnum.failure,
          slotsErrMessage: e.toString(),
          errMessage: state.errMessage,
        ),
      );
    }
  }

  void selectTimeSlot(TimeSlotModel slot) {
    if (state.formState == null) return;
    if (slot.status != SlotStatusEnum.available &&
        slot.isCurrentBookingSlot != true) {
      return;
    }

    emit(
      state.copyWith(
        formState: state.formState!.copyWith(
          startTime: slot.startTime,
          endTime: slot.endTime,
          durationMinutes: slot.serviceDurationMinutes ??
              state.formState!.durationMinutes,
        ),
        isPatientConflictConfirmed: false,
      ),
    );

    _checkPatientConflict();
  }

  void _checkPatientConflict() {
    final form = state.formState;
    if (form == null ||
        form.customer == null ||
        form.startTime.isEmpty ||
        form.endTime.isEmpty) {
      emit(
        state.copyWith(
          hasPatientTimeConflict: false,
          hasPatientSameDayNotice: false,
          clearPatientConflictingBooking: true,
          clearPatientSameDayBooking: true,
        ),
      );
      return;
    }

    final conflictRes = SlotGeneratorHelper.checkPatientConflict(
      allBookings: state.bookings,
      patientId: form.customer!.id,
      date: form.date,
      startTime: form.startTime,
      endTime: form.endTime,
      excludeBookingId: form.bookingId,
    );

    emit(
      state.copyWith(
        hasPatientTimeConflict: conflictRes.hasTimeConflict,
        hasPatientSameDayNotice: conflictRes.hasSameDayNotice,
        patientConflictingBooking: conflictRes.conflictingBooking,
        patientSameDayBooking: conflictRes.sameDayBooking,
      ),
    );
  }

  void confirmPatientTimeConflict() {
    emit(state.copyWith(isPatientConflictConfirmed: true));
  }

  void clearPatientTimeConflict() {
    emit(
      state.copyWith(
        hasPatientTimeConflict: false,
        isPatientConflictConfirmed: false,
        clearPatientConflictingBooking: true,
      ),
    );
  }

  void updateFormEndTime(String endTime) {
    if (state.formState == null) return;
    final hasStart = state.formState!.startTime.isNotEmpty;
    final startMinutes = hasStart
        ? _timeToMinutes(state.formState!.startTime)
        : 0;
    final endMinutes = _timeToMinutes(endTime);
    final diff = (hasStart && endMinutes > startMinutes)
        ? endMinutes - startMinutes
        : 0;

    emit(
      state.copyWith(
        formState: state.formState!.copyWith(
          endTime: endTime,
          durationMinutes: diff,
        ),
      ),
    );
  }

  void updateFormConsultationFee(num fee) {
    if (state.formState == null) return;
    emit(
      state.copyWith(
        formState: state.formState!.copyWith(
          consultationFee: fee,
          totalPrice: fee > 0 ? fee : state.formState!.totalPrice,
        ),
      ),
    );
  }

  /// Backward-compatibility alias
  void updateFormHourlyRate(num rate) => updateFormConsultationFee(rate);

  void updateFormTotalPrice(num total) {
    if (state.formState == null) return;
    emit(
      state.copyWith(formState: state.formState!.copyWith(totalPrice: total)),
    );
  }

  void updateFormNotes(String notes) {
    if (state.formState == null) return;
    emit(state.copyWith(formState: state.formState!.copyWith(notes: notes)));
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  Future<bool> submitBookingForm({
    String? serviceName,
    num? consultationFee,
    num? hourlyRate,
    num? totalPrice,
    String? notes,
    DateTime? customNow,
  }) async {
    final form = state.formState;
    if (form == null) return false;

    // التحقق من تعارض مواعيد المريض: إذا وجد تقاطع زمني ولم يؤكد المستخدم صراحة
    if (state.hasPatientTimeConflict && !state.isPatientConflictConfirmed) {
      emit(
        state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          errMessage: 'patient_time_conflict_warning',
        ),
      );
      return false;
    }

    final resolvedFee =
        consultationFee ?? hourlyRate ?? form.consultationFee;
    final resolvedTotal = totalPrice ??
        (resolvedFee > 0 ? resolvedFee : form.totalPrice);

    final booking = BookingModel(
      id: form.bookingId,
      customer: form.customer != null
          ? CustomerModel(
              id: form.customer!.id,
              name: form.customer!.name,
              phone: form.customer!.phone,
              detailedAddress: form.customer!.address,
            )
          : null,
      patientId: form.customer?.id,
      patientName: form.customer?.name,
      patientPhone: form.customer?.phone,
      technicians: form.technicians
          .map((t) => TechnicianModel(id: t.id, name: t.name))
          .toList(),
      doctorId: form.technicians.isNotEmpty ? form.technicians.first.id : null,
      doctorName:
          form.technicians.isNotEmpty ? form.technicians.first.name : null,
      serviceId: form.serviceId,
      serviceName: form.serviceName.isNotEmpty ? form.serviceName : serviceName,
      bookingType: form.bookingType,
      date: form.date,
      startTime: form.startTime,
      endTime: form.endTime,
      durationMinutes: form.durationMinutes,
      consultationFee: resolvedFee,
      totalPrice: resolvedTotal,
      status: form.status,
      paymentStatus: form.paymentStatus,
      notes: notes ?? form.notes,
    );

    if (form.bookingId != null) {
      return await updateBooking(booking, customNow: customNow);
    } else {
      return await createBooking(booking, customNow: customNow);
    }
  }

  Future<bool> createBooking(BookingModel booking, {DateTime? customNow}) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final result = await createBookingUseCase(booking, customNow: customNow);
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
            formState: state.formState?.copyWith(
              startTime: '',
              endTime: '',
            ),
          ),
        );
        loadSlotsForCurrentForm(forceRefresh: true);
        return false;
      },
      (created) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            actionSuccessMessage: 'booking_created_successfully',
          ),
        );
        fetchBookingSummary();
        fetchBookings(resetPage: true);
        return true;
      },
    );
  }

  // ─── Booking Details Flow ────────────────────────────────────────────────
  Future<void> getBookingDetails(String bookingId) async {
    _currentBookingId = bookingId;
    if (state.technicians.isEmpty) {
      _initFormOptions();
      fetchTechnicians();
    }
    emit(
      state.copyWith(
        detailsStatus: RequestStatusEnum.loading,
        actionStatus: RequestStatusEnum.initial,
        isDeleted: false,
      ),
    );

    final result = await getBookingByIdUseCase(bookingId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          detailsStatus: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ),
      ),
      (booking) => emit(
        state.copyWith(
          detailsStatus: RequestStatusEnum.success,
          selectedBooking: booking,
        ),
      ),
    );
  }

  Future<void> refreshBookingDetails() async {
    if (_currentBookingId != null && _currentBookingId!.isNotEmpty) {
      await getBookingDetails(_currentBookingId!);
    }
  }

  Future<bool> updateBooking(BookingModel booking, {DateTime? customNow}) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final result = await updateBookingUseCase(booking, customNow: customNow);
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
            formState: state.formState?.copyWith(
              startTime: '',
              endTime: '',
            ),
          ),
        );
        loadSlotsForCurrentForm(forceRefresh: true);
        return false;
      },
      (updated) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            selectedBooking: updated,
            actionSuccessMessage: 'booking_updated_successfully',
          ),
        );
        fetchBookingSummary();
        fetchBookings(resetPage: false);
        return true;
      },
    );
  }

  Future<bool> changeBookingStatus(
    String bookingId,
    BookingStatusEnum newStatus, {
    DateTime? rescheduledTo,
    String? postponeReason,
    String? cancelReason,
    String? cancelledBy,
    DateTime? cancelledAt,
    DateTime? arrivalTime,
  }) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final params = ChangeBookingStatusParams(
      bookingId: bookingId,
      newStatus: newStatus,
      rescheduledTo: rescheduledTo ?? state.dialogPostponeDate,
      postponeReason: postponeReason ?? state.dialogPostponeReason,
      cancelReason: cancelReason ?? state.dialogCancelReason,
      cancelledBy: cancelledBy ?? state.dialogCancelledBy,
      cancelledAt: cancelledAt ??
          (newStatus == BookingStatusEnum.cancelled
              ? CairoTimeHelper.now()
              : null),
      arrivalTime: arrivalTime,
    );
    final result = await changeBookingStatusUseCase(params);
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
        final currentSelected = state.selectedBooking;
        final updatedBooking =
            (currentSelected != null && currentSelected.id == bookingId)
                ? currentSelected.copyWith(
                    status: newStatus,
                    rescheduledTo:
                        rescheduledTo ?? state.dialogPostponeDate,
                    postponeReason:
                        postponeReason ?? state.dialogPostponeReason,
                    cancelReason:
                        cancelReason ?? state.dialogCancelReason,
                    cancelledBy:
                        cancelledBy ?? state.dialogCancelledBy,
                    cancelledAt: cancelledAt ??
                        (newStatus == BookingStatusEnum.cancelled
                            ? CairoTimeHelper.now()
                            : null),
                    arrivalTime: arrivalTime ??
                        (newStatus == BookingStatusEnum.waiting &&
                                currentSelected.status ==
                                    BookingStatusEnum.noShow
                            ? CairoTimeHelper.now()
                            : currentSelected.arrivalTime),
                    updatedAt: CairoTimeHelper.now(),
                  )
                : currentSelected;
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            selectedBooking: updatedBooking,
            actionSuccessMessage: 'status_updated_successfully',
          ),
        );
        fetchBookingSummary();
        fetchBookings(resetPage: false);
        return true;
      },
    );
  }

  Future<bool> reassignTechnicians(
    String bookingId,
    List<String> technicianIds,
    List<String> technicianNames,
  ) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final params = ReassignTechnicianParams(
      bookingId: bookingId,
      newTechnicianIds: technicianIds,
      newTechnicianNames: technicianNames,
    );
    final result = await reassignTechnicianUseCase(params);
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
        final currentSelected = state.selectedBooking;
        final updatedBooking =
            (currentSelected != null && currentSelected.id == bookingId)
            ? currentSelected.copyWith(
                technicians: [
                  for (int i = 0; i < technicianIds.length; i++)
                    TechnicianModel(
                      id: technicianIds[i],
                      name: i < technicianNames.length
                          ? technicianNames[i]
                          : null,
                    ),
                ],
                technicianIds: technicianIds,
                technicianNames: technicianNames,
                technicianId: technicianIds.isNotEmpty
                    ? technicianIds.first
                    : null,
                technicianName: technicianNames.isNotEmpty
                    ? technicianNames.join('، ')
                    : null,
                updatedAt: CairoTimeHelper.now(),
              )
            : currentSelected;
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            selectedBooking: updatedBooking,
            actionSuccessMessage: 'technician_reassigned_successfully',
          ),
        );
        fetchBookings(resetPage: false);
        return true;
      },
    );
  }

  Future<bool> reassignTechnician(
    String bookingId,
    String newTechnicianId,
    String? newTechnicianName,
  ) => reassignTechnicians(bookingId, [
    newTechnicianId,
  ], newTechnicianName != null ? [newTechnicianName] : const []);

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
        final isDeletedTarget = state.selectedBooking?.id == bookingId;
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            isDeleted: isDeletedTarget,
            actionSuccessMessage: 'booking_deleted_successfully',
          ),
        );
        fetchBookingSummary();
        fetchBookings(resetPage: false);
        return true;
      },
    );
  }

  // ─── Action Dialogs State Management (Clean Cubit Driven) ───────────────

  void initChangeStatusDialog(
    BookingStatusEnum currentStatus, {
    BookingModel? booking,
  }) {
    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.initial,
        dialogStatus: currentStatus,
        dialogPostponeDate: booking?.rescheduledTo,
        dialogPostponeTime: booking?.rescheduledTo != null
            ? '${booking!.rescheduledTo!.hour.toString().padLeft(2, '0')}:${booking.rescheduledTo!.minute.toString().padLeft(2, '0')}'
            : null,
        dialogPostponeReason: booking?.postponeReason,
        dialogCancelReason: booking?.cancelReason,
        dialogCancelledBy: booking?.cancelledBy ?? 'patient',
      ),
    );
  }

  void selectStatusToChange(BookingStatusEnum status) {
    emit(state.copyWith(dialogStatus: status));
  }

  void updateDialogPostponeDate(DateTime date) {
    emit(state.copyWith(dialogPostponeDate: date));
  }

  void updateDialogPostponeTime(String time) {
    emit(state.copyWith(dialogPostponeTime: time));
  }

  void updateDialogPostponeReason(String reason) {
    emit(state.copyWith(dialogPostponeReason: reason));
  }

  void updateDialogCancelReason(String reason) {
    emit(state.copyWith(dialogCancelReason: reason));
  }

  void updateDialogCancelledBy(String by) {
    emit(state.copyWith(dialogCancelledBy: by));
  }

  void initReassignTechniciansDialog(List<String> currentIds) {
    if (state.technicians.isEmpty) {
      _initFormOptions();
      fetchTechnicians();
    }
    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.initial,
        dialogTechnicianIds: currentIds.toSet(),
      ),
    );
  }

  void toggleReassignTechnician(String technicianId) {
    final current = Set<String>.from(state.dialogTechnicianIds);
    if (current.contains(technicianId)) {
      current.remove(technicianId);
    } else {
      current.add(technicianId);
    }
    emit(state.copyWith(dialogTechnicianIds: current));
  }

  @override
  Future<void> close() {
    _noShowTimer?.cancel();
    AppBranchService.instance.selectedBranchNotifier
        .removeListener(_onGlobalBranchChanged);
    disposeSearch();
    return super.close();
  }
}
