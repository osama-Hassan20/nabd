import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/presentation/widgets/calendar_year_dropdown.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';

class CompactDateStripWidget extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime? selectedMonth;
  final bool isMonthFilterActive;
  final ValueChanged<DateTime?> onDateSelected;
  final void Function(DateTime? month, {bool filterByWholeMonth})
  onMonthSelected;
  final VoidCallback onClearFilter;
  final ValueChanged<int>? onYearSelected;
  final VoidCallback? onNextDay;
  final VoidCallback? onPrevDay;
  final VoidCallback? onNextMonth;
  final VoidCallback? onPrevMonth;
  final VoidCallback? onGoToToday;

  const CompactDateStripWidget({
    super.key,
    required this.selectedDate,
    this.selectedMonth,
    this.isMonthFilterActive = false,
    required this.onDateSelected,
    required this.onMonthSelected,
    required this.onClearFilter,
    this.onYearSelected,
    this.onNextDay,
    this.onPrevDay,
    this.onNextMonth,
    this.onPrevMonth,
    this.onGoToToday,
  });

  @override
  State<CompactDateStripWidget> createState() => _CompactDateStripWidgetState();
}

class _CompactDateStripWidgetState extends State<CompactDateStripWidget> {
  final ScrollController _scrollController = ScrollController();

