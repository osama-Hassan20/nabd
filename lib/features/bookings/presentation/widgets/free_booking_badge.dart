import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';

class FreeBookingBadge extends StatelessWidget {
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const FreeBookingBadge({
    super.key,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.primaryViolet.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.primaryViolet.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.card_giftcard_rounded,
            size: fontSize + 2,
            color: AppColors.primaryViolet,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'disc_free_badge'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryViolet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
