import 'package:flutter/material.dart';

import '../../core/utils/theme/app_colors.dart';

class CustomContainer extends StatelessWidget {
  const CustomContainer({
    super.key,
    this.backGroundColor,
    this.padding,
    this.margin,
    this.borderRaduis,
    this.child,
    this.enableShadow = false,
    this.boxShadow,
    this.gradient,
    this.width,
    this.height,
    this.border,
    this.borderRadius,
    this.constraints,
  });

  final Color? backGroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRaduis;
  final Widget? child;
  final bool enableShadow;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final BoxBorder? border;
  final BorderRadiusGeometry? borderRadius;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: constraints,
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: border,
        // boxShadow:
        //     boxShadow ??
        //     (enableShadow
        //         ? [
        //             BoxShadow(
        //               color: AppColors.black.withValues(alpha: .1),
        //               blurRadius: 10,
        //               offset: const Offset(0, 4),
        //             ),
        //           ]
        //         : null),
        borderRadius:
            borderRadius ??
            BorderRadius.all(Radius.circular(borderRaduis ?? 12)),
        gradient: gradient,
        color: gradient == null ? (backGroundColor ?? (AppColors.white)) : null,
      ),
      child: child,
    );
  }
}
