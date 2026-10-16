import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:purexo/core/utils/extensions/date_time_extentision.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/bookings/data/models/booking_model.dart';
import 'package:purexo/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';

class BookingDetailsScheduleSection extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailsScheduleSection({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateStr = BookingTimeFormatter.formatDateWithDay(
      booking.date,
      context,
    );
    final timeStr = BookingTimeFormatter.formatTimeRange(
      booking.startTime,
      booking.endTime,
      context,
    );

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
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const CustomAssetImage(
                  path: AppIcons.service,
                  width: 18,
                  height: 18,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'service_and_schedule'.tr(),
                style: CustomAppFontStyle.semiBold16.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.grayE2E8F0),
          const SizedBox(height: 16),

          // Service Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grayf6,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grayE2E8F0),
            ),
            child: Row(
              children: [
                const CustomAssetImage(
                  path: AppIcons.service,
                  width: 16,
                  height: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    booking.serviceName ?? 'service_default'.tr(),
                    style: CustomAppFontStyle.semiBold14.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Scheduled Date & Time
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grayf6,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grayE2E8F0),
            ),
            child: Column(
              children: [
                // Date Row
                Row(
                  children: [
                    const CustomAssetImage(
                      path: AppIcons.calendar,
                      width: 16,
                      height: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dateStr.isNotEmpty ? dateStr : 'not_specified'.tr(),
                        style: CustomAppFontStyle.medium13.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.grayE2E8F0),
                const SizedBox(height: 10),

                // Time & Duration Row
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.gray71717A,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        timeStr.isNotEmpty ? timeStr : 'not_specified'.tr(),
                        style: CustomAppFontStyle.regular13.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    if (booking.durationMinutes != null &&
                        booking.durationMinutes! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${booking.durationMinutes} ${'minutes'.tr()}',
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          if (booking.createdAt != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '${'created_at'.tr()}: ',
                  style: CustomAppFontStyle.regular12.copyWith(
                    color: AppColors.gray71717A,
                  ),
                ),
                Text(
                  booking.createdAt!.toCustomFormatWithTime(),
                  style: CustomAppFontStyle.medium12.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
