import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/utils/theme/app_colors.dart';
import '../../core/utils/theme/custom_app_font_styles.dart';

class CustomHeaderAction extends StatefulWidget {
  final String title;
  final List<List<dynamic>>? icon;
  final VoidCallback onTap;
  final bool isActive;

  const CustomHeaderAction({
    super.key,
    required this.title,
    this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<CustomHeaderAction> createState() => _CustomHeaderActionState();
}

class _CustomHeaderActionState extends State<CustomHeaderAction> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _isHovered || widget.isActive
                ? AppColors.white.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    HugeIcon(
                      icon: widget.icon!,
                      color: _isHovered || widget.isActive
                          ? AppColors.darkGray
                          : AppColors.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.title,
                    style: CustomAppFontStyle.medium14.copyWith(
                      color: _isHovered || widget.isActive
                          ? AppColors.darkGray
                          : AppColors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                width: _isHovered || widget.isActive ? 40 : 0,
                decoration: BoxDecoration(
                  color: AppColors.darkGray,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
