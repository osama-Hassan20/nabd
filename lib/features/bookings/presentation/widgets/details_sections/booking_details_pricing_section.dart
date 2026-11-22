import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/network/mony_helper.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';

class BookingDetailsPricingSection extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailsPricingSection({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final paymentStatus = booking.paymentStatus;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.35 : 0.02),
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
                    color: colors.textPrimary,
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
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 16),

          // Consultation Fee Row (if present)
          if (booking.consultationFee != null &&
              booking.consultationFee! > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'consultation_fee_label'.tr(),
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  '${MonyHelper.formatMoney(booking.consultationFee!)} ${'currency'.tr()}',
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: colors.textPrimary,
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
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  '${booking.durationMinutes} ${'minutes'.tr()}',
                  style: CustomAppFontStyle.medium13.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 14),

          // Total Price Container (Highlighted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomAssetImage(
                      path: AppIcons.money,
                      width: 18,
                      height: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'total_price'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${MonyHelper.formatMoney(booking.totalPrice ?? 0)} ${'currency'.tr()}',
                  style: CustomAppFontStyle.bold18.copyWith(
                    color: colors.primary,
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
