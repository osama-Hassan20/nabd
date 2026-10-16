import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:purexo/shared/widgets/custom_push_container_button.dart';

class ChangeBookingStatusDialog extends StatelessWidget {
  final BookingStatusEnum selectedStatus;
  final bool isLoading;
  final ValueChanged<BookingStatusEnum> onSelectStatus;
  final VoidCallback onConfirm;

  const ChangeBookingStatusDialog({
    super.key,
    required this.selectedStatus,
    required this.isLoading,
    required this.onSelectStatus,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grayE2E8F0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'change_status'.tr(),
                    style: CustomAppFontStyle.semiBold18.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  CloseButton(),
                ],
              ),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: BookingStatusEnum.values.map((status) {
                  final isSelected = selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => onSelectStatus(status),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? status.color.withValues(alpha: 0.12)
                              : AppColors.grayf2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? status.color
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            CustomAssetImage(
                              path: status.icon,
                              width: 18,
                              height: 18,
                              color: status.color,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                status.label,
                                style: CustomAppFontStyle.medium14.copyWith(
                                  color: AppColors.darkText,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: status.color,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomPushButton(
                    height: 40,
                    width: 100,
                    backgroundColor: AppColors.grayf2,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.pop(),
                    child: Center(
                      child: Text(
                        'cancel'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: AppColors.grayMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomPushButton(
                      height: 40,
                      width: 120,
                      backgroundColor: AppColors.primary,
                      isLoading: isLoading,
                      borderRadius: BorderRadius.circular(8),
                      onTap: onConfirm,
                      child: Center(
                        child: Text(
                          'save'.tr(),
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