  DateTime _getFocusedMonth() {
    if (widget.selectedMonth != null) {
      return DateTime(
        widget.selectedMonth!.year,
        widget.selectedMonth!.month,
        1,
      );
    }
    if (widget.selectedDate != null) {
      return DateTime(widget.selectedDate!.year, widget.selectedDate!.month, 1);
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  @override
  void initState() {
    super.initState();
    _scrollToSelectedDay();
  }

  @override
  void didUpdateWidget(covariant CompactDateStripWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate ||
        widget.selectedMonth != oldWidget.selectedMonth) {
      _scrollToSelectedDay();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final selected = widget.selectedDate;
      final focused = _getFocusedMonth();
      if (selected != null &&
          selected.year == focused.year &&
          selected.month == focused.month) {
        final dayIndex = selected.day - 1;
        const itemExtent = 64.0; // card width 56 + separator 8
        final viewportWidth = _scrollController.position.viewportDimension;
        final targetOffset =
            (dayIndex * itemExtent) - (viewportWidth / 2) + (itemExtent / 2);
        final maxOffset = _scrollController.position.maxScrollExtent;
        final clampedOffset = targetOffset.clamp(0.0, maxOffset);
        _scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPrevMonth() {
    if (widget.onPrevMonth != null) {
      widget.onPrevMonth!();
      return;
    }
    final current = _getFocusedMonth();
    final newMonth = DateTime(current.year, current.month - 1, 1);
    final firstDay = DateTime(newMonth.year, newMonth.month, 1);
    widget.onDateSelected(firstDay);
    widget.onMonthSelected(
      newMonth,
      filterByWholeMonth: false,
    );
  }

  void _onNextMonth() {
    if (widget.onNextMonth != null) {
      widget.onNextMonth!();
      return;
    }
    final current = _getFocusedMonth();
    final newMonth = DateTime(current.year, current.month + 1, 1);
    final firstDay = DateTime(newMonth.year, newMonth.month, 1);
    widget.onDateSelected(firstDay);
    widget.onMonthSelected(
      newMonth,
      filterByWholeMonth: false,
    );
  }

  void _onPrevDay() {
    if (widget.onPrevDay != null) {
      widget.onPrevDay!();
      return;
    }
    final now = DateTime.now();
    final focused = _getFocusedMonth();
    final base =
        widget.selectedDate ??
        ((focused.year == now.year && focused.month == now.month)
            ? DateTime(now.year, now.month, now.day)
            : DateTime(focused.year, focused.month, 1));
    final prev = DateTime(base.year, base.month, base.day - 1);
    widget.onDateSelected(prev);
    if (prev.month != focused.month || prev.year != focused.year) {
      widget.onMonthSelected(
        DateTime(prev.year, prev.month, 1),
        filterByWholeMonth: false,
      );
    }
  }

  void _onNextDay() {
    if (widget.onNextDay != null) {
      widget.onNextDay!();
      return;
    }
    final now = DateTime.now();
    final focused = _getFocusedMonth();
    final base =
        widget.selectedDate ??
        ((focused.year == now.year && focused.month == now.month)
            ? DateTime(now.year, now.month, now.day)
            : DateTime(focused.year, focused.month, 1));
    final next = DateTime(base.year, base.month, base.day + 1);
    widget.onDateSelected(next);
    if (next.month != focused.month || next.year != focused.year) {
      widget.onMonthSelected(
        DateTime(next.year, next.month, 1),
        filterByWholeMonth: false,
      );
    }
  }

  void _onSelectYear(int year) {
    if (widget.onYearSelected != null) {
      widget.onYearSelected!(year);
      return;
    }
    final current = _getFocusedMonth();
    final newMonth = DateTime(year, current.month, 1);
    final firstDay = DateTime(year, current.month, 1);
    widget.onDateSelected(firstDay);
    widget.onMonthSelected(
      newMonth,
      filterByWholeMonth: false,
    );
  }

  void _goToToday() {
    if (widget.onGoToToday != null) {
      widget.onGoToToday!();
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    widget.onDateSelected(today);
    widget.onMonthSelected(
      DateTime(now.year, now.month, 1),
      filterByWholeMonth: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final focusedMonth = _getFocusedMonth();
    final monthName = DateFormat('MMMM', locale).format(focusedMonth);
    final daysInMonth = DateUtils.getDaysInMonth(
      focusedMonth.year,
      focusedMonth.month,
    );

    final isCurrentMonthToday =
        focusedMonth.year == now.year && focusedMonth.month == now.month;

    final hasActiveFilter =
        widget.selectedDate != null || widget.isMonthFilterActive;

    final selectedDayDescription = widget.selectedDate != null
        ? DateFormat('EEEE، d MMMM y', locale).format(widget.selectedDate!)
        : (widget.isMonthFilterActive
              ? 'all_month'.tr()
              : 'select_day_hint'.tr());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Header Controls with Responsive Breakdown ───────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;

              final monthTitleAndYear = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monthName,
                    style: CustomAppFontStyle.semiBold15.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CalendarYearDropdown(
                    selectedYear: focusedMonth.year,
                    onYearSelected: _onSelectYear,
                  ),
                  const SizedBox(width: 6),
                  _TodayButton(
                    isToday:
                        isCurrentMonthToday &&
                        widget.selectedDate?.day == today.day,
                    onTap: _goToToday,
                  ),
                ],
              );

              final monthNavGroup = _NavigationGroup(
                label: 'month_label'.tr(),
                onPrev: _onPrevMonth,
                onNext: _onNextMonth,
              );

              final dayNavGroup = _NavigationGroup(
                label: 'day_label'.tr(),
                onPrev: _onPrevDay,
                onNext: _onNextDay,
              );

              final clearButton = hasActiveFilter
                  ? _ClearFilterButton(onTap: widget.onClearFilter)
                  : null;

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: monthTitleAndYear),
                        if (clearButton != null) ...[
                          const SizedBox(width: 6),
                          clearButton,
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDayDescription,
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: AppColors.gray71717A,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        monthNavGroup,
                        const SizedBox(width: 6),
                        dayNavGroup,
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  monthTitleAndYear,
                  const Spacer(),
                  monthNavGroup,
                  const SizedBox(width: 6),
                  dayNavGroup,
                  if (clearButton != null) ...[
                    const SizedBox(width: 8),
                    clearButton,
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // ─── Horizontal Days Strip ──────────────────────────────────
          SizedBox(
            height: 68,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: daysInMonth,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final dayNumber = index + 1;
                final dayDate = DateTime(
                  focusedMonth.year,
                  focusedMonth.month,
                  dayNumber,
                );

                final isToday =
                    dayDate.year == today.year &&
                    dayDate.month == today.month &&
                    dayDate.day == today.day;

                final isSelected =
                    widget.selectedDate != null &&
                    dayDate.year == widget.selectedDate!.year &&
                    dayDate.month == widget.selectedDate!.month &&
                    dayDate.day == widget.selectedDate!.day;

                final dayName = DateFormat('E', locale).format(dayDate);

                return InkWell(
                  onTap: () {
                    if (isSelected) {
                      widget.onDateSelected(null);
                    } else {
                      widget.onDateSelected(dayDate);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isToday
                                ? AppColors.primaryLight
                                : AppColors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isToday
                                  ? AppColors.primary
                                  : AppColors.grayE2E8F0),
                        width: (isSelected || isToday) ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName,
                          style: CustomAppFontStyle.regular11.copyWith(
                            color: isSelected
                                ? AppColors.white.withValues(alpha: 0.85)
                                : (isToday
                                      ? AppColors.primary
                                      : AppColors.gray71717A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dayNumber.toString(),
                          style: CustomAppFontStyle.bold15.copyWith(
                            color: isSelected
                                ? AppColors.white
                                : (isToday
                                      ? AppColors.primary
                                      : AppColors.darkText),
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationGroup extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _NavigationGroup({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.grayf2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Prev button (points to past: right arrow in RTL, left arrow in LTR)
          InkWell(
            onTap: onPrev,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: CustomAssetImage(path: AppIcons.arrowForward, width: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              label,
              style: CustomAppFontStyle.medium11.copyWith(
                color: AppColors.darkText,
              ),
            ),
          ),
          // Next button (points to future: left arrow in RTL, right arrow in LTR)
          InkWell(
            onTap: onNext,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: CustomAssetImage(path: AppIcons.arrowBack, width: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayButton extends StatelessWidget {
  final bool isToday;
  final VoidCallback onTap;

  const _TodayButton({required this.isToday, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isToday ? AppColors.primaryLight : AppColors.grayf2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.grayE2E8F0,
          ),
        ),
        child: Center(
          child: Text(
            'today'.tr(),
            style: CustomAppFontStyle.medium11.copyWith(
              color: isToday ? AppColors.primary : AppColors.gray71717A,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearFilterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ClearFilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'clear_date_filter'.tr(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.red1A,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
              const SizedBox(width: 4),
              Text(
                'cancel'.tr(),
                style: CustomAppFontStyle.medium11.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
