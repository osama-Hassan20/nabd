import 'package:flutter/material.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';

class StaffUserAvatar extends StatelessWidget {
  final String? fullName;
  final bool isOwner;
  final double radius;

  const StaffUserAvatar({
    super.key,
    this.fullName,
    this.isOwner = false,
    this.radius = 20,
  });

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    // Clean dr prefix
    final cleanParts = parts.where((p) => p != 'د.' && p != 'دكتور').toList();
    if (cleanParts.isEmpty) return 'د';
    if (cleanParts.length == 1) {
      return cleanParts[0].substring(0, 1).toUpperCase();
    }
    return '${cleanParts[0][0]}${cleanParts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(fullName);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isOwner
                  ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                  : [AppColors.primary, AppColors.primaryDark],
            ),
            boxShadow: [
              BoxShadow(
                color: (isOwner ? const Color(0xFFF59E0B) : AppColors.primary)
                    .withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: CustomAppFontStyle.semiBold14.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (isOwner)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 11,
                color: Color(0xFFD97706),
              ),
            ),
          ),
      ],
    );
  }
}

