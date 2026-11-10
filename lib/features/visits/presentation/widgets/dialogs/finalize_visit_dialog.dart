import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

class FinalizeVisitDialog extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onConfirm;

  const FinalizeVisitDialog({
    super.key,
    this.isLoading = false,
    required this.onConfirm,
  });

  static Future<bool?> show({
    required BuildContext context,
    bool isLoading = false,
    VoidCallback? onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) => FinalizeVisitDialog(
        isLoading: isLoading,
        onConfirm: () {
          if (onConfirm != null) {
            onConfirm();
          } else {
            Navigator.of(dialogCtx).pop(true);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'visits_finalize_confirm_title'.tr(),
                style: CustomAppFontStyle.semiBold18.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'visits_finalize_confirm_body'.tr(),
                textAlign: TextAlign.center,
                style: CustomAppFontStyle.regular14.copyWith(
                  color: AppColors.gray71717A,
                  height: 1.5,
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
                    onTap: () => Navigator.of(context).pop(false),
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
                      width: 140,
                      backgroundColor: AppColors.primary,
                      isLoading: isLoading,
                      borderRadius: BorderRadius.circular(8),
                      onTap: onConfirm,
                      child: Center(
                        child: Text(
                          'visits_finalize_visit'.tr(),
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
