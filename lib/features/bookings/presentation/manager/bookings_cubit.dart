import 'package:eyadty/core/base/safe_cubit.dart';
import 'package:eyadty/core/mixins/search_mixin.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/booking_form_options_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/recurrence_rule_model.dart';
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
import 'package:eyadty/features/customers/data/models/customer_model.dart';
import 'package:eyadty/features/customers/domain/use_cases/get_customers_use_case.dart';
import 'package:eyadty/features/technicians/data/models/technician_model.dart';
import 'package:eyadty/features/technicians/domain/use_cases/get_technicians_use_case.dart';

import 'bookings_state.dart';

class BookingsCubit extends SafeCubit<BookingsState> with SearchMixin {
  final GetBookingSummaryUseCase getBookingSummaryUseCase;
  final GetBookingsUseCase getBookingsUseCase;
  final GetBookingByIdUseCase getBookingByIdUseCase;
  final CreateBookingUseCase createBookingUseCase;
  final UpdateBookingUseCase updateBookingUseCase;
  final ChangeBookingStatusUseCase changeBookingStatusUseCase;
  final ReassignTechnicianUseCase reassignTechnicianUseCase;
  final DeleteBookingUseCase deleteBookingUseCase;
  final GetTechniciansUseCase? getTechniciansUseCase;
  final GetCustomersUseCase? getCustomersUseCase;

  BookingsCubit({
    required this.getBookingSummaryUseCase,
    required this.getBookingsUseCase,
    required this.getBookingByIdUseCase,
    required this.createBookingUseCase,
    required this.updateBookingUseCase,
    required this.changeBookingStatusUseCase,
    required this.reassignTechnicianUseCase,
    required this.deleteBookingUseCase,
    this.getTechniciansUseCase,
    this.getCustomersUseCase,
  }) : super(const BookingsState()) {
    _initFormOptions();
    fetchTechnicians();
    fetchCustomers();
  }

