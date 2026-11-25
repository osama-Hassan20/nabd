import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';

class ProvisionalBadge extends StatelessWidget {
  final String? label;
  final bool isProvisional;

  const ProvisionalBadge({
    super.key,
    this.label,
    this.isProvisional = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isProvisional) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label ?? 'provisional_unconfirmed'.tr(),
            style: CustomAppFontStyle.medium10.copyWith(
              color: const Color(0xFFD97706),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
