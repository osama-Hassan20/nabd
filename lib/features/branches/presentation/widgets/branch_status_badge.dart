import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';

class BranchStatusBadge extends StatelessWidget {
  final bool isActive;

  const BranchStatusBadge({
    super.key,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive
        ? const Color(0xFFECFDF5) // Emerald 50
        : const Color(0xFFF1F5F9); // Slate 100
    final dotColor = isActive
        ? const Color(0xFF10B981) // Emerald 500
        : const Color(0xFF94A3B8); // Slate 400
    final textColor = isActive
        ? const Color(0xFF047857) // Emerald 700
        : const Color(0xFF475569); // Slate 600
    final label = isActive ? 'status_active'.tr() : 'status_inactive'.tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: CustomAppFontStyle.medium12.copyWith(color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class MainBranchBadge extends StatelessWidget {
  const MainBranchBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Amber 50
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 13,
            color: Color(0xFFD97706), // Amber 600
          ),
          const SizedBox(width: 4),
          Text(
            'main_branch_badge'.tr(),
            style: CustomAppFontStyle.semiBold11.copyWith(
              color: const Color(0xFFB45309), // Amber 700
            ),
          ),
        ],
      ),
    );
  }
}
