import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';

class MedicalServiceStatusBadge extends StatelessWidget {
  final bool isActive;

  const MedicalServiceStatusBadge({
    super.key,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isActive ? AppColors.lightGreenEFF8F0 : AppColors.surfaceLevel1;
    final textColor = isActive ? AppColors.success : AppColors.gray;
    final text = isActive
        ? 'service_status_active'.tr()
        : 'service_status_inactive'.tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? AppColors.lightGreenAccent : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: CustomAppFontStyle.medium12.copyWith(
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
