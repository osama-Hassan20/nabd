import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_form_options_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/presentation/widgets/action_dialogs/change_booking_status_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/action_dialogs/delete_booking_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/action_dialogs/reassign_technician_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_card.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_type_tab_bar.dart';
import 'package:eyadty/features/bookings/presentation/widgets/bookings_table.dart';
import 'package:eyadty/features/bookings/presentation/widgets/recurring_booking_card.dart';
import 'package:eyadty/features/bookings/presentation/widgets/recurring_bookings_table.dart';
import 'package:eyadty/features/customers/presentation/manager/customers_cubit.dart';
import 'package:eyadty/features/customers/presentation/manager/customers_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_tab_bar.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class CustomerBookingsSection extends StatefulWidget {
  const CustomerBookingsSection({super.key});

  @override
  State<CustomerBookingsSection> createState() =>
      _CustomerBookingsSectionState();
}

class _CustomerBookingsSectionState extends State<CustomerBookingsSection>
    with TickerProviderStateMixin {
  late final TabController _oneTimeTabController;
  late final TabController _recurringTabController;

  static const List<BookingStatusEnum?> _oneTimeTabStatuses = [
    null,
    BookingStatusEnum.scheduled,
    BookingStatusEnum.completed,
    BookingStatusEnum.cancelled,
  ];

  static const List<String> _recurringSubFilters = [
    'all',
    'ongoing',
    'ended',
  ];

  @override
  void initState() {
    super.initState();
    _oneTimeTabController = TabController(length: 4, vsync: this);
    _oneTimeTabController.addListener(_onOneTimeTabChanged);

    _recurringTabController = TabController(length: 3, vsync: this);
    _recurringTabController.addListener(_onRecurringTabChanged);
  }

  void _onOneTimeTabChanged() {
    if (_oneTimeTabController.indexIsChanging) return;
    final cubit = context.read<CustomersCubit>();
    final status = _oneTimeTabStatuses[_oneTimeTabController.index];
    cubit.filterCustomerBookingsByStatus(status);
  }

  void _onRecurringTabChanged() {
    if (_recurringTabController.indexIsChanging) return;
    final cubit = context.read<CustomersCubit>();
    final subFilter = _recurringSubFilters[_recurringTabController.index];
    cubit.filterRecurringSubStatus(subFilter);
  }

  @override
  void dispose() {
    _oneTimeTabController.removeListener(_onOneTimeTabChanged);
    _oneTimeTabController.dispose();
    _recurringTabController.removeListener(_onRecurringTabChanged);
    _recurringTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomersCubit>();

    return BlocBuilder<CustomersCubit, CustomersState>(
      buildWhen: (prev, curr) =>
          prev.filteredCustomerBookings != curr.filteredCustomerBookings ||
          prev.selectedBookingStatusFilter !=
              curr.selectedBookingStatusFilter ||
          prev.activeCustomerBookingTypeTab !=
              curr.activeCustomerBookingTypeTab ||
          prev.recurringStatusSubFilter != curr.recurringStatusSubFilter ||
          prev.customerBookingSearchQuery !=
              curr.customerBookingSearchQuery ||
          prev.customerOneTimeBookingsCount !=
              curr.customerOneTimeBookingsCount ||
          prev.customerActiveRecurringCount !=
              curr.customerActiveRecurringCount ||
          prev.customerEndedRecurringCount !=
              curr.customerEndedRecurringCount ||
          prev.actionStatus != curr.actionStatus,
      builder: (context, state) {
        final isRecurring =
            state.activeCustomerBookingTypeTab == BookingTypeEnum.recurring;

        return CustomContainer(
          backGroundColor: AppColors.lightBackground,
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grayE2E8F0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header & Booking Type Switcher ───────────────────
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CustomAssetImage(
                        path: AppIcons.calendar,
                        width: 20,
                        height: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'customer_bookings'.tr(),
                        style: CustomAppFontStyle.bold16.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                  BookingTypeTabBar(
                    activeTab: state.activeCustomerBookingTypeTab,
                    oneTimeBadgeCount: state.customerOneTimeBookingsCount,
                    recurringBadgeCount: state.customerActiveRecurringCount +
                        state.customerEndedRecurringCount,
                    onTabChanged: (type) {
                      cubit.switchCustomerBookingTypeTab(type);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Sub-Status Filter Tabs ───────────────────────────
              if (!isRecurring)
                CustomTabBar(
                  controller: _oneTimeTabController,
                  tabs: [
                    'all'.tr(),
                    'status_scheduled'.tr(),
                    'status_completed'.tr(),
                    'status_cancelled'.tr(),
                  ],
                )
              else
                CustomTabBar(
                  controller: _recurringTabController,
                  tabs: [
                    '${'all_recurring'.tr()} (${state.customerActiveRecurringCount + state.customerEndedRecurringCount})',
                    '${'ongoing_recurring_tab'.tr()} (${state.customerActiveRecurringCount})',
                    '${'ended_recurring_tab'.tr()} (${state.customerEndedRecurringCount})',
                  ],
                ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 16),

              // ─── Adaptive Bookings View (One-Time vs. Recurring) ───
              if (state.filteredCustomerBookings.isEmpty)
                _EmptyCustomerBookingsPlaceholder(
                  hasFilters: (!isRecurring &&
                          state.selectedBookingStatusFilter != null) ||
                      (isRecurring &&
                          state.recurringStatusSubFilter != 'all') ||
                      state.customerBookingSearchQuery.isNotEmpty,
                  onReset: () {
                    cubit.customerBookingsSearchController.clear();
                    if (!isRecurring) {
                      _oneTimeTabController.animateTo(0);
                      cubit.filterCustomerBookingsByStatus(null);
                    } else {
                      _recurringTabController.animateTo(0);
                      cubit.filterRecurringSubStatus('all');
                    }
                  },
                )
              else if (isRecurring)
                AdaptiveLayout(
                  // 1. Desktop: RecurringBookingsTable
                  desktopLayout: (context) => RecurringBookingsTable(
                    bookings: state.filteredCustomerBookings,
                    onViewDetails: (b) => _onViewDetails(context, b),
                    onEdit: (b) => _onEditBooking(context, cubit, b),
                    onChangeStatus: (b) => _onChangeStatus(context, cubit, b),
                    onReassignTechnician: (b) =>
                        _onReassignTechnicians(context, cubit, b),
                    onDelete: (b) => _onDeleteBooking(context, cubit, b),
                  ),

                  // 2. Tablet: 2-Column Responsive Grid with RecurringBookingCard
                  tabletLayout: (context) => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredCustomerBookings.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 500,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 260,
                    ),
                    itemBuilder: (context, index) {
                      final item = state.filteredCustomerBookings[index];
                      return RecurringBookingCard(
                        booking: item,
                        onViewDetails: () => _onViewDetails(context, item),
                        onEdit: () => _onEditBooking(context, cubit, item),
                        onChangeStatus: () =>
                            _onChangeStatus(context, cubit, item),
                        onReassignTechnician: () =>
                            _onReassignTechnicians(context, cubit, item),
                        onDelete: () => _onDeleteBooking(context, cubit, item),
                      );
                    },
                  ),

                  // 3. Mobile: 1-Column Vertical List with RecurringBookingCard
                  mobileLayout: (context) => ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredCustomerBookings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = state.filteredCustomerBookings[index];
                      return RecurringBookingCard(
                        booking: item,
                        onViewDetails: () => _onViewDetails(context, item),
                        onEdit: () => _onEditBooking(context, cubit, item),
                        onChangeStatus: () =>
                            _onChangeStatus(context, cubit, item),
                        onReassignTechnician: () =>
                            _onReassignTechnicians(context, cubit, item),
                        onDelete: () => _onDeleteBooking(context, cubit, item),
                      );
                    },
                  ),
                )
              else
                AdaptiveLayout(
                  // 1. Desktop: Full BookingsTable
                  desktopLayout: (context) => BookingsTable(
                    bookings: state.filteredCustomerBookings,
                    onViewDetails: (b) => _onViewDetails(context, b),
                    onEdit: (b) => _onEditBooking(context, cubit, b),
                    onChangeStatus: (b) => _onChangeStatus(context, cubit, b),
                    onReassignTechnician: (b) =>
                        _onReassignTechnicians(context, cubit, b),
                    onDelete: (b) => _onDeleteBooking(context, cubit, b),
                  ),

                  // 2. Tablet: 2-Column Responsive Grid matching AdaptiveBookingsView
                  tabletLayout: (context) => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredCustomerBookings.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 500,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 230,
                    ),
                    itemBuilder: (context, index) {
                      final item = state.filteredCustomerBookings[index];
                      return BookingCard(
                        booking: item,
                        onViewDetails: () => _onViewDetails(context, item),
                        onEdit: () => _onEditBooking(context, cubit, item),
                        onChangeStatus: () =>
                            _onChangeStatus(context, cubit, item),
                        onReassignTechnician: () =>
                            _onReassignTechnicians(context, cubit, item),
                        onDelete: () => _onDeleteBooking(context, cubit, item),
                      );
                    },
                  ),

                  // 3. Mobile: 1-Column Vertical List matching AdaptiveBookingsView
                  mobileLayout: (context) => ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredCustomerBookings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = state.filteredCustomerBookings[index];
                      return BookingCard(
                        booking: item,
                        onViewDetails: () => _onViewDetails(context, item),
                        onEdit: () => _onEditBooking(context, cubit, item),
                        onChangeStatus: () =>
                            _onChangeStatus(context, cubit, item),
                        onReassignTechnician: () =>
                            _onReassignTechnicians(context, cubit, item),
                        onDelete: () => _onDeleteBooking(context, cubit, item),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _onViewDetails(BuildContext context, BookingModel booking) {
    if (booking.id != null) {
      context.go('${AppRouter.bookings}/${booking.id}');
    }
  }

  void _onEditBooking(
    BuildContext context,
    CustomersCubit cubit,
    BookingModel booking,
  ) async {
    await AddEditBookingDialog.show(context: context, booking: booking);
    if (cubit.state.selectedCustomer?.id != null) {
      cubit.fetchCustomerDetails(cubit.state.selectedCustomer!.id!);
    }
  }

  void _onChangeStatus(
    BuildContext context,
    CustomersCubit cubit,
    BookingModel booking,
  ) {
    cubit.initChangeStatusDialog(booking.status ?? BookingStatusEnum.scheduled);

    showDialog(
      context: context,
      builder: (dialogCtx) => BlocBuilder<CustomersCubit, CustomersState>(
        bloc: cubit,
        builder: (ctx, state) => ChangeBookingStatusDialog(
          selectedStatus: state.dialogStatus ?? BookingStatusEnum.scheduled,
          isLoading: false,
          onSelectStatus: (s) => cubit.selectStatusToChange(s),
          onConfirm: () async {
            final newStatus = state.dialogStatus;
            if (newStatus != null && booking.id != null) {
              Navigator.pop(dialogCtx);
              await cubit.changeBookingStatus(booking.id!, newStatus);
            }
          },
        ),
      ),
    );
  }

  void _onReassignTechnicians(
    BuildContext context,
    CustomersCubit cubit,
    BookingModel booking,
  ) {
    cubit.initReassignTechniciansDialog(booking.technicianIds);

    const availableTechs = [
      BookingTechnicianOption(id: 'TECH-01', name: 'أحمد الشافعي'),
      BookingTechnicianOption(id: 'TECH-02', name: 'عمر عبد العزيز'),
      BookingTechnicianOption(id: 'TECH-03', name: 'يوسف النجار'),
      BookingTechnicianOption(id: 'TECH-04', name: 'طارق السعيد'),
      BookingTechnicianOption(id: 'TECH-05', name: 'ماجد القاضي'),
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => BlocBuilder<CustomersCubit, CustomersState>(
        bloc: cubit,
        builder: (ctx, state) => ReassignTechnicianDialog(
          technicians: availableTechs,
          selectedIds: state.dialogTechnicianIds,
          isLoading: false,
          onToggleTechnician: (id) => cubit.toggleReassignTechnician(id),
          onConfirm: () async {
            if (booking.id == null) return;
            final selectedIds = state.dialogTechnicianIds.toList();
            final selectedNames = availableTechs
                .where((t) => selectedIds.contains(t.id))
                .map((t) => t.name)
                .toList();

            Navigator.pop(dialogCtx);
            await cubit.reassignTechnicians(
              booking.id!,
              selectedIds,
              selectedNames,
            );
          },
        ),
      ),
    );
  }

  void _onDeleteBooking(
    BuildContext context,
    CustomersCubit cubit,
    BookingModel booking,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => DeleteBookingDialog(
        isLoading: false,
        onDelete: () async {
          if (booking.id == null) return;
          Navigator.pop(dialogCtx);
          await cubit.deleteBooking(booking.id!);
        },
      ),
    );
  }
}

class _EmptyCustomerBookingsPlaceholder extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onReset;

  const _EmptyCustomerBookingsPlaceholder({
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      borderRadius: BorderRadius.circular(12),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.grayf2,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: SvgPicture.asset(
                AppIcons.calendar,
                colorFilter: ColorFilter.mode(
                  isDark ? AppColors.grayMuted : AppColors.gray71717A,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'no_customer_bookings'.tr(),
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
              const SizedBox(height: 14),
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
