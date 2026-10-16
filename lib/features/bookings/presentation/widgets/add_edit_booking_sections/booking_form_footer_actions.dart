import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/shared/widgets/custom_push_container_button.dart';

class BookingFormFooterActions extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubmit;

  const BookingFormFooterActions({
    super.key,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, color: AppColors.grayE2E8F0),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomPushButton(
                height: 44,
                width: 100,
                backgroundColor: AppColors.grayf2,
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.pop(),
                child: Center(
                  child: Text(
                    'cancel'.tr(),
                    style: CustomAppFontStyle.medium14.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomPushButton(
                  height: 44,
                  width: 120,
                  backgroundColor: AppColors.secondary,
                  isLoading: isLoading,
                  borderRadius: BorderRadius.circular(8),
                  onTap: onSubmit,
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
        ),
      ],
    );
  }
}
