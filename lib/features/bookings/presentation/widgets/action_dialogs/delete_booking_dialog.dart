import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

class DeleteBookingDialog extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onDelete;

  const DeleteBookingDialog({
    super.key,
    required this.isLoading,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grayE2E8F0),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.red1A,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(14),
                child: const CustomAssetImage(
                  path: AppIcons.delete,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'confirm_delete_booking_title'.tr(),
                style: CustomAppFontStyle.semiBold18.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'confirm_delete_booking_desc'.tr(),
                textAlign: TextAlign.center,
                style: CustomAppFontStyle.regular13.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
              const SizedBox(height: 24),
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
                      backgroundColor: AppColors.error,
                      isLoading: isLoading,
                      borderRadius: BorderRadius.circular(8),
                      onTap: onDelete,
                      child: Center(
                        child: Text(
                          'delete'.tr(),
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
