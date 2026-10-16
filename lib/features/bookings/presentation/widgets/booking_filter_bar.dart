import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:purexo/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:purexo/features/bookings/data/models/recurrence_rule_model.dart';
import 'package:purexo/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:purexo/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:purexo/features/bookings/presentation/manager/bookings_state.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:purexo/shared/widgets/custom_container.dart';
import 'package:purexo/shared/widgets/custom_push_container_button.dart';
import 'package:purexo/shared/widgets/custom_stack_selector.dart';
import 'package:purexo/shared/widgets/custom_text_field.dart';
import 'package:purexo/shared/widgets/responsive_helper/adaptive_layout.dart';

class BookingFilterBar extends StatelessWidget {
  final VoidCallback onAddNewBooking;

  const BookingFilterBar({super.key, required this.onAddNewBooking});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();

    return BlocBuilder<BookingsCubit, BookingsState>(
      buildWhen: (prev, curr) =>
          prev.selectedStatus != curr.selectedStatus ||
          prev.selectedDate != curr.selectedDate ||
          prev.activeBookingTypeTab != curr.activeBookingTypeTab ||
          prev.selectedDayOfWeek != curr.selectedDayOfWeek,
      builder: (context, state) {
        return AdaptiveLayout(
          mobileLayout: (context) => _buildMobileLayout(context, cubit, state),
          tabletLayout: (context) => _buildTabletLayout(context, cubit, state),
          desktopLayout: (context) =>
              _buildDesktopLayout(context, cubit, state),
        );
      },
    );
  }

  // ─── Desktop Layout (width >= 1000) ──────────────────────────────────────────
  Widget _buildDesktopLayout(
    BuildContext context,
    BookingsCubit cubit,
    BookingsState state,
  ) {
    return CustomContainer(
      backGroundColor: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRaduis: 12,
      child: Row(
        children: [
          // Search Field (Flex 3)
          Expanded(flex: 3, child: _buildSearchField(cubit)),
          const SizedBox(width: 12),

          // Status Dropdown
          SizedBox(
            width: 190,
            child: _StatusDropdown(
              selectedStatus: state.selectedStatus,
              onChanged: cubit.onStatusFilterChanged,
            ),
          ),

          // Recurring: Day of Week dropdown / OneTime: Date Filter Chip
          if (state.activeBookingTypeTab == BookingTypeEnum.recurring) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 180,
              child: _DayOfWeekDropdown(
                selectedDay: state.selectedDayOfWeek,
                onChanged: cubit.onDayOfWeekFilterChanged,
              ),
            ),
          ] else if (state.selectedDate != null) ...[
            const SizedBox(width: 12),
            _DateFilterChip(
              date: state.selectedDate!,
              onClear: cubit.clearDateFilter,
            ),
          ],

          const SizedBox(width: 12),

          // Add New Booking Button
          _AddBookingButton(onTap: onAddNewBooking, width: 170),
        ],
      ),
    );
  }

  // ─── Tablet Layout (700 < width < 1000) ──────────────────────────────────────
  Widget _buildTabletLayout(
    BuildContext context,
    BookingsCubit cubit,
    BookingsState state,
  ) {
    return CustomContainer(
      backGroundColor: AppColors.white,
      padding: const EdgeInsets.all(14),
      borderRaduis: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Search Field + Add Button
          Row(
            children: [
              Expanded(child: _buildSearchField(cubit)),
              const SizedBox(width: 12),
              _AddBookingButton(onTap: onAddNewBooking, width: 160),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Status Dropdown + (Day of Week dropdown OR Date Filter Chip)
          Row(
            children: [
              SizedBox(
                width: 200,
                child: _StatusDropdown(
                  selectedStatus: state.selectedStatus,
                  onChanged: cubit.onStatusFilterChanged,
                ),
              ),
              if (state.activeBookingTypeTab == BookingTypeEnum.recurring) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: _DayOfWeekDropdown(
                    selectedDay: state.selectedDayOfWeek,
                    onChanged: cubit.onDayOfWeekFilterChanged,
                  ),
                ),
              ] else if (state.selectedDate != null) ...[
                const SizedBox(width: 12),
                _DateFilterChip(
                  date: state.selectedDate!,
                  onClear: cubit.clearDateFilter,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Mobile Layout (width <= 700) ───────────────────────────────────────────
  Widget _buildMobileLayout(
    BuildContext context,
    BookingsCubit cubit,
    BookingsState state,
  ) {
    return CustomContainer(
      backGroundColor: AppColors.white,
      padding: const EdgeInsets.all(12),
      borderRaduis: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Field
          _buildSearchField(cubit),
          const SizedBox(height: 10),

          // Status Dropdown & Date / Day Filter row
          Row(
            children: [
              Expanded(
                child: _StatusDropdown(
                  selectedStatus: state.selectedStatus,
                  onChanged: cubit.onStatusFilterChanged,
                ),
              ),
              if (state.activeBookingTypeTab == BookingTypeEnum.recurring) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _DayOfWeekDropdown(
                    selectedDay: state.selectedDayOfWeek,
                    onChanged: cubit.onDayOfWeekFilterChanged,
                  ),
                ),
              ] else if (state.selectedDate != null) ...[
                const SizedBox(width: 8),
                _DateFilterChip(
                  date: state.selectedDate!,
                  onClear: cubit.clearDateFilter,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Add New Booking Button (Full Width on Mobile)
          _AddBookingButton(onTap: onAddNewBooking, isFullWidth: true),
        ],
      ),
    );
  }

  // ─── Shared Search Field Widget ─────────────────────────────────────────────
  Widget _buildSearchField(BookingsCubit cubit) {
    return CustomTextFormField(
      controller: cubit.searchController,
      hintText: 'search_bookings_hint'.tr(),
      prefixWidget: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: CustomAssetImage(
          path: AppIcons.search,
          width: 18,
          height: 18,
          color: AppColors.gray71717A,
        ),
      ),
      suffixWidget: cubit.searchController.text.isNotEmpty
          ? IconButton(
              icon: const CustomAssetImage(
                path: AppIcons.close,
                width: 14,
                height: 14,
                color: AppColors.gray71717A,
              ),
              onPressed: () {
                cubit.searchController.clear();
                cubit.fetchBookings(resetPage: true);
              },
            )
          : null,
    );
  }
}

class _StatusDropdown extends StatefulWidget {
  final BookingStatusEnum? selectedStatus;
  final ValueChanged<BookingStatusEnum?> onChanged;

  const _StatusDropdown({
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  State<_StatusDropdown> createState() => _StatusDropdownState();
}

class _StatusDropdownState extends State<_StatusDropdown> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.selectedStatus?.label ?? 'all_statuses'.tr(),
    );
  }

  @override
  void didUpdateWidget(_StatusDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedStatus != widget.selectedStatus) {
      _controller.text = widget.selectedStatus?.label ?? 'all_statuses'.tr();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = <BookingStatusEnum?>[null, ...BookingStatusEnum.values];
    return CustomStackSelector<BookingStatusEnum?>(
      controller: _controller,
      list: list,
      itemAsString: (s) => s?.label ?? 'all_statuses'.tr(),
      hintText: 'all_statuses'.tr(),
      changeValue: (s) => widget.onChanged(s),
    );
  }
}

class _DayOfWeekDropdown extends StatefulWidget {
  final String? selectedDay;
  final ValueChanged<String?> onChanged;

  const _DayOfWeekDropdown({
    required this.selectedDay,
    required this.onChanged,
  });

  @override
  State<_DayOfWeekDropdown> createState() => _DayOfWeekDropdownState();
}

class _DayOfWeekDropdownState extends State<_DayOfWeekDropdown> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didUpdateWidget(_DayOfWeekDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay) {
      if (widget.selectedDay == null) {
        _controller.text = 'all_days'.tr();
      } else {
        _controller.text =
            DayOfWeekOption.fromKey(widget.selectedDay!).getName(context);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = <DayOfWeekOption?>[null, ...DayOfWeekOption.all];
    return CustomStackSelector<DayOfWeekOption?>(
      controller: _controller,
      list: list,
      itemAsString: (d) => d?.getName(context) ?? 'all_days'.tr(),
      hintText: 'filter_by_day'.tr(),
      changeValue: (d) => widget.onChanged(d?.key),
    );
  }
}

class _DateFilterChip extends StatelessWidget {
  final DateTime date;
  final VoidCallback onClear;

  const _DateFilterChip({required this.date, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final formattedDate = BookingTimeFormatter.formatCompactDate(date, context);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CustomAssetImage(
            path: AppIcons.calendar,
            width: 16,
            height: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            formattedDate,
            style: CustomAppFontStyle.medium12.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(12),
            child: const CustomAssetImage(
              path: AppIcons.close,
              width: 14,
              height: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBookingButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isFullWidth;
  final double? width;

  const _AddBookingButton({
    required this.onTap,
    this.isFullWidth = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPushButton(
      height: 48,
      width: isFullWidth ? double.infinity : (width ?? 170),
      backgroundColor: AppColors.secondary,
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CustomAssetImage(
            path: AppIcons.add,
            width: 16,
            height: 16,
            color: AppColors.white,
          ),
          const SizedBox(width: 8),
          Text(
            'add_new_booking'.tr(),
            style: CustomAppFontStyle.semiBold14.copyWith(
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
