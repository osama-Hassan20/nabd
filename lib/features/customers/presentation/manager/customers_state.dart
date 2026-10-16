import 'package:equatable/equatable.dart';
import 'package:purexo/core/utils/enums/request_status_enum.dart';
import 'package:purexo/features/bookings/data/models/booking_model.dart';
import 'package:purexo/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:purexo/features/bookings/data/models/enums/booking_type_enum.dart';
import '../../data/models/customer_model.dart';

class CustomerFormState extends Equatable {
  final String? id;
  final String name;
  final String phone;
  final String address;

  const CustomerFormState({
    this.id,
    this.name = '',
    this.phone = '',
    this.address = '',
  });

  CustomerFormState copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    bool clearId = false,
  }) {
    return CustomerFormState(
      id: clearId ? null : (id ?? this.id),
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, address];
}

class CustomersState extends Equatable {
  final RequestStatusEnum status;
  final RequestStatusEnum actionStatus;
  final RequestStatusEnum detailsStatus;
  final List<CustomerModel> items;
  final CustomerModel? selectedCustomer;
  final String? errMessage;
  final String? actionErrMessage;
  final String? detailsErrMessage;
  final int totalPages;
  final int totalCount;
  final CustomerFormState? formState;

  // ─── Customer Details Bookings & KPI ─────────────────────────────
  final List<BookingModel> customerBookings;
  final List<BookingModel> filteredCustomerBookings;
  final BookingStatusEnum? selectedBookingStatusFilter;
  final String customerBookingSearchQuery;
  final BookingTypeEnum activeCustomerBookingTypeTab;
  final String recurringStatusSubFilter; // 'all', 'ongoing', 'ended'
  final int customerTotalBookingsCount;
  final int customerOneTimeBookingsCount;
  final int customerActiveRecurringCount;
  final int customerEndedRecurringCount;
  final int customerUpcomingBookingsCount;
  final int customerCompletedBookingsCount;
  final num customerTotalSpentAmount;
  final BookingStatusEnum? dialogStatus;
  final Set<String> dialogTechnicianIds;

  const CustomersState({
    this.status = RequestStatusEnum.initial,
    this.actionStatus = RequestStatusEnum.initial,
    this.detailsStatus = RequestStatusEnum.initial,
    this.items = const [],
    this.selectedCustomer,
    this.errMessage,
    this.actionErrMessage,
    this.detailsErrMessage,
    this.totalPages = 1,
    this.totalCount = 0,
    this.formState,
    this.customerBookings = const [],
    this.filteredCustomerBookings = const [],
    this.selectedBookingStatusFilter,
    this.customerBookingSearchQuery = '',
    this.activeCustomerBookingTypeTab = BookingTypeEnum.oneTime,
    this.recurringStatusSubFilter = 'all',
    this.customerTotalBookingsCount = 0,
    this.customerOneTimeBookingsCount = 0,
    this.customerActiveRecurringCount = 0,
    this.customerEndedRecurringCount = 0,
    this.customerUpcomingBookingsCount = 0,
    this.customerCompletedBookingsCount = 0,
    this.customerTotalSpentAmount = 0,
    this.dialogStatus,
    this.dialogTechnicianIds = const {},
  });

  CustomersState copyWith({
    RequestStatusEnum? status,
    RequestStatusEnum? actionStatus,
    RequestStatusEnum? detailsStatus,
    List<CustomerModel>? items,
    CustomerModel? selectedCustomer,
    String? errMessage,
    String? actionErrMessage,
    String? detailsErrMessage,
    int? totalPages,
    int? totalCount,
    CustomerFormState? formState,
    bool clearFormState = false,
    List<BookingModel>? customerBookings,
    List<BookingModel>? filteredCustomerBookings,
    BookingStatusEnum? selectedBookingStatusFilter,
    bool clearBookingStatusFilter = false,
    String? customerBookingSearchQuery,
    BookingTypeEnum? activeCustomerBookingTypeTab,
    String? recurringStatusSubFilter,
    int? customerTotalBookingsCount,
    int? customerOneTimeBookingsCount,
    int? customerActiveRecurringCount,
    int? customerEndedRecurringCount,
    int? customerUpcomingBookingsCount,
    int? customerCompletedBookingsCount,
    num? customerTotalSpentAmount,
    BookingStatusEnum? dialogStatus,
    Set<String>? dialogTechnicianIds,
  }) {
    return CustomersState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      detailsStatus: detailsStatus ?? this.detailsStatus,
      items: items ?? this.items,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      errMessage: errMessage ?? this.errMessage,
      actionErrMessage: actionErrMessage ?? this.actionErrMessage,
      detailsErrMessage: detailsErrMessage ?? this.detailsErrMessage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      formState: clearFormState ? null : (formState ?? this.formState),
      customerBookings: customerBookings ?? this.customerBookings,
      filteredCustomerBookings:
          filteredCustomerBookings ?? this.filteredCustomerBookings,
      selectedBookingStatusFilter: clearBookingStatusFilter
          ? null
          : (selectedBookingStatusFilter ?? this.selectedBookingStatusFilter),
      customerBookingSearchQuery:
          customerBookingSearchQuery ?? this.customerBookingSearchQuery,
      activeCustomerBookingTypeTab:
          activeCustomerBookingTypeTab ?? this.activeCustomerBookingTypeTab,
      recurringStatusSubFilter:
          recurringStatusSubFilter ?? this.recurringStatusSubFilter,
      customerTotalBookingsCount:
          customerTotalBookingsCount ?? this.customerTotalBookingsCount,
      customerOneTimeBookingsCount:
          customerOneTimeBookingsCount ?? this.customerOneTimeBookingsCount,
      customerActiveRecurringCount:
          customerActiveRecurringCount ?? this.customerActiveRecurringCount,
      customerEndedRecurringCount:
          customerEndedRecurringCount ?? this.customerEndedRecurringCount,
      customerUpcomingBookingsCount:
          customerUpcomingBookingsCount ?? this.customerUpcomingBookingsCount,
      customerCompletedBookingsCount:
          customerCompletedBookingsCount ?? this.customerCompletedBookingsCount,
      customerTotalSpentAmount:
          customerTotalSpentAmount ?? this.customerTotalSpentAmount,
      dialogStatus: dialogStatus ?? this.dialogStatus,
      dialogTechnicianIds: dialogTechnicianIds ?? this.dialogTechnicianIds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        detailsStatus,
        items,
        selectedCustomer,
        errMessage,
        actionErrMessage,
        detailsErrMessage,
        totalPages,
        totalCount,
        formState,
        customerBookings,
        filteredCustomerBookings,
        selectedBookingStatusFilter,
        customerBookingSearchQuery,
        activeCustomerBookingTypeTab,
        recurringStatusSubFilter,
        customerTotalBookingsCount,
        customerOneTimeBookingsCount,
        customerActiveRecurringCount,
        customerEndedRecurringCount,
        customerUpcomingBookingsCount,
        customerCompletedBookingsCount,
        customerTotalSpentAmount,
        dialogStatus,
        dialogTechnicianIds,
      ];
}
