import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:purexo/core/network/mony_helper.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/bookings/data/models/booking_model.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';

class BookingDetailsPricingSection extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailsPricingSection({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final paymentStatus = booking.paymentStatus;

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
          // Section Header + Payment Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const CustomAssetImage(
                  path: AppIcons.money,
                  width: 18,
                  height: 18,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'pricing_and_payment'.tr(),
                  style: CustomAppFontStyle.semiBold16.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
              ),
              if (paymentStatus != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: paymentStatus.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    paymentStatus.label,
                    style: CustomAppFontStyle.medium12.copyWith(
                      color: paymentStatus.color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.grayE2E8F0),
          const SizedBox(height: 16),

          // Hourly Rate Row (if present)
          if (booking.hourlyRate != null && booking.hourlyRate! > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'hourly_rate'.tr(),
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: AppColors.gray71717A,
                  ),
                ),
                Text(
                  '${MonyHelper.formatMoney(booking.hourlyRate!)} ${'qar_currency'.tr()} / ${'hour'.tr()}',
                  style: CustomAppFontStyle.medium13.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Duration Row (if present)
          if (booking.durationMinutes != null &&
              booking.durationMinutes! > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'duration'.tr(),
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: AppColors.gray71717A,
                  ),
                ),
                Text(
                  '${booking.durationMinutes} ${'minutes'.tr()}',
                  style: CustomAppFontStyle.medium13.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 1, color: AppColors.grayE2E8F0),
          const SizedBox(height: 14),

          // Total Price Container (Highlighted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CustomAssetImage(
                      path: AppIcons.money,
                      width: 18,
                      height: 18,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'total_price'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${MonyHelper.formatMoney(booking.totalPrice ?? 0)} ${'qar_currency'.tr()}',
                  style: CustomAppFontStyle.bold18.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
