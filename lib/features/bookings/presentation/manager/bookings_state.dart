import 'package:equatable/equatable.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/booking_form_options_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_summary_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/recurrence_rule_model.dart';

class BookingFormState extends Equatable {
  final String? bookingId;
  final BookingCustomerOption? customer;
  final List<BookingTechnicianOption> technicians;
  final String serviceName;
  final BookingTypeEnum bookingType;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final num hourlyRate;
  final num totalPrice;
  final BookingStatusEnum status;
  final PaymentStatusEnum paymentStatus;
  final String notes;
  final List<RecurringDaySchedule> recurringSchedules;
  final DateTime? recurrenceEndDate;
  final bool isOngoing;

  BookingTechnicianOption? get technician =>
      technicians.isNotEmpty ? technicians.first : null;

  const BookingFormState({
    this.bookingId,
    this.customer,
    this.technicians = const [],
    this.serviceName = '',
    this.bookingType = BookingTypeEnum.oneTime,
    required this.date,
    this.startTime = '',
    this.endTime = '',
    this.durationMinutes = 0,
    this.hourlyRate = 0,
    this.totalPrice = 0,
    this.status = BookingStatusEnum.scheduled,
    this.paymentStatus = PaymentStatusEnum.unpaid,
    this.notes = '',
    this.recurringSchedules = const [],
    this.recurrenceEndDate,
    this.isOngoing = true,
  });

  BookingFormState copyWith({
    String? bookingId,
    bool clearBookingId = false,
    BookingCustomerOption? customer,
    bool clearCustomer = false,
    List<BookingTechnicianOption>? technicians,
    BookingTechnicianOption? technician,
    bool clearTechnicians = false,
    bool clearTechnician = false,
    String? serviceName,
    BookingTypeEnum? bookingType,
    DateTime? date,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    num? hourlyRate,
    num? totalPrice,
    BookingStatusEnum? status,
    PaymentStatusEnum? paymentStatus,
    String? notes,
    List<RecurringDaySchedule>? recurringSchedules,
    DateTime? recurrenceEndDate,
    bool clearRecurrenceEndDate = false,
    bool? isOngoing,
  }) {
    List<BookingTechnicianOption> resolvedTechs;
    if (clearTechnicians || clearTechnician) {
      resolvedTechs = const [];
    } else if (technicians != null) {
      resolvedTechs = technicians;
    } else if (technician != null) {
      resolvedTechs = [technician];
    } else {
      resolvedTechs = this.technicians;
    }

    return BookingFormState(
      bookingId: clearBookingId ? null : (bookingId ?? this.bookingId),
      customer: clearCustomer ? null : (customer ?? this.customer),
      technicians: resolvedTechs,
      serviceName: serviceName ?? this.serviceName,
      bookingType: bookingType ?? this.bookingType,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      recurringSchedules: recurringSchedules ?? this.recurringSchedules,
      recurrenceEndDate: clearRecurrenceEndDate
          ? null
          : (recurrenceEndDate ?? this.recurrenceEndDate),
      isOngoing: isOngoing ?? this.isOngoing,
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        customer,
        technicians,
        serviceName,
        bookingType,
        date,
        startTime,
        endTime,
        durationMinutes,
        hourlyRate,
        totalPrice,
        status,
        paymentStatus,
        notes,
        recurringSchedules,
        recurrenceEndDate,
        isOngoing,
      ];
}

class BookingsState extends Equatable {
  final RequestStatusEnum summaryStatus;
  final RequestStatusEnum bookingsStatus;
  final RequestStatusEnum detailsStatus;
  final RequestStatusEnum actionStatus;

  final BookingSummaryModel? summary;
  final List<BookingModel> bookings;
  final PaginationModel? pagination;

  final List<BookingCustomerOption> customers;
  final List<BookingTechnicianOption> technicians;

  final DateTime? selectedDate;
  final DateTime? selectedMonth;
  final bool isMonthFilterActive;
  final BookingStatusEnum? selectedStatus;
  final String searchQuery;
  final int currentPage;
  final BookingTypeEnum activeBookingTypeTab;
  final String? selectedDayOfWeek;

