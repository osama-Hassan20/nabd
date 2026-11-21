import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/animation/hover_scale_animation.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

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
          prev.activeBookingTypeTab != curr.activeBookingTypeTab,
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
    final colors = context.themeColors;
    return CustomContainer(
      backGroundColor: colors.cardBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: colors.borderSubtle),
      child: Row(
        children: [
          // Search Field (Flex 3)
          Expanded(flex: 3, child: _buildSearchField(context, cubit)),
          const SizedBox(width: 12),

          // Status Dropdown
          SizedBox(
            width: 190,
            child: _StatusDropdown(
              selectedStatus: state.selectedStatus,
              onChanged: cubit.onStatusFilterChanged,
            ),
          ),

          if (state.selectedDate != null) ...[
            const SizedBox(width: 12),
            _DateFilterChip(
              date: state.selectedDate!,
              onClear: cubit.clearDateFilter,
            ),
          ],

          const SizedBox(width: 12),

          // Add New Medical Booking Button
          _AddBookingButton(onTap: onAddNewBooking, width: 175),
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
    final colors = context.themeColors;
    return CustomContainer(
      backGroundColor: colors.cardBackground,
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: colors.borderSubtle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchField(context, cubit)),
              const SizedBox(width: 12),
              _AddBookingButton(onTap: onAddNewBooking, width: 160),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 200,
                child: _StatusDropdown(
                  selectedStatus: state.selectedStatus,
                  onChanged: cubit.onStatusFilterChanged,
                ),
              ),
              if (state.selectedDate != null) ...[
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

  // ─── Mobile Layout (width <= 700) ────────────────────────────────────────────
  Widget _buildMobileLayout(
    BuildContext context,
    BookingsCubit cubit,
    BookingsState state,
  ) {
    final colors = context.themeColors;
    return CustomContainer(
      backGroundColor: colors.cardBackground,
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.borderSubtle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(context, cubit),
          const SizedBox(height: 8),
          _StatusDropdown(
            selectedStatus: state.selectedStatus,
            onChanged: cubit.onStatusFilterChanged,
          ),
          if (state.selectedDate != null) ...[
            const SizedBox(height: 8),
            _DateFilterChip(
              date: state.selectedDate!,
              onClear: cubit.clearDateFilter,
            ),
          ],
          const SizedBox(height: 10),
          _AddBookingButton(onTap: onAddNewBooking),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, BookingsCubit cubit) {
    final colors = context.themeColors;
    return CustomTextFormField(
      hintText: 'search_patient_hint'.tr(),
      controller: cubit.searchController,
      prefixWidget: Icon(
        Icons.search_rounded,
        color: colors.textSecondary,
        size: 20,
      ),
      enableFill: true,
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
    final colors = context.themeColors;
    final list = <BookingStatusEnum?>[null, ...BookingStatusEnum.values];
    return CustomStackSelector<BookingStatusEnum?>(
      controller: _controller,
      list: list,
      itemAsString: (s) => s?.label ?? 'all_statuses'.tr(),
      hintText: 'all_statuses'.tr(),
      itemBuilder: (context, s) {
        if (s == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              'all_statuses'.tr(),
              style: CustomAppFontStyle.medium14.copyWith(
                color: colors.textPrimary,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: s.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.label,
                  style: CustomAppFontStyle.medium14.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      changeValue: (s) => widget.onChanged(s),
    );
  }
}

class _DateFilterChip extends StatelessWidget {
  final DateTime date;
  final VoidCallback onClear;

  const _DateFilterChip({
    required this.date,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final formattedDate = BookingTimeFormatter.formatCompactDate(date, context);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: colors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            formattedDate,
            style: CustomAppFontStyle.medium12.copyWith(
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(10),
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBookingButton extends StatelessWidget {
  final VoidCallback onTap;
  final double? width;

  const _AddBookingButton({required this.onTap, this.width});

  @override
  Widget build(BuildContext context) {
    return HoverScaleAnimation(
      hoverScale: 1.02,
      tapScale: 0.98,
      child: CustomPushButton(
        width: width,
        height: 44,
        radius: 100,
        backgroundColor: AppColors.primary,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: AppColors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              'create_medical_appointment'.tr(),
              style: CustomAppFontStyle.semiBold13.copyWith(
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
