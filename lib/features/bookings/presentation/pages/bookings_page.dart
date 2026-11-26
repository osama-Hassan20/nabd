import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/layout_adaptive/widgets/pagination_table.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/features/bookings/presentation/widgets/adaptive_bookings_view.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_action_dialogs.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_filter_bar.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_summary_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_type_tab_bar.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_cubit.dart';
import 'package:eyadty/features/cashier/presentation/widgets/dialogs/collect_payment_dialog.dart';
import 'package:eyadty/features/visits/presentation/manager/visits_cubit.dart';
import 'package:eyadty/features/visits/domain/repo/visits_repo.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingsCubit>(
      create: (context) => getIt<BookingsCubit>()..init(),
      child: const _BookingsPageView(),
    );
  }
}

class _BookingsPageView extends StatelessWidget {
  const _BookingsPageView();

  void _onAddNewBooking(BuildContext context) {
    AddEditBookingDialog.show(context: context);
  }

  void _onViewDetails(BuildContext context, BookingModel booking) {
    final id = booking.id;
    if (id != null && id.isNotEmpty) {
      context.go('${AppRouter.bookings}/$id');
    }
  }

  void _onEditBooking(BuildContext context, BookingModel booking) {
    AddEditBookingDialog.show(context: context, booking: booking);
  }

  void _onChangeStatus(BuildContext context, BookingModel booking) {
    BookingActionDialogs.showChangeStatusDialog(
      context: context,
      booking: booking,
    );
  }

  void _onReassignTechnician(BuildContext context, BookingModel booking) {
    BookingActionDialogs.showReassignTechnicianDialog(
      context: context,
      booking: booking,
    );
  }

  void _onDeleteBooking(BuildContext context, BookingModel booking) {
    BookingActionDialogs.showDeleteDialog(
      context: context,
      booking: booking,
    );
  }

  void _onCallPatient(BuildContext context, BookingModel booking) {
    final cubit = context.read<BookingsCubit>();
    cubit.changeBookingStatus(
      booking.id ?? '',
      BookingStatusEnum.inConsultation,
    );
    CustomToast(
      context: context,
      header: 'call_patient_success'.tr(),
    ).showTopToast();
  }

  void _onCollectPayment(BuildContext context, BookingModel booking) {
    final cashierCubit = getIt<CashierCubit>();
    final session = getIt<SessionCubit>().state;
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cashierCubit,
        child: CollectPaymentDialog(
          bookingId: booking.id ?? '',
          patientId: booking.patientId ?? booking.customer?.id ?? '',
          patientName: booking.patientName ?? booking.customer?.name ?? '',
          totalPrice: booking.consultationFee ?? 0,
          paidAmount: booking.paidAmount ?? 0,
          shiftId: cashierCubit.state.activeShift?.id,
          branchId: session.activeBranchId,
          cashierCubit: cashierCubit,
        ),
      ),
    );
  }

  void _onStartConsultation(BuildContext context, BookingModel booking) async {
    final visitsCubit = getIt<VisitsCubit>();
    final visitsRepo = getIt<VisitsRepo>();

    // 1. Check if visit already exists
    final bookingId = booking.id ?? '';
    final existingRes =
        await visitsRepo.getVisitByBookingId(bookingId: bookingId);
    final existingVisit = existingRes.fold((_) => null, (v) => v);

    if (existingVisit != null) {
      if (context.mounted) {
        context.go('${AppRouter.visits}/${existingVisit.id}');
      }
      return;
    }

    // 2. Otherwise start consultation
    final started = await visitsCubit.startConsultationForBooking(booking);
    if (started != null && context.mounted) {
      context.go('${AppRouter.visits}/${started.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();
    final colors = context.themeColors;

    final horizontalPadding = AdaptiveLayout.getResponsiveValue(
      context: context,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 24.0,
    );

    return BlocListener<BookingsCubit, BookingsState>(
      listenWhen: (prev, curr) =>
          (prev.errMessage != curr.errMessage && curr.errMessage != null) ||
          (prev.actionSuccessMessage != curr.actionSuccessMessage &&
              curr.actionSuccessMessage != null),
      listener: (context, state) {
        if (state.errMessage != null) {
          CustomToast(
            context: context,
            header: state.errMessage!.tr(),
          ).showErrorToast();
        } else if (state.actionSuccessMessage != null) {
          CustomToast(
            context: context,
            header: state.actionSuccessMessage!.tr(),
          ).showTopToast();
        }
      },
      child: Scaffold(
        backgroundColor: colors.scaffoldBackground,
        body: Column(
          children: [
            // Scrollable Content
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const BookingSummarySection(),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Clinical Visit Type Tab Bar (New, Revisit, Emergency)
                  SliverToBoxAdapter(
                    child: BlocBuilder<BookingsCubit, BookingsState>(
                      buildWhen: (prev, curr) =>
                          prev.activeBookingTypeTab !=
                          curr.activeBookingTypeTab,
                      builder: (context, state) {
                        return BookingTypeTabBar(
                          activeTab: state.activeBookingTypeTab,
                          onTabChanged: cubit.switchBookingTypeTab,
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  SliverToBoxAdapter(
                    child: BookingFilterBar(
                      onAddNewBooking: () => _onAddNewBooking(context),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: AdaptiveBookingsView(
                      onViewDetails: (b) => _onViewDetails(context, b),
                      onEdit: (b) => _onEditBooking(context, b),
                      onChangeStatus: (b) => _onChangeStatus(context, b),
                      onReassignTechnician: (b) =>
                          _onReassignTechnician(context, b),
                      onDelete: (b) => _onDeleteBooking(context, b),
                      onCallPatient: (b) => _onCallPatient(context, b),
                      onStartConsultation: (b) =>
                          _onStartConsultation(context, b),
                      onCollectPayment: (b) => _onCollectPayment(context, b),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),

            // Persistent Sticky Bottom Pagination Navigation
            BlocBuilder<BookingsCubit, BookingsState>(
              buildWhen: (prev, curr) =>
                  prev.currentPage != curr.currentPage ||
                  prev.pagination != curr.pagination,
              builder: (context, state) {
                final totalPages = state.pagination?.pages ?? 1;

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    border: Border(
                      top: BorderSide(color: colors.borderSubtle, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.04),
                        offset: const Offset(0, -2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomPaginationTable(
                        currentPage: state.currentPage,
                        pagesCount: totalPages,
                        onTapNext: () =>
                            cubit.onPageChanged(state.currentPage + 1),
                        onTapPrevious: () =>
                            cubit.onPageChanged(state.currentPage - 1),
                        onTapNumber: (page) => cubit.onPageChanged(page),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
