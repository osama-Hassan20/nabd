import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class BookingDetailsPatientSection extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailsPatientSection({super.key, required this.booking});

  void _copyPhone(BuildContext context) {
    final phone = booking.patientPhone ?? booking.customerPhone;
    if (phone != null && phone.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: phone));
      CustomToast(
        context: context,
        header: 'copied_to_clipboard'.tr(),
      ).showTopToast();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = booking.patientName ?? booking.customerName;
    final patientId = booking.patientId ?? booking.customerId;
    final patientPhone = booking.patientPhone ?? booking.customerPhone;
    final patientAddress = booking.customerAddress;

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
                  path: AppIcons.user,
                  width: 18,
                  height: 18,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'patient_info'.tr(),
                style: CustomAppFontStyle.semiBold16.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 16),

          // Patient Name & Avatar
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colors.primaryLight,
                child: Text(
                  (patientName != null && patientName.trim().isNotEmpty)
                      ? patientName.trim()[0].toUpperCase()
                      : '?',
                  style: CustomAppFontStyle.bold16.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName ?? 'patient_unassigned'.tr(),
                      style: CustomAppFontStyle.semiBold15.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    if (patientId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'ID: $patientId',
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Patient Phone
          if (patientPhone != null && patientPhone.trim().isNotEmpty) ...[
            InkWell(
              onTap: () => _copyPhone(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceLevel1,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    CustomAssetImage(
                      path: AppIcons.phone,
                      width: 16,
                      height: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        patientPhone,
                        style: CustomAppFontStyle.medium13.copyWith(
                          color: colors.textPrimary,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    Icon(
                      Icons.copy,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Patient Address
          if (patientAddress != null && patientAddress.trim().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceLevel1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomAssetImage(
                    path: AppIcons.userLocation,
                    width: 16,
                    height: 16,
                    color: colors.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      patientAddress,
                      style: CustomAppFontStyle.regular13.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

