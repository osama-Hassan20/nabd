import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  path: AppIcons.user,
                  width: 18,
                  height: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'patient_info'.tr(),
                style: CustomAppFontStyle.semiBold16.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.grayE2E8F0),
          const SizedBox(height: 16),

          // Patient Name & Avatar
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  (patientName != null && patientName.trim().isNotEmpty)
                      ? patientName.trim()[0].toUpperCase()
                      : '?',
                  style: CustomAppFontStyle.bold16.copyWith(
                    color: AppColors.primaryDark,
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
                        color: AppColors.darkText,
                      ),
                    ),
                    if (patientId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'ID: $patientId',
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: AppColors.gray71717A,
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
                  color: AppColors.grayf6,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.grayE2E8F0),
                ),
                child: Row(
                  children: [
                    const CustomAssetImage(
                      path: AppIcons.phone,
                      width: 16,
                      height: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        patientPhone,
                        style: CustomAppFontStyle.medium13.copyWith(
                          color: AppColors.darkText,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    const Icon(
                      Icons.copy,
                      size: 14,
                      color: AppColors.gray71717A,
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
                color: AppColors.grayf6,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.grayE2E8F0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomAssetImage(
                    path: AppIcons.userLocation,
                    width: 16,
                    height: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      patientAddress,
                      style: CustomAppFontStyle.regular13.copyWith(
                        color: AppColors.darkText,
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

