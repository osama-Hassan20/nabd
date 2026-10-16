import 'package:purexo/core/animation/hover_scale_animation.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomActionButton extends StatelessWidget {
  const CustomActionButton({
    super.key,
    this.onPressed,
    this.tooltip,
    this.text,
    required this.icon,
    this.color,
    this.iconColor,
    this.iconSize,
    this.textStyle,
    this.borderRadius,
    this.gradient,
    this.width,
    this.padding,
  });

  final void Function()? onPressed;
  final String? tooltip;
  final String? text;
  final String icon;
  final Color? color;
  final Gradient? gradient;
  final Color? iconColor;
  final double? iconSize;
  final TextStyle? textStyle;
  final double? borderRadius;
  final double? width;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) {
    return HoverScaleAnimation(
      child: Container(
        width: width,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
          gradient: gradient,
        ),
        child: IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: gradient != null
                ? Colors.transparent
                : (color ?? AppColors.greenMuted),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: width != null ? Size(width!, 0) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
            ),
          ),
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              if (text != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text!,
                    style: textStyle ?? CustomAppFontStyle.regular16,
                  ),
                ),
              SvgPicture.asset(
                icon,
                //  fit: BoxFit.scaleDown,
                width: iconSize ?? 24,
                height: iconSize ?? 24,
                colorFilter: iconColor != null
                    ? ColorFilter.mode(iconColor!, BlendMode.srcIn)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
