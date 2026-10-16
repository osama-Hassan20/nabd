import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/features/bookings/presentation/widgets/calendar_year_dropdown.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';

class BookingCalendarWidget extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?>? onDateSelected;
  final ValueChanged<int>? onYearSelected;

  const BookingCalendarWidget({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.onYearSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();
    final locale = context.locale.languageCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<String> weekDayNames = locale == 'ar'
        ? ['سبت', 'أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة']
        : ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    return BlocBuilder<BookingsCubit, BookingsState>(
      buildWhen: (prev, curr) =>
          prev.selectedDate != curr.selectedDate ||
          prev.selectedMonth != curr.selectedMonth,
      builder: (context, state) {
        final focusedMonth =
            state.selectedMonth ??
            selectedDate ??
            state.selectedDate ??
            DateTime(now.year, now.month, 1);
        final effectiveSelectedDate = selectedDate ?? state.selectedDate;

        final daysInMonth = DateUtils.getDaysInMonth(
          focusedMonth.year,
          focusedMonth.month,
        );
        final firstDayWeekday = DateTime(
          focusedMonth.year,
          focusedMonth.month,
          1,
        ).weekday;
        final offset = (firstDayWeekday % 7);

        return CustomContainer(
          backGroundColor: AppColors.white,
          padding: const EdgeInsets.all(16),
          borderRaduis: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Month, Year Selector & Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('MMMM', locale).format(focusedMonth),
                        style: CustomAppFontStyle.semiBold16.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CalendarYearDropdown(
                        selectedYear: focusedMonth.year,
                        onYearSelected: (year) {
                          if (onYearSelected != null) {
                            onYearSelected!(year);
                          } else {
                            cubit.setCalendarYear(year);
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'previous_month'.tr(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: CustomAssetImage(
                          path: AppIcons.arrowForward,
                          width: 16,
                          height: 16,
                          color: AppColors.gray71717A,
                        ),
                        onPressed: cubit.previousCalendarMonth,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'next_month'.tr(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: CustomAssetImage(
                          path: AppIcons.arrowBack,
                          width: 16,
                          height: 16,
                          color: AppColors.gray71717A,
                        ),
                        onPressed: cubit.nextCalendarMonth,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Weekdays header
              Row(
                children: weekDayNames.map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: AppColors.gray71717A,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Month Days Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: offset + daysInMonth,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  if (index < offset) {
                    return const SizedBox.shrink();
                  }
                  final dayNumber = index - offset + 1;
                  final cellDate = DateTime(
                    focusedMonth.year,
                    focusedMonth.month,
                    dayNumber,
                  );
                  final isToday =
                      cellDate.year == today.year &&
                      cellDate.month == today.month &&
                      cellDate.day == today.day;
                  final isSelected =
                      effectiveSelectedDate != null &&
                      cellDate.year == effectiveSelectedDate.year &&
                      cellDate.month == effectiveSelectedDate.month &&
                      cellDate.day == effectiveSelectedDate.day;

                  return InkWell(
                    onTap: () {
                      if (isSelected) {
                        if (onDateSelected != null) {
                          onDateSelected!(null);
                        } else {
                          cubit.onDateSelected(null);
                        }
                      } else {
                        if (onDateSelected != null) {
                          onDateSelected!(cellDate);
                        } else {
                          cubit.onDateSelected(cellDate);
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isToday
                                  ? AppColors.primaryLight
                                  : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday && !isSelected
                            ? Border.all(color: AppColors.primary, width: 1.2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          dayNumber.toString(),
                          style: CustomAppFontStyle.medium13.copyWith(
                            color: isSelected
                                ? AppColors.white
                                : (isToday
                                      ? AppColors.primary
                                      : AppColors.darkText),
                            fontWeight: (isSelected || isToday)
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              if (effectiveSelectedDate != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    if (onDateSelected != null) {
                      onDateSelected!(null);
                    } else {
                      cubit.clearDateFilter();
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.fillDisableColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        'clear_date_filter'.tr(),
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
