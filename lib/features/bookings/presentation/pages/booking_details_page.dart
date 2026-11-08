import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_action_dialogs.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_details_shimmer.dart';
import 'package:eyadty/features/bookings/presentation/widgets/details_sections/booking_details_patient_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/details_sections/booking_details_notes_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/details_sections/booking_details_pricing_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/details_sections/booking_details_schedule_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/details_sections/booking_details_technicians_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/details_sections/booking_details_top_bar.dart';
import 'package:eyadty/shared/widgets/custom_empty_widget.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/error_page.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class BookingDetailsPage extends StatelessWidget {
  final String bookingId;
  final BookingsCubit? bookingsCubit;

  const BookingDetailsPage({
    super.key,
    required this.bookingId,
    this.bookingsCubit,
  });

  @override
  Widget build(BuildContext context) {
    if (bookingsCubit != null) {
      return BlocProvider.value(
        value: bookingsCubit!..getBookingDetails(bookingId),
        child: Scaffold(body: const _BookingDetailsView()),
      );
    }

    return BlocProvider<BookingsCubit>(
      create: (context) => getIt<BookingsCubit>()..getBookingDetails(bookingId),
      child: Scaffold(body: const _BookingDetailsView()),
    );
  }
}

class _BookingDetailsView extends StatelessWidget {
  const _BookingDetailsView();

  void _onEdit(BuildContext context, BookingModel booking) {
    AddEditBookingDialog.show(
      context: context,
      booking: booking,
      bookingsCubit: context.read<BookingsCubit>(),
    );
  }

  void _onChangeStatus(BuildContext context, BookingModel booking) {
    BookingActionDialogs.showChangeStatusDialog(
      context: context,
      booking: booking,
      bookingsCubit: context.read<BookingsCubit>(),
    );
  }

  void _onReassignTechnician(BuildContext context, BookingModel booking) {
    BookingActionDialogs.showReassignTechnicianDialog(
      context: context,
      booking: booking,
      bookingsCubit: context.read<BookingsCubit>(),
    );
  }

  void _onDelete(BuildContext context, BookingModel booking) async {
    final deleted = await BookingActionDialogs.showDeleteDialog(
      context: context,
      booking: booking,
      bookingsCubit: context.read<BookingsCubit>(),
    );
    if (deleted == true && context.mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRouter.bookings);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();
    final horizontalPadding = AdaptiveLayout.getResponsiveValue(
      context: context,
      mobile: 4.0,
      tablet: 16.0,
      desktop: 24.0,
    );
    final isDesktop = AdaptiveLayout.isDesktop(context);

    return BlocConsumer<BookingsCubit, BookingsState>(
      listenWhen: (prev, curr) =>
          prev.errMessage != curr.errMessage ||
          prev.actionSuccessMessage != curr.actionSuccessMessage ||
          prev.isDeleted != curr.isDeleted,
      listener: (context, state) {
        if (state.isDeleted) {
          CustomToast(
            context: context,
            header:
                (state.actionSuccessMessage ?? 'booking_deleted_successfully')
                    .tr(),
          ).showTopToast();
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRouter.bookings);
          }
          return;
        }

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
      builder: (context, state) {
        // Loading State (Shimmer Skeleton)
        if (state.detailsStatus == RequestStatusEnum.loading) {
          return const BookingDetailsShimmer();
        }

        // Failure State (Independent Retry)
        if (state.detailsStatus == RequestStatusEnum.failure) {
          return Center(
            child: ErrorPage(
              errorMessage: state.errMessage ?? 'failed_to_load'.tr(),
              onPressed: () => cubit.refreshBookingDetails(),
            ),
          );
        }

        // Empty / Not Found State
        final booking = state.booking;
        if (state.detailsStatus == RequestStatusEnum.empty || booking == null) {
          return Center(
            child: CustomEmptyWidget(title: 'booking_not_found'.tr()),
          );
        }

        final hasNotes =
            booking.notes != null && booking.notes!.trim().isNotEmpty;

        return RefreshIndicator(
          onRefresh: () => cubit.refreshBookingDetails(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 5,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Navigation Bar & Action Bar
                BookingDetailsTopBar(
                  booking: booking,
                  onEdit: () => _onEdit(context, booking),
                  onChangeStatus: () => _onChangeStatus(context, booking),
                  onReassign: () => _onReassignTechnician(context, booking),
                  onDelete: () => _onDelete(context, booking),
                ),
                const SizedBox(height: 20),

                // Responsive Sections Layout
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left / Main Column (Flex 3)
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            BookingDetailsPatientSection(booking: booking),
                            const SizedBox(height: 16),
                            BookingDetailsScheduleSection(booking: booking),
                            if (hasNotes) ...[
                              const SizedBox(height: 16),
                              BookingDetailsNotesSection(notes: booking.notes!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Right / Sidebar Column (Flex 2)
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            BookingDetailsPricingSection(booking: booking),
                            const SizedBox(height: 16),
                            BookingDetailsTechniciansSection(
                              booking: booking,
                              onReassign: () =>
                                  _onReassignTechnician(context, booking),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  // Tablet & Mobile Stacked Column
                  Column(
                    children: [
                      BookingDetailsPatientSection(booking: booking),
                      const SizedBox(height: 16),
                      BookingDetailsScheduleSection(booking: booking),
                      const SizedBox(height: 16),
                      BookingDetailsPricingSection(booking: booking),
                      const SizedBox(height: 16),
                      BookingDetailsTechniciansSection(
                        booking: booking,
                        onReassign: () =>
                            _onReassignTechnician(context, booking),
                      ),
                      if (hasNotes) ...[
                        const SizedBox(height: 16),
                        BookingDetailsNotesSection(notes: booking.notes!),
                      ],
                    ],
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
