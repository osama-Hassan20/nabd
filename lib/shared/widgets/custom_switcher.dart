import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_gradient.dart';

import '../../core/utils/theme/app_colors.dart';
import 'package:flutter/material.dart';

// class CustomSwitcher extends StatelessWidget {
//   const CustomSwitcher({
//     super.key,
//     required this.isActive,
//     required this.onChanged,
//   });

//   final bool isActive;
//   final void Function(bool) onChanged;

//   @override
//   Widget build(BuildContext context) {
//     return Transform(
//       alignment: Alignment.center,
//       transform: Matrix4.rotationY(3.1416),
//       child: Transform.scale(
//         scale: 0.8,
//         child: Switch(
//           padding: const EdgeInsets.all(0),
//           value: isActive,
//           onChanged: onChanged,
//           activeColor: AppColors.primary,

//           inactiveTrackColor: AppColors.grayF5,
//           inactiveThumbColor: AppColors.black,
//           activeTrackColor: AppColors.primary,
//           thumbColor: WidgetStatePropertyAll(
//             isActive ? AppColors.white : AppColors.gray6C,
//           ),
//         ),
//       ),
//     );
//   }
// }

class CustomSwitcher extends StatefulWidget {
  const CustomSwitcher({
    super.key,
    required this.isActive,
    required this.onChanged,
    this.enableBorder = false,
  });
  final bool isActive;
  final void Function(bool) onChanged;
  final bool enableBorder;
  @override
  State<CustomSwitcher> createState() => _CustomSwitcherState();
}

class _CustomSwitcherState extends State<CustomSwitcher> {
  @override
  Widget build(BuildContext context) {
    bool isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () => widget.onChanged(!widget.isActive),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 48,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: widget.isActive
              ? AppGradient.greenGradient
              : LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.gray334155,
                          AppColors.gray334155.withValues(alpha: 0.8),
                        ]
                      : [
                          AppColors.grayMuted.withValues(alpha: 0.2),
                          AppColors.grayMuted.withValues(alpha: 0.1),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: widget.enableBorder
              ? Border.all(
                  color: isDark ? AppColors.grayDim : AppColors.grayBorder,
                  width: 1,
                )
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment:
              widget.isActive ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