  final BookingModel? selectedBooking;
  final BookingFormState? formState;
  final String? errMessage;
  final String? actionSuccessMessage;
  final bool isDeleted;
  final BookingStatusEnum? dialogStatus;
  final Set<String> dialogTechnicianIds;

  BookingModel? get booking => selectedBooking;

  static const List<BookingCustomerOption> initialCustomers = [
    BookingCustomerOption(
      id: 'PAT-01',
      name: 'سارة أحمد عبد الله',
      phone: '+20 101 234 5678',
      address: 'القاهرة - المعادي الجديدة، شارع النصر',
    ),
    BookingCustomerOption(
      id: 'PAT-02',
      name: 'يوسف إبراهيم المنصوري',
      phone: '+20 102 345 6789',
      address: 'الجيزة - الدقي، شارع مصدق',
    ),
    BookingCustomerOption(
      id: 'PAT-03',
      name: 'مريم حسن الشريف',
      phone: '+20 103 456 7890',
      address: 'التجمع الخامس - النرجس عمارات',
    ),
    BookingCustomerOption(
      id: 'PAT-04',
      name: 'خالد عبد الرحمن السليطي',
      phone: '+20 104 567 8901',
      address: 'الشيخ زايد - كمبوند الربوة',
    ),
    BookingCustomerOption(
      id: 'PAT-05',
      name: 'ندى عمر القحطاني',
      phone: '+20 105 678 9012',
      address: 'مدينة نصر - الحي السابع',
    ),
  ];

  static const List<BookingTechnicianOption> initialTechnicians = [
    BookingTechnicianOption(id: 'DOC-01', name: 'د. رامي سلامة (باطنة)'),
    BookingTechnicianOption(id: 'DOC-02', name: 'د. نورهان السيد (أطفال)'),
    BookingTechnicianOption(id: 'DOC-03', name: 'د. حازم زكي (عظام)'),
    BookingTechnicianOption(id: 'DOC-04', name: 'د. ريم المهدي (عيون)'),
    BookingTechnicianOption(
      id: 'TECH-03',
      name: 'د. يوسف النجار (أنف وأذن)',
      isAvailable: false,
      unavailableReason: 'في إجازة سنوية',
    ),
    BookingTechnicianOption(id: 'TECH-04', name: 'د. طارق العسيري (جلدية)'),
    BookingTechnicianOption(id: 'TECH-05', name: 'د. ماجد القاضي (أسنان)'),
  ];

  final String selectedBranchId;
  final DateTime? dialogPostponeDate;
  final String? dialogPostponeTime;
  final String? dialogPostponeReason;
  final String? dialogCancelReason;
  final String dialogCancelledBy;

  const BookingsState({
    this.summaryStatus = RequestStatusEnum.initial,
    this.bookingsStatus = RequestStatusEnum.initial,
    this.detailsStatus = RequestStatusEnum.initial,
    this.actionStatus = RequestStatusEnum.initial,
    this.summary,
    this.bookings = const [],
    this.pagination,
    this.customers = initialCustomers,
    this.technicians = initialTechnicians,
    this.selectedBranchId = 'branch_1',
    this.selectedDate,
    this.selectedMonth,
    this.isMonthFilterActive = false,
    this.selectedStatus,
    this.searchQuery = '',
    this.currentPage = 1,
    this.activeBookingTypeTab = BookingTypeEnum.oneTime,
    this.selectedDayOfWeek,
    this.selectedBooking,
    this.formState,
    this.errMessage,
    this.actionSuccessMessage,
    this.isDeleted = false,
    this.dialogStatus,
    this.dialogTechnicianIds = const {},
    this.dialogPostponeDate,
    this.dialogPostponeTime,
    this.dialogPostponeReason,
    this.dialogCancelReason,
    this.dialogCancelledBy = 'patient',
  });

