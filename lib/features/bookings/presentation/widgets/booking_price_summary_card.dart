import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/helpers/app_formatter_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/discount_type_enum.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_action_dialogs.dart';
import 'package:eyadty/features/bookings/presentation/widgets/free_booking_badge.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

class BookingPriceSummaryCard extends StatelessWidget {
  final BookingModel booking;

  const BookingPriceSummaryCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = booking.discountType != null &&
        booking.discountType != DiscountTypeEnum.none;

    final session =
        getIt.isRegistered<SessionCubit>() ? getIt<SessionCubit>() : null;
    final evaluator = getIt.isRegistered<PermissionEvaluator>()
        ? getIt<PermissionEvaluator>()
        : null;
    final isOwner = session?.currentUser?.isOwner == true;
    final hasRemovePerm = evaluator?.can(
          StaffPermissionEnum.applyBookingDiscount,
          branchId: booking.branchId,
        ) ??
        isOwner;

    final paymentStatus = booking.effectivePaymentStatus;
    final originalFee = booking.consultationFee ?? booking.totalPrice ?? 0;
    final paid = booking.paidAmount ?? 0;
    final net = booking.netAmount;
    final remaining = (net - paid).clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
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
          // Section Header + Badges
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
                  'disc_price_summary_title'.tr(),
                  style: CustomAppFontStyle.semiBold16.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
              ),
              if (booking.isFreeConsultation)
                const FreeBookingBadge()
              else
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
          const Divider(height: 1),
          const SizedBox(height: 16),

          // 1. Original Fee Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'disc_original_price'.tr(),
                style: CustomAppFontStyle.regular13.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
              Text(
                AppFormatterHelper.formatCurrency(originalFee),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Discount Row (if active)
          if (hasDiscount) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'disc_discount_amount'.tr()} (${booking.discountType?.labelKey.tr() ?? ''})',
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: AppColors.primaryViolet,
                  ),
                ),
                Text(
                  '- ${AppFormatterHelper.formatCurrency(booking.discountAmount)}',
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.primaryViolet,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // 3. Net Price Container (Bold / Highlighted)
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
                Text(
                  'disc_net_amount'.tr(),
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  AppFormatterHelper.formatCurrency(net),
                  style: CustomAppFontStyle.bold18.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Paid & Remaining Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'disc_paid_amount'.tr(),
                style: CustomAppFontStyle.regular13.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
              Text(
                AppFormatterHelper.formatCurrency(paid),
                style: CustomAppFontStyle.medium13.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'disc_remaining'.tr(),
                style: CustomAppFontStyle.regular13.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
              Text(
                AppFormatterHelper.formatCurrency(remaining),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: remaining > 0 ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),

          // 5. Discount Metadata (Reason, Approver)
          if (hasDiscount) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (booking.discountReason != null &&
                booking.discountReason!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'disc_reason_label'.tr()}: ',
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      booking.discountReason!,
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            if (booking.discountApprovedByUserId != null) ...[
              Row(
                children: [
                  Text(
                    '${'disc_approved_by'.tr()}: ',
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                  Text(
                    booking.discountApprovedByUserId!,
                    style: CustomAppFontStyle.medium12.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  if (booking.discountApprovedAt != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• ${AppFormatterHelper.formatDate(booking.discountApprovedAt)}',
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: AppColors.gray71717A,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],

          // 6. Remove Discount Action Button
          if (hasDiscount && hasRemovePerm) ...[
            const SizedBox(height: 16),
            CustomPushButton(
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              onTap: () => BookingActionDialogs.showRemoveDiscountDialog(
                context: context,
                booking: booking,
              ),
              child: Center(
                child: Text(
                  'disc_remove_button'.tr(),
                  style: CustomAppFontStyle.medium14.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
