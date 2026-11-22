import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/extensions/date_time_extentision.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';

import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';

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

    final colors = context.themeColors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
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
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomAssetImage(
                  path: AppIcons.service,
                  width: 18,
                  height: 18,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'service_and_schedule'.tr(),
                style: CustomAppFontStyle.semiBold16.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 16),

          // Service Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceLevel1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                CustomAssetImage(
                  path: AppIcons.service,
                  width: 16,
                  height: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    booking.serviceName ?? 'service_default'.tr(),
                    style: CustomAppFontStyle.semiBold14.copyWith(
                      color: colors.textPrimary,
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
              color: colors.surfaceLevel1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              children: [
                // Date Row
                Row(
                  children: [
                    CustomAssetImage(
                      path: AppIcons.calendar,
                      width: 16,
                      height: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dateStr.isNotEmpty ? dateStr : 'not_specified'.tr(),
                        style: CustomAppFontStyle.medium13.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: colors.borderSubtle),
                const SizedBox(height: 10),

                // Time & Duration Row
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        timeStr.isNotEmpty ? timeStr : 'not_specified'.tr(),
                        style: CustomAppFontStyle.regular13.copyWith(
                          color: colors.textPrimary,
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
                          color: colors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${booking.durationMinutes} ${'minutes'.tr()}',
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Postponement Information Banner
          if (booking.status == BookingStatusEnum.postponed && booking.rescheduledTo != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_repeat_rounded, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'postponed_to_other_day'.tr(),
                        style: CustomAppFontStyle.semiBold13.copyWith(color: AppColors.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${'rescheduled_appointment'.tr()}: ${BookingTimeFormatter.formatDateWithDay(booking.rescheduledTo, context)} ${BookingTimeFormatter.formatSingleTime('${booking.rescheduledTo!.hour.toString().padLeft(2, '0')}:${booking.rescheduledTo!.minute.toString().padLeft(2, '0')}', context)}',
                    style: CustomAppFontStyle.medium12.copyWith(color: colors.textPrimary),
                  ),
                  if (booking.postponeReason != null && booking.postponeReason!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${'postpone_reason_label'.tr()}: ${booking.postponeReason}',
                      style: CustomAppFontStyle.regular12.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Cancellation Information Banner
          if (booking.status == BookingStatusEnum.cancelled) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.isDark ? AppColors.error.withValues(alpha: 0.15) : AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        'cancelled_today'.tr(),
                        style: CustomAppFontStyle.semiBold13.copyWith(color: AppColors.error),
                      ),
                      const Spacer(),
                      Text(
                        booking.cancelledBy == 'clinic'
                            ? 'cancelled_by_clinic'.tr()
                            : 'cancelled_by_patient'.tr(),
                        style: CustomAppFontStyle.medium11.copyWith(color: AppColors.error),
                      ),
                    ],
                  ),
                  if (booking.cancelReason != null && booking.cancelReason!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${'cancel_reason_label'.tr()}: ${booking.cancelReason}',
                      style: CustomAppFontStyle.regular12.copyWith(color: colors.textPrimary),
                    ),
                  ],
                  if (booking.cancelledAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${'cancellation_time'.tr()}: ${booking.cancelledAt!.toCustomFormatWithTime()}',
                      style: CustomAppFontStyle.regular11.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (booking.createdAt != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '${'created_at'.tr()}: ',
                  style: CustomAppFontStyle.regular12.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  booking.createdAt!.toCustomFormatWithTime(),
                  style: CustomAppFontStyle.medium12.copyWith(
                    color: colors.textPrimary,
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
