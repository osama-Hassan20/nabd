import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_calendar_widget.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_card.dart';
import 'package:eyadty/features/bookings/presentation/widgets/bookings_table.dart';
import 'package:eyadty/features/bookings/presentation/widgets/compact_date_strip_widget.dart';
import 'package:eyadty/features/bookings/presentation/widgets/recurring_booking_card.dart';
import 'package:eyadty/features/bookings/presentation/widgets/recurring_bookings_table.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/shimmer/custom_shimmer_container.dart';

class AdaptiveBookingsView extends StatelessWidget {
  final void Function(BookingModel booking)? onViewDetails;
  final void Function(BookingModel booking) onEdit;
  final void Function(BookingModel booking) onChangeStatus;
  final void Function(BookingModel booking) onReassignTechnician;
  final void Function(BookingModel booking) onDelete;
  final void Function(BookingModel booking)? onCallPatient;

  const AdaptiveBookingsView({
    super.key,
    this.onViewDetails,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onReassignTechnician,
    required this.onDelete,
    this.onCallPatient,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();

    return BlocBuilder<BookingsCubit, BookingsState>(
      buildWhen: (prev, curr) =>
          prev.bookingsStatus != curr.bookingsStatus ||
          prev.bookings != curr.bookings ||
          prev.selectedDate != curr.selectedDate ||
          prev.activeBookingTypeTab != curr.activeBookingTypeTab ||
          prev.selectedDayOfWeek != curr.selectedDayOfWeek,
      builder: (context, state) {
        final isRecurring =
            state.activeBookingTypeTab == BookingTypeEnum.recurring;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1000;
            final isTablet =
                constraints.maxWidth >= 700 && constraints.maxWidth < 1000;

            // 1. Loading State
            if (state.bookingsStatus == RequestStatusEnum.loading &&
                state.bookings.isEmpty) {
              if (isDesktop) {
                if (isRecurring) {
                  return CustomTableShimmer(
                    headers: [
                      '#',
                      'customer_label'.tr(),
                      'service_label'.tr(),
                      'technician_label'.tr(),
                      'recurring_days_schedule'.tr(),
                      'subscription_period'.tr(),
                      'price_label'.tr(),
                      'status_label'.tr(),
                      'actions_label'.tr(),
                    ],
                    columnWidths: RecurringBookingsTable.columnWidths,
                    rowCount: 6,
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 320,
                      child: CustomShimmerContainer(
                        height: 380,
                        width: 320,
                        borderRadius: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTableShimmer(
                        headers: [
                          '#',
                          'customer_label'.tr(),
                          'service_label'.tr(),
                          'technician_label'.tr(),
                          'date_and_time_label'.tr(),
                          'price_label'.tr(),
                          'status_label'.tr(),
                          'actions_label'.tr(),
                        ],
                        columnWidths: BookingsTable.columnWidths,
                        rowCount: 6,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  if (!isRecurring) ...[
                    const CustomShimmerContainer(
                      height: 72,
                      width: double.infinity,
                      borderRadius: 10,
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...List.generate(
                    4,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: CustomShimmerContainer(
                        height: 160,
                        width: double.infinity,
                        borderRadius: 12,
                      ),
                    ),
                  ),
                ],
              );
            }

            // 2. Empty State
            if (state.bookingsStatus == RequestStatusEnum.empty ||
                state.bookings.isEmpty) {
              final emptyWidget = _EmptyBookingsPlaceholder(
                hasFilters: state.selectedDate != null ||
                    state.selectedStatus != null ||
                    state.searchQuery.isNotEmpty ||
                    state.selectedDayOfWeek != null,
                onReset: () {
                  cubit.searchController.clear();
                  cubit.clearDateFilter();
                  cubit.onStatusFilterChanged(null);
                  cubit.onDayOfWeekFilterChanged(null);
                },
              );

              if (isRecurring) {
                return emptyWidget;
              }

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 320,
                      child: BookingCalendarWidget(
                        selectedDate: state.selectedDate,
                        onDateSelected: cubit.onDateSelected,
                        onYearSelected: cubit.setCalendarYear,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: emptyWidget),
                  ],
                );
              }

              return Column(
                children: [
                  CompactDateStripWidget(
                    selectedDate: state.selectedDate,
                    selectedMonth: state.selectedMonth,
                    isMonthFilterActive: state.isMonthFilterActive,
                    onDateSelected: cubit.onDateSelected,
                    onMonthSelected: cubit.onMonthSelected,
                    onYearSelected: cubit.setCalendarYear,
                    onNextMonth: cubit.nextCalendarMonth,
                    onPrevMonth: cubit.previousCalendarMonth,
                    onNextDay: cubit.nextCalendarDay,
                    onPrevDay: cubit.previousCalendarDay,
                    onGoToToday: cubit.goToToday,
                    onClearFilter: cubit.clearDateFilter,
                  ),
                  const SizedBox(height: 16),
                  emptyWidget,
                ],
              );
            }

            // 3. Desktop Layout
            if (isDesktop) {
              if (isRecurring) {
                return RecurringBookingsTable(
                  bookings: state.bookings,
                  onViewDetails: onViewDetails,
                  onEdit: onEdit,
                  onChangeStatus: onChangeStatus,
                  onReassignTechnician: onReassignTechnician,
                  onDelete: onDelete,
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 320,
                    child: BookingCalendarWidget(
                      selectedDate: state.selectedDate,
                      onDateSelected: cubit.onDateSelected,
                      onYearSelected: cubit.setCalendarYear,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BookingsTable(
                      bookings: state.bookings,
                      onViewDetails: onViewDetails,
                      onEdit: onEdit,
                      onChangeStatus: onChangeStatus,
                      onReassignTechnician: onReassignTechnician,
                      onDelete: onDelete,
                      onCallPatient: onCallPatient,
                    ),
                  ),
                ],
              );
            }

            // 4. Tablet Layout: 2-Column Grid
            if (isTablet) {
              if (isRecurring) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.bookings.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 250,
                  ),
                  itemBuilder: (context, index) {
                    final item = state.bookings[index];
                    return RecurringBookingCard(
                      booking: item,
                      onViewDetails: onViewDetails != null
                          ? () => onViewDetails!(item)
                          : null,
                      onEdit: () => onEdit(item),
                      onChangeStatus: () => onChangeStatus(item),
                      onReassignTechnician: () =>
                          onReassignTechnician(item),
                      onDelete: () => onDelete(item),
                    );
                  },
                );
              }

              return Column(
                children: [
                  CompactDateStripWidget(
                    selectedDate: state.selectedDate,
                    selectedMonth: state.selectedMonth,
                    isMonthFilterActive: state.isMonthFilterActive,
                    onDateSelected: cubit.onDateSelected,
                    onMonthSelected: cubit.onMonthSelected,
                    onYearSelected: cubit.setCalendarYear,
                    onNextMonth: cubit.nextCalendarMonth,
                    onPrevMonth: cubit.previousCalendarMonth,
                    onNextDay: cubit.nextCalendarDay,
                    onPrevDay: cubit.previousCalendarDay,
                    onGoToToday: cubit.goToToday,
                    onClearFilter: cubit.clearDateFilter,
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.bookings.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 230,
                    ),
                    itemBuilder: (context, index) {
                      final item = state.bookings[index];
                      return BookingCard(
                        booking: item,
                        onViewDetails: onViewDetails != null
                            ? () => onViewDetails!(item)
                            : null,
                        onEdit: () => onEdit(item),
                        onChangeStatus: () => onChangeStatus(item),
                        onReassignTechnician: () =>
                            onReassignTechnician(item),
                        onDelete: () => onDelete(item),
                        onCallPatient: onCallPatient != null
                            ? () => onCallPatient!(item)
                            : null,
                      );
                    },
                  ),
                ],
              );
            }

            // 5. Mobile Layout: 1-Column List
            if (isRecurring) {
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.bookings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = state.bookings[index];
                  return RecurringBookingCard(
                    booking: item,
                    onViewDetails: onViewDetails != null
                        ? () => onViewDetails!(item)
                        : null,
                    onEdit: () => onEdit(item),
                    onChangeStatus: () => onChangeStatus(item),
                    onReassignTechnician: () =>
                        onReassignTechnician(item),
                    onDelete: () => onDelete(item),
                  );
                },
              );
            }

            return Column(
              children: [
                CompactDateStripWidget(
                  selectedDate: state.selectedDate,
                  selectedMonth: state.selectedMonth,
                  isMonthFilterActive: state.isMonthFilterActive,
                  onDateSelected: cubit.onDateSelected,
                  onMonthSelected: cubit.onMonthSelected,
                  onYearSelected: cubit.setCalendarYear,
                  onNextMonth: cubit.nextCalendarMonth,
                  onPrevMonth: cubit.previousCalendarMonth,
                  onNextDay: cubit.nextCalendarDay,
                  onPrevDay: cubit.previousCalendarDay,
                  onGoToToday: cubit.goToToday,
                  onClearFilter: cubit.clearDateFilter,
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.bookings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = state.bookings[index];
                    return BookingCard(
                      booking: item,
                      onViewDetails: onViewDetails != null
                          ? () => onViewDetails!(item)
                          : null,
                      onEdit: () => onEdit(item),
                      onChangeStatus: () => onChangeStatus(item),
                      onReassignTechnician: () =>
                          onReassignTechnician(item),
                      onDelete: () => onDelete(item),
                      onCallPatient: onCallPatient != null
                          ? () => onCallPatient!(item)
                          : null,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _EmptyBookingsPlaceholder extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onReset;

  const _EmptyBookingsPlaceholder({
    required this.hasFilters,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return CustomContainer(
      backGroundColor: isDark
          ? AppColors.darkBackground.withValues(alpha: .5)
          : AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      borderRaduis: 12,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.grayf2,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(18),
              child: SvgPicture.asset(
                AppIcons.calendar,
                colorFilter: ColorFilter.mode(
                  isDark ? AppColors.grayMuted : AppColors.gray71717A,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'no_bookings_found'.tr(),
              style: CustomAppFontStyle.semiBold16.copyWith(
                color: isDark ? AppColors.white : AppColors.darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'no_bookings_desc'.tr(),
              textAlign: TextAlign.center,
              style: CustomAppFontStyle.regular13.copyWith(
                color: isDark ? AppColors.grayMuted : AppColors.gray71717A,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onReset,
                child: Text(
                  'reset_filters'.tr(),
                  style: CustomAppFontStyle.medium14.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