  BookingsState copyWith({
    RequestStatusEnum? summaryStatus,
    RequestStatusEnum? bookingsStatus,
    RequestStatusEnum? detailsStatus,
    RequestStatusEnum? actionStatus,
    BookingSummaryModel? summary,
    List<BookingModel>? bookings,
    PaginationModel? pagination,
    List<BookingCustomerOption>? customers,
    List<BookingTechnicianOption>? technicians,
    String? selectedBranchId,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    DateTime? selectedMonth,
    bool clearSelectedMonth = false,
    bool? isMonthFilterActive,
    BookingStatusEnum? selectedStatus,
    bool clearSelectedStatus = false,
    String? searchQuery,
    int? currentPage,
    BookingTypeEnum? activeBookingTypeTab,
    String? selectedDayOfWeek,
    bool clearSelectedDayOfWeek = false,
    BookingModel? selectedBooking,
    bool clearSelectedBooking = false,
    BookingFormState? formState,
    bool clearFormState = false,
    String? errMessage,
    String? actionSuccessMessage,
    bool? isDeleted,
    BookingStatusEnum? dialogStatus,
    bool clearDialogStatus = false,
    Set<String>? dialogTechnicianIds,
    DateTime? dialogPostponeDate,
    bool clearDialogPostponeDate = false,
    String? dialogPostponeTime,
    bool clearDialogPostponeTime = false,
    String? dialogPostponeReason,
    bool clearDialogPostponeReason = false,
    String? dialogCancelReason,
    bool clearDialogCancelReason = false,
    String? dialogCancelledBy,
  }) {
    return BookingsState(
      summaryStatus: summaryStatus ?? this.summaryStatus,
      bookingsStatus: bookingsStatus ?? this.bookingsStatus,
      detailsStatus: detailsStatus ?? this.detailsStatus,
      actionStatus: actionStatus ?? this.actionStatus,
      summary: summary ?? this.summary,
      bookings: bookings ?? this.bookings,
      pagination: pagination ?? this.pagination,
      customers: customers ?? this.customers,
      technicians: technicians ?? this.technicians,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      selectedDate:
          clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      selectedMonth:
          clearSelectedMonth ? null : (selectedMonth ?? this.selectedMonth),
      isMonthFilterActive: isMonthFilterActive ?? this.isMonthFilterActive,
      selectedStatus:
          clearSelectedStatus ? null : (selectedStatus ?? this.selectedStatus),
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      activeBookingTypeTab: activeBookingTypeTab ?? this.activeBookingTypeTab,
      selectedDayOfWeek: clearSelectedDayOfWeek
          ? null
          : (selectedDayOfWeek ?? this.selectedDayOfWeek),
      selectedBooking: clearSelectedBooking
          ? null
          : (selectedBooking ?? this.selectedBooking),
      formState: clearFormState ? null : (formState ?? this.formState),
      errMessage: errMessage,
      actionSuccessMessage: actionSuccessMessage,
      isDeleted: isDeleted ?? this.isDeleted,
      dialogStatus:
          clearDialogStatus ? null : (dialogStatus ?? this.dialogStatus),
      dialogTechnicianIds: dialogTechnicianIds ?? this.dialogTechnicianIds,
      dialogPostponeDate: clearDialogPostponeDate
          ? null
          : (dialogPostponeDate ?? this.dialogPostponeDate),
      dialogPostponeTime: clearDialogPostponeTime
          ? null
          : (dialogPostponeTime ?? this.dialogPostponeTime),
      dialogPostponeReason: clearDialogPostponeReason
          ? null
          : (dialogPostponeReason ?? this.dialogPostponeReason),
      dialogCancelReason: clearDialogCancelReason
          ? null
          : (dialogCancelReason ?? this.dialogCancelReason),
      dialogCancelledBy: dialogCancelledBy ?? this.dialogCancelledBy,
    );
  }

  @override
  List<Object?> get props => [
        summaryStatus,
        bookingsStatus,
        detailsStatus,
        actionStatus,
        summary,
        bookings,
        pagination,
        customers,
        technicians,
        selectedBranchId,
        selectedDate,
        selectedMonth,
        isMonthFilterActive,
        selectedStatus,
        searchQuery,
        currentPage,
        activeBookingTypeTab,
        selectedDayOfWeek,
        selectedBooking,
        formState,
        errMessage,
        actionSuccessMessage,
        isDeleted,
        dialogStatus,
        dialogTechnicianIds,
        dialogPostponeDate,
        dialogPostponeTime,
        dialogPostponeReason,
        dialogCancelReason,
        dialogCancelledBy,
      ];
}

