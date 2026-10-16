import 'package:flutter/material.dart';
import 'package:eyadty/core/base/safe_cubit.dart';
import 'package:eyadty/core/mixins/search_mixin.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/bookings_response_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/change_booking_status_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/reassign_technician_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import '../../data/models/customer_model.dart';
import '../../domain/use_cases/add_customer_use_case.dart';
import '../../domain/use_cases/delete_customer_use_case.dart';
import '../../domain/use_cases/get_customer_by_id_use_case.dart';
import '../../domain/use_cases/get_customers_use_case.dart';
import '../../domain/use_cases/update_customer_use_case.dart';
import 'customers_state.dart';

class CustomersCubit extends SafeCubit<CustomersState> with SearchMixin {
  final GetCustomersUseCase getCustomersUseCase;
  final GetCustomerByIdUseCase getCustomerByIdUseCase;
  final AddCustomerUseCase addCustomerUseCase;
  final UpdateCustomerUseCase updateCustomerUseCase;
  final DeleteCustomerUseCase deleteCustomerUseCase;
  final GetBookingsUseCase getBookingsUseCase;
  final ChangeBookingStatusUseCase changeBookingStatusUseCase;
  final ReassignTechnicianUseCase reassignTechnicianUseCase;
  final DeleteBookingUseCase deleteBookingUseCase;

  CustomersCubit({
    required this.getCustomersUseCase,
    required this.getCustomerByIdUseCase,
    required this.addCustomerUseCase,
    required this.updateCustomerUseCase,
    required this.deleteCustomerUseCase,
    required this.getBookingsUseCase,
    required this.changeBookingStatusUseCase,
    required this.reassignTechnicianUseCase,
    required this.deleteBookingUseCase,
  }) : super(const CustomersState());

  PaginationParams paginationParams = PaginationParams(page: 1, limit: 10);
  final TextEditingController customerBookingsSearchController =
      TextEditingController();

  void init() {
    addSearchListener(() {
      fetchCustomers(resetPage: true);
    });
    customerBookingsSearchController.addListener(() {
      searchCustomerBookings(customerBookingsSearchController.text);
    });
    fetchCustomers();
  }

  @override
  Future<void> close() {
    customerBookingsSearchController.dispose();
    disposeSearch();
    return super.close();
  }

