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
import 'package:eyadty/features/bookings/presentation/widgets/action_dialogs/change_booking_status_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/action_dialogs/delete_booking_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/action_dialogs/reassign_doctor_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_card.dart';
import 'package:eyadty/features/bookings/presentation/widgets/bookings_table.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_tab_bar.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class DoctorBookingsSection extends StatefulWidget {
  const DoctorBookingsSection({super.key});

  @override
  State<DoctorBookingsSection> createState() =>
      _DoctorBookingsSectionState();
}

class _DoctorBookingsSectionState extends State<DoctorBookingsSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<BookingStatusEnum?> _tabStatuses = [
    null,
    BookingStatusEnum.scheduled,
    BookingStatusEnum.completed,
    BookingStatusEnum.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final cubit = context.read<DoctorsCubit>();
    final status = _tabStatuses[_tabController.index];
    cubit.filterDoctorBookingsByStatus(status);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DoctorsCubit>();

    return BlocBuilder<DoctorsCubit, DoctorsState>(
      buildWhen: (prev, curr) =>
          prev.doctorBookings != curr.doctorBookings ||
          prev.filteredDoctorBookings != curr.filteredDoctorBookings ||
          prev.selectedBookingStatusFilter !=
              curr.selectedBookingStatusFilter ||
          prev.actionStatus != curr.actionStatus,
      builder: (context, state) {
        final bookings = state.filteredDoctorBookings;

        return CustomContainer(
          backGroundColor: AppColors.lightBackground,
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grayE2E8F0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header: Bookings Count ───────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const CustomAssetImage(
                      path: AppIcons.totalOrders,
                      width: 18,
                      height: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'bookings'.tr(),
                    style: CustomAppFontStyle.semiBold16.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grayf2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${state.doctorBookings.length}',
                      style: CustomAppFontStyle.semiBold12.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Status Tabs via CustomTabBar ─────────────────────
              CustomTabBar(
                controller: _tabController,
                tabs: [
                  'all'.tr(),
                  'status_scheduled'.tr(),
                  'status_completed'.tr(),
                  'status_cancelled'.tr(),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 16),

              // ─── Adaptive Bookings View (Table / Grid / List) ─────
              if (bookings.isEmpty)
                _EmptyDoctorBookingsPlaceholder(
                  hasFilters: state.selectedBookingStatusFilter != null,
                  onReset: () {
                    _tabController.animateTo(0);
                    cubit.filterDoctorBookingsByStatus(null);
                  },
                )
              else
                AdaptiveLayout(
                  // 1. Desktop: Full BookingsTable
                  desktopLayout: (context) => BookingsTable(
                    bookings: bookings,
                    onViewDetails: (b) => _onViewDetails(context, b),
                    onEdit: (b) => _onEditBooking(context, cubit, b),
                    onChangeStatus: (b) => _onChangeStatus(context, cubit, b),
                    onReassignTechnician: (b) =>
                        _onReassignDoctors(context, cubit, b),
                    onDelete: (b) => _onDeleteBooking(context, cubit, b),
                  ),

                  // 2. Tablet: 2-Column Responsive Grid matching AdaptiveBookingsView
                  tabletLayout: (context) => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bookings.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 500,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 230,
                        ),
                    itemBuilder: (context, index) {
                      final item = bookings[index];
                      return BookingCard(
                        booking: item,
                        onViewDetails: () => _onViewDetails(context, item),
                        onEdit: () => _onEditBooking(context, cubit, item),
                        onChangeStatus: () =>
                            _onChangeStatus(context, cubit, item),
                        onReassignTechnician: () =>
                            _onReassignDoctors(context, cubit, item),
                        onDelete: () => _onDeleteBooking(context, cubit, item),
                      );
                    },
                  ),

                  // 3. Mobile: 1-Column Vertical List matching AdaptiveBookingsView
                  mobileLayout: (context) => ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bookings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = bookings[index];
                      return BookingCard(
                        booking: item,
                        onViewDetails: () => _onViewDetails(context, item),
                        onEdit: () => _onEditBooking(context, cubit, item),
                        onChangeStatus: () =>
                            _onChangeStatus(context, cubit, item),
                        onReassignTechnician: () =>
                            _onReassignDoctors(context, cubit, item),
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
    DoctorsCubit cubit,
    BookingModel booking,
  ) async {
    await AddEditBookingDialog.show(context: context, booking: booking);
    if (cubit.state.selectedDoctor?.id != null) {
      cubit.fetchDoctorDetails(cubit.state.selectedDoctor!.id!);
    }
  }

  void _onChangeStatus(
    BuildContext context,
    DoctorsCubit cubit,
    BookingModel booking,
  ) {
    cubit.initChangeStatusDialog(booking.status ?? BookingStatusEnum.scheduled);

    showDialog(
      context: context,
      builder: (dialogCtx) => BlocBuilder<DoctorsCubit, DoctorsState>(
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

  void _onReassignDoctors(
    BuildContext context,
    DoctorsCubit cubit,
    BookingModel booking,
  ) {
    cubit.initReassignDoctorsDialog(booking.technicianIds);

    const availableDoctors = [
      BookingDoctorOption(id: 'DOC-01', name: 'د. خالد عبد الرحمن (باطنة)'),
      BookingDoctorOption(id: 'DOC-02', name: 'د. سارة المنشاوي (أطفال)'),
      BookingDoctorOption(id: 'DOC-03', name: 'د. محمد إبراهيم (عظام)'),
      BookingDoctorOption(id: 'DOC-04', name: 'د. فاطمة الزهراء (جلدية)'),
      BookingDoctorOption(id: 'DOC-05', name: 'د. محمود حسن (أنف وأذن)'),
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => BlocBuilder<DoctorsCubit, DoctorsState>(
        bloc: cubit,
        builder: (ctx, state) => ReassignDoctorDialog(
          technicians: availableDoctors,
          selectedIds: state.dialogDoctorIds,
          isLoading: false,
          onToggleTechnician: (id) => cubit.toggleReassignDoctor(id),
          onConfirm: () async {
            if (booking.id == null) return;
            final selectedIds = state.dialogDoctorIds.toList();
            final selectedNames = availableDoctors
                .where((t) => selectedIds.contains(t.id))
                .map((t) => t.name)
                .toList();

            Navigator.pop(dialogCtx);
            await cubit.reassignDoctors(
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
    DoctorsCubit cubit,
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

class _EmptyDoctorBookingsPlaceholder extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onReset;

  const _EmptyDoctorBookingsPlaceholder({
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
              'no_data_found'.tr(),
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

