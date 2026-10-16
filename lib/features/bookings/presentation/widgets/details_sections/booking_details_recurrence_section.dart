import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/bookings/data/models/booking_model.dart';
import 'package:purexo/features/bookings/data/models/recurrence_rule_model.dart';
import 'package:purexo/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';

class BookingDetailsRecurrenceSection extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailsRecurrenceSection({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final recurrence = booking.recurrence;
    final isOngoing = recurrence?.isOngoing ?? true;
    final endDate = recurrence?.endDate;
    final daySchedules = recurrence?.daySchedules ?? const [];
    final daysOfWeek = recurrence?.daysOfWeek ?? const [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayE2E8F0),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const CustomAssetImage(
                  path: AppIcons.calendar,
                  width: 18,
                  height: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'recurring_days'.tr(),
                style: CustomAppFontStyle.semiBold16.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.grayE2E8F0),
          const SizedBox(height: 16),

          // Recurrence Duration Badge (Ongoing vs Specific End Date)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isOngoing
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOngoing
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOngoing ? Icons.all_inclusive : Icons.event_busy,
                  size: 16,
                  color: isOngoing ? AppColors.success : AppColors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  isOngoing
                      ? 'ongoing_until_cancelled'.tr()
                      : endDate != null
                          ? '${'recurrence_ends_on'.tr()} ${BookingTimeFormatter.formatCompactDate(endDate, context)}'
                          : 'ends_on_specific_date'.tr(),
                  style: CustomAppFontStyle.semiBold13.copyWith(
                    color: isOngoing ? AppColors.success : AppColors.accent,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Day-by-Day Schedules
          if (daySchedules.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: daySchedules.map((sched) {
                final dayOpt = DayOfWeekOption.fromKey(sched.day);
                final formattedRange = BookingTimeFormatter.formatTimeRange(
                  sched.startTime,
                  sched.endTime,
                  context,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grayf6,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grayE2E8F0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          dayOpt.getName(context),
                          style: CustomAppFontStyle.semiBold12.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedRange,
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else if (daysOfWeek.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: daysOfWeek.map((dayKey) {
                final dayOpt = DayOfWeekOption.fromKey(dayKey);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grayf6,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grayE2E8F0),
                  ),
                  child: Text(
                    dayOpt.getName(context),
                    style: CustomAppFontStyle.medium13.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              'recurring'.tr(),
              style: CustomAppFontStyle.regular13.copyWith(
                color: AppColors.gray71717A,
              ),
            ),
        ],
      ),
    );
  }
}