  // ─── Customers List Flow ──────────────────────────────────────────────────
  Future<void> fetchCustomers({bool resetPage = false}) async {
    if (resetPage) {
      paginationParams = paginationParams.copyWith(page: 1);
    }

    paginationParams = paginationParams.copyWith(
      filterList: [
        if (searchQuery.trim().isNotEmpty)
          FilterParam(key: 'search', value: searchQuery.trim()),
      ],
    );

    emit(state.copyWith(status: RequestStatusEnum.loading));

    final result = await getCustomersUseCase(paginationParams);

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
        ),
      ),
    );
  }

  void changePage(int newPage) {
    if (newPage < 1 || newPage > state.totalPages) return;
    paginationParams = paginationParams.copyWith(page: newPage);
    fetchCustomers();
  }

  void initCustomerForm(CustomerModel? customer) {
    if (customer != null) {
      emit(state.copyWith(
        formState: CustomerFormState(
          id: customer.id,
          name: customer.name ?? '',
          phone: customer.phone ?? '',
          address: customer.address ?? '',
        ),
      ));
    } else {
      emit(state.copyWith(
        formState: const CustomerFormState(),
      ));
    }
  }

  Future<bool> saveCustomer({
    required String name,
    required String phone,
    required String address,
  }) async {
    final form = state.formState;
    final isEditing = form?.id != null;

    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final customerModel = CustomerModel(
      id: form?.id,
      name: name.trim(),
      phone: phone.trim(),
      address: address.trim(),
    );

    final result = isEditing
        ? await updateCustomerUseCase(customerModel)
        : await addCustomerUseCase(customerModel);

    return result.fold(
      (failure) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          actionErrMessage: failure.errMessage,
        ));
        return false;
      },
      (saved) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.success,
          clearFormState: true,
          selectedCustomer: saved,
        ));
        fetchCustomers();
        return true;
      },
    );
  }

  Future<bool> deleteCustomer(String id) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await deleteCustomerUseCase(id);

    return result.fold(
      (failure) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          actionErrMessage: failure.errMessage,
        ));
        return false;
      },
      (msg) {
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        fetchCustomers();
        return true;
      },
    );
  }

  // ─── Customer Details Flow ────────────────────────────────────────────────
  Future<void> fetchCustomerDetails(String customerId) async {
    emit(
      state.copyWith(
        detailsStatus: RequestStatusEnum.loading,
      ),
    );

    final results = await Future.wait([
      getCustomerByIdUseCase(customerId),
      getBookingsUseCase(
        PaginationParams(
          limit: 100,
          filterList: [FilterParam(key: 'customerId', value: customerId)],
        ),
      ),
    ]);

    final customerResult = results[0];
    final bookingsResult = results[1];

    CustomerModel? customer;
    String? errMessage;

    customerResult.fold(
      (failure) => errMessage = failure.errMessage,
      (c) => customer = c as CustomerModel,
    );

    if (customer == null) {
      emit(
        state.copyWith(
          detailsStatus: RequestStatusEnum.failure,
          detailsErrMessage: errMessage ?? 'تعذر تحميل بيانات العميل',
        ),
      );
      return;
    }

    List<BookingModel> bookings = [];
    bookingsResult.fold(
      (_) => bookings = [],
      (resp) {
        if (resp is BookingsResponseModel) {
          bookings = resp.bookings ?? [];
        }
      },
    );

    // Calculate dynamic KPI metrics
    final totalBookings = bookings.length;
    final oneTimeBookings = bookings
        .where((b) => b.bookingType != BookingTypeEnum.recurring)
        .toList();
    final recurringBookings = bookings
        .where((b) => b.bookingType == BookingTypeEnum.recurring)
        .toList();

    final activeRecurringCount =
        recurringBookings.where(_isOngoingRecurring).length;
    final endedRecurringCount =
        recurringBookings.where((b) => !_isOngoingRecurring(b)).length;

    final upcomingBookings = bookings
        .where((b) => b.status == BookingStatusEnum.scheduled)
        .length;
    final completedBookings = bookings
        .where((b) => b.status == BookingStatusEnum.completed)
        .length;
    final totalSpent = bookings
        .where(
          (b) =>
              b.status == BookingStatusEnum.completed ||
              b.paymentStatus == PaymentStatusEnum.paid,
        )
        .fold<num>(0, (sum, b) => sum + (b.totalPrice ?? 0));

    final filtered = _applyCustomerBookingFilters(
      bookings: bookings,
      typeTab: state.activeCustomerBookingTypeTab,
      statusFilter: state.selectedBookingStatusFilter,
      recurringSubFilter: state.recurringStatusSubFilter,
      search: state.customerBookingSearchQuery,
    );

    emit(
      state.copyWith(
        detailsStatus: RequestStatusEnum.success,
        selectedCustomer: customer,
        customerBookings: bookings,
        filteredCustomerBookings: filtered,
        customerTotalBookingsCount: totalBookings,
        customerOneTimeBookingsCount: oneTimeBookings.length,
        customerActiveRecurringCount: activeRecurringCount,
        customerEndedRecurringCount: endedRecurringCount,
        customerUpcomingBookingsCount: upcomingBookings,
        customerCompletedBookingsCount: completedBookings,
        customerTotalSpentAmount: totalSpent,
      ),
    );
  }

  void switchCustomerBookingTypeTab(BookingTypeEnum type) {
    final filtered = _applyCustomerBookingFilters(
      bookings: state.customerBookings,
      typeTab: type,
      statusFilter: state.selectedBookingStatusFilter,
      recurringSubFilter: state.recurringStatusSubFilter,
      search: state.customerBookingSearchQuery,
    );
    emit(
      state.copyWith(
        activeCustomerBookingTypeTab: type,
        filteredCustomerBookings: filtered,
      ),
    );
  }

  void filterRecurringSubStatus(String subFilter) {
    final filtered = _applyCustomerBookingFilters(
      bookings: state.customerBookings,
      typeTab: state.activeCustomerBookingTypeTab,
      statusFilter: state.selectedBookingStatusFilter,
      recurringSubFilter: subFilter,
      search: state.customerBookingSearchQuery,
    );
    emit(
      state.copyWith(
        recurringStatusSubFilter: subFilter,
        filteredCustomerBookings: filtered,
      ),
    );
  }

  void filterCustomerBookingsByStatus(BookingStatusEnum? status) {
    final filtered = _applyCustomerBookingFilters(
      bookings: state.customerBookings,
      typeTab: state.activeCustomerBookingTypeTab,
      statusFilter: status,
      recurringSubFilter: state.recurringStatusSubFilter,
      search: state.customerBookingSearchQuery,
    );

    emit(
      state.copyWith(
        selectedBookingStatusFilter: status,
        clearBookingStatusFilter: status == null,
        filteredCustomerBookings: filtered,
      ),
    );
  }

  void searchCustomerBookings(String query) {
    final filtered = _applyCustomerBookingFilters(
      bookings: state.customerBookings,
      typeTab: state.activeCustomerBookingTypeTab,
      statusFilter: state.selectedBookingStatusFilter,
      recurringSubFilter: state.recurringStatusSubFilter,
      search: query,
    );

    emit(
      state.copyWith(
        customerBookingSearchQuery: query,
        filteredCustomerBookings: filtered,
      ),
    );
  }

  List<BookingModel> _applyCustomerBookingFilters({
    required List<BookingModel> bookings,
    BookingTypeEnum? typeTab,
    BookingStatusEnum? statusFilter,
    String? recurringSubFilter,
    required String search,
  }) {
    final tab = typeTab ?? state.activeCustomerBookingTypeTab;
    final subFilter = recurringSubFilter ?? state.recurringStatusSubFilter;
    final status = statusFilter;

    List<BookingModel> list = bookings.where((b) {
      if (tab == BookingTypeEnum.recurring) {
        return b.bookingType == BookingTypeEnum.recurring;
      } else {
        return b.bookingType != BookingTypeEnum.recurring;
      }
    }).toList();

    if (tab == BookingTypeEnum.recurring) {
      if (subFilter == 'ongoing') {
        list = list.where(_isOngoingRecurring).toList();
      } else if (subFilter == 'ended') {
        list = list.where((b) => !_isOngoingRecurring(b)).toList();
      }
    } else {
      if (status != null) {
        list = list.where((b) => b.status == status).toList();
      }
    }

    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((b) {
        final service = b.serviceName?.toLowerCase() ?? '';
        final tech =
            b.technicians.map((t) => t.name ?? '').join(' ').toLowerCase();
        final id = b.id?.toLowerCase() ?? '';
        return service.contains(q) || tech.contains(q) || id.contains(q);
      }).toList();
    }

    return list;
  }

  bool _isOngoingRecurring(BookingModel b) {
    if (b.status == BookingStatusEnum.cancelled ||
        b.status == BookingStatusEnum.completed) {
      return false;
    }
    final rec = b.recurrence;
    if (rec == null) return true;
    if (rec.isOngoing) return true;
    if (rec.endDate != null) {
      return rec.endDate!.isAfter(DateTime.now());
    }
    return true;
  }

  // ─── Status Dialog ────────────────────────────────────────────────────────
  void initChangeStatusDialog(BookingStatusEnum current) {
    emit(state.copyWith(dialogStatus: current));
  }

  void selectStatusToChange(BookingStatusEnum status) {
    emit(state.copyWith(dialogStatus: status));
  }

  Future<bool> changeBookingStatus(
    String bookingId,
    BookingStatusEnum newStatus,
  ) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await changeBookingStatusUseCase(
      ChangeBookingStatusParams(bookingId: bookingId, newStatus: newStatus),
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            actionErrMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (_) {
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        if (state.selectedCustomer?.id != null) {
          fetchCustomerDetails(state.selectedCustomer!.id!);
        }
        return true;
      },
    );
  }

  // ─── Reassign Technicians Dialog ──────────────────────────────────────────
  void initReassignTechniciansDialog(List<String> currentIds) {
    emit(state.copyWith(dialogTechnicianIds: currentIds.toSet()));
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
            actionErrMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (_) {
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        if (state.selectedCustomer?.id != null) {
          fetchCustomerDetails(state.selectedCustomer!.id!);
        }
        return true;
      },
    );
  }

  // ─── Delete Booking ───────────────────────────────────────────────────────
  Future<bool> deleteBooking(String bookingId) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await deleteBookingUseCase(bookingId);

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            actionErrMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (_) {
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        if (state.selectedCustomer?.id != null) {
          fetchCustomerDetails(state.selectedCustomer!.id!);
        }
        return true;
      },
    );
  }
}