  String? _currentBookingId;

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
    if (getTechniciansUseCase == null) return;
    final result = await getTechniciansUseCase!(
      const PaginationParams(page: 1, limit: 100),
    );
    result.fold(
      (_) {},
      (response) {
        if (response.items.isNotEmpty) {
          final options = response.items
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
    if (getCustomersUseCase == null) return;
    final result = await getCustomersUseCase!(
      const PaginationParams(page: 1, limit: 100),
    );
    result.fold(
      (_) {},
      (response) {
        if (response.items.isNotEmpty) {
          final options = response.items
              .map(
                (c) => BookingCustomerOption(
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
    final result = await getBookingSummaryUseCase(NoParams());
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
      if (state.selectedDate != null) {
        final d = state.selectedDate!;
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
    fetchBookings(resetPage: true);
  }

  void nextCalendarMonth() {
    final current = state.selectedMonth ?? state.selectedDate ?? DateTime.now();
    final nextMonth = DateTime(current.year, current.month + 1, 1);
    final firstDay = DateTime(nextMonth.year, nextMonth.month, 1);
    emit(
      state.copyWith(
        selectedMonth: nextMonth,
        selectedDate: firstDay,
        isMonthFilterActive: false,
      ),
    );
    fetchBookings(resetPage: true);
  }

  void previousCalendarMonth() {
    final current = state.selectedMonth ?? state.selectedDate ?? DateTime.now();
    final prevMonth = DateTime(current.year, current.month - 1, 1);
    final firstDay = DateTime(prevMonth.year, prevMonth.month, 1);
    emit(
      state.copyWith(
        selectedMonth: prevMonth,
        selectedDate: firstDay,
        isMonthFilterActive: false,
      ),
    );
    fetchBookings(resetPage: true);
  }

  void setCalendarYear(int year) {
    final current = state.selectedMonth ?? state.selectedDate ?? DateTime.now();
    final newMonth = DateTime(year, current.month, 1);
    final firstDay = DateTime(year, current.month, 1);

    emit(
      state.copyWith(
        selectedMonth: newMonth,
        selectedDate: firstDay,
        isMonthFilterActive: false,
      ),
    );

    fetchBookings(resetPage: true);
  }

  void nextCalendarDay() {
    final now = DateTime.now();
    final current =
        state.selectedDate ??
        state.selectedMonth ??
        DateTime(now.year, now.month, now.day);
    final next = DateTime(current.year, current.month, current.day + 1);
    onDateSelected(next);
  }

  void previousCalendarDay() {
    final now = DateTime.now();
    final current =
        state.selectedDate ??
        state.selectedMonth ??
        DateTime(now.year, now.month, now.day);
    final prev = DateTime(current.year, current.month, current.day - 1);
    onDateSelected(prev);
  }

  void goToToday() {
    final now = DateTime.now();
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

      final recSchedules =
          booking.recurrence?.daySchedules ??
          (booking.recurrence?.daysOfWeek
                  ?.map(
                    (d) => RecurringDaySchedule(
                      day: d,
                      startTime: booking.startTime ?? '10:00',
                      endTime: booking.endTime ?? '12:00',
                    ),
                  )
                  .toList() ??
              const <RecurringDaySchedule>[]);

      emit(
        state.copyWith(
          formState: BookingFormState(
            bookingId: booking.id,
            customer: cust,
            technicians: techs,
            serviceName: booking.serviceName ?? '',
            bookingType: booking.bookingType ?? BookingTypeEnum.oneTime,
            date: booking.date ?? DateTime.now(),
            startTime: booking.startTime ?? '10:00',
            endTime: booking.endTime ?? '12:00',
            durationMinutes: booking.durationMinutes ?? 120,
            hourlyRate: booking.hourlyRate ?? 80,
            totalPrice: booking.totalPrice ?? 0,
            status: booking.status ?? BookingStatusEnum.scheduled,
            paymentStatus: booking.paymentStatus ?? PaymentStatusEnum.unpaid,
            notes: booking.notes ?? '',
            recurringSchedules: recSchedules,
            recurrenceEndDate: booking.recurrence?.endDate,
            isOngoing: booking.recurrence?.isOngoing ?? true,
          ),
        ),
      );
    } else {
      emit(
        state.copyWith(
          formState: BookingFormState(
            customer: null,
            technicians: const [],
            serviceName: '',
            bookingType: state.activeBookingTypeTab,
            date: DateTime.now(),
            startTime: '',
            endTime: '',
            durationMinutes: 0,
            hourlyRate: 0,
            totalPrice: 0,
            status: BookingStatusEnum.scheduled,
            paymentStatus: PaymentStatusEnum.unpaid,
            notes: '',
            recurringSchedules: const [],
            recurrenceEndDate: null,
            isOngoing: true,
          ),
        ),
      );
    }
  }

  void updateFormCustomer(BookingCustomerOption? customer) {
    if (state.formState == null) return;
    emit(
      state.copyWith(formState: state.formState!.copyWith(customer: customer)),
    );
  }

  void updateFormTechnicians(List<BookingTechnicianOption> technicians) {
    if (state.formState == null) return;
    emit(
      state.copyWith(
        formState: state.formState!.copyWith(technicians: technicians),
      ),
    );
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
        formState: state.formState!.copyWith(technicians: current),
      ),
    );
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
          formState: state.formState!.copyWith(technicians: current),
        ),
      );
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
        formState: state.formState!.copyWith(technicians: current),
      ),
    );
  }

  void updateFormTechnician(BookingTechnicianOption? technician) {
    if (state.formState == null) return;
    if (technician == null) {
      emit(
        state.copyWith(
          formState: state.formState!.copyWith(clearTechnicians: true),
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
    emit(state.copyWith(formState: state.formState!.copyWith(date: date)));
  }

  void updateFormStartTime(String startTime) {
    if (state.formState == null) return;
    final startMinutes = _timeToMinutes(startTime);
    final hasEnd = state.formState!.endTime.isNotEmpty;
    final endMinutes = hasEnd ? _timeToMinutes(state.formState!.endTime) : 0;
    final diff = (hasEnd && endMinutes > startMinutes)
        ? endMinutes - startMinutes
        : 0;
    final totalPrice = diff > 0
        ? (state.formState!.hourlyRate * (diff / 60)).round()
        : 0;

    emit(
      state.copyWith(
        formState: state.formState!.copyWith(
          startTime: startTime,
          durationMinutes: diff,
          totalPrice: totalPrice,
        ),
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
    final totalPrice = diff > 0
        ? (state.formState!.hourlyRate * (diff / 60)).round()
        : 0;

    emit(
      state.copyWith(
        formState: state.formState!.copyWith(
          endTime: endTime,
          durationMinutes: diff,
          totalPrice: totalPrice,
        ),
      ),
    );
  }

  void updateFormHourlyRate(num rate) {
    if (state.formState == null) return;
    final total = (rate * (state.formState!.durationMinutes / 60)).round();
    emit(
      state.copyWith(
        formState: state.formState!.copyWith(
          hourlyRate: rate,
          totalPrice: total,
        ),
      ),
    );
  }

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

  void toggleRecurringDay(String day) {
    if (state.formState == null) return;
    final current = List<RecurringDaySchedule>.from(
      state.formState!.recurringSchedules,
    );
    final index = current.indexWhere((s) => s.day == day);
    if (index >= 0) {
      current.removeAt(index);
    } else {
      final defaultStart = state.formState!.startTime.isNotEmpty
          ? state.formState!.startTime
          : '10:00';
      final defaultEnd = state.formState!.endTime.isNotEmpty
          ? state.formState!.endTime
          : '12:00';
      current.add(
        RecurringDaySchedule(
          day: day,
          startTime: defaultStart,
          endTime: defaultEnd,
        ),
      );
    }
    emit(
      state.copyWith(
        formState: state.formState!.copyWith(recurringSchedules: current),
      ),
    );
  }

  void updateRecurringDayTime(
    String day, {
    String? startTime,
    String? endTime,
  }) {
    if (state.formState == null) return;
    final current = state.formState!.recurringSchedules.map((s) {
      if (s.day == day) {
        return s.copyWith(
          startTime: startTime ?? s.startTime,
          endTime: endTime ?? s.endTime,
        );
      }
      return s;
    }).toList();
    emit(
      state.copyWith(
        formState: state.formState!.copyWith(recurringSchedules: current),
      ),
    );
  }

  void updateRecurrenceEndDate(DateTime? endDate) {
    if (state.formState == null) return;
    emit(
      state.copyWith(
        formState: state.formState!.copyWith(
          recurrenceEndDate: endDate,
          clearRecurrenceEndDate: endDate == null,
        ),
      ),
    );
  }

  void updateRecurrenceOngoing(bool isOngoing) {
    if (state.formState == null) return;
    emit(
      state.copyWith(
        formState: state.formState!.copyWith(
          isOngoing: isOngoing,
          clearRecurrenceEndDate: isOngoing,
        ),
      ),
    );
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
    num? hourlyRate,
    num? totalPrice,
    String? notes,
  }) async {
    final form = state.formState;
    if (form == null) return false;

    final isRecurring = form.bookingType == BookingTypeEnum.recurring;
    final recurrence = isRecurring && form.recurringSchedules.isNotEmpty
        ? RecurrenceRuleModel(
            frequency: 'weekly',
            daysOfWeek: form.recurringSchedules.map((s) => s.day).toList(),
            daySchedules: form.recurringSchedules,
            startDate: form.date,
            isOngoing: form.isOngoing,
            endDate: form.isOngoing ? null : form.recurrenceEndDate,
          )
        : null;

    final booking = BookingModel(
      id: form.bookingId,
      customer: form.customer != null
          ? CustomerModel(
              id: form.customer!.id,
              name: form.customer!.name,
              phone: form.customer!.phone,
              address: form.customer!.address,
            )
          : null,
      technicians: form.technicians
          .map((t) => TechnicianModel(id: t.id, name: t.name))
          .toList(),
      serviceName: serviceName ?? form.serviceName,
      bookingType: form.bookingType,
      date: form.date,
      recurrence: recurrence,
      startTime: form.startTime,
      endTime: form.endTime,
      durationMinutes: form.durationMinutes,
      hourlyRate: hourlyRate ?? form.hourlyRate,
      totalPrice: totalPrice ?? form.totalPrice,
      status: form.status,
      paymentStatus: form.paymentStatus,
      notes: notes ?? form.notes,
    );

    if (form.bookingId != null) {
      return await updateBooking(booking);
    } else {
      return await createBooking(booking);
    }
  }

  Future<bool> createBooking(BookingModel booking) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final result = await createBookingUseCase(booking);
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

  Future<bool> updateBooking(BookingModel booking) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final result = await updateBookingUseCase(booking);
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
    BookingStatusEnum newStatus,
  ) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final params = ChangeBookingStatusParams(
      bookingId: bookingId,
      newStatus: newStatus,
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
                updatedAt: DateTime.now(),
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
                updatedAt: DateTime.now(),
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

  void initChangeStatusDialog(BookingStatusEnum currentStatus) {
    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.initial,
        dialogStatus: currentStatus,
      ),
    );
  }

  void selectStatusToChange(BookingStatusEnum status) {
    emit(state.copyWith(dialogStatus: status));
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
    disposeSearch();
    return super.close();
  }
}
