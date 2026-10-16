import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/utils/theme/app_colors.dart';
import '../../core/utils/theme/custom_app_font_styles.dart';

class CustomTextWithIconInCheckOut extends StatelessWidget {
  const CustomTextWithIconInCheckOut({
    super.key,
    required this.text,
    required this.iconPath,
    this.iconColor,
    this.iconSize,
    this.textStyle,
    this.enableColor = true,
    this.lastWidget,
    this.textDirection,
    this.mainAxisSize,
  });
  final String text;
  final String iconPath;
  final Color? iconColor;
  final TextStyle? textStyle;
  final double? iconSize;
  final Widget? lastWidget;
  final bool enableColor;
  final TextDirection? textDirection;
  final MainAxisSize? mainAxisSize;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: mainAxisSize ?? MainAxisSize.min,
      spacing: 4,
      children: [
        SvgPicture.asset(
          iconPath,
          width: iconSize ?? 16,
          height: iconSize ?? 16,
          colorFilter: enableColor
              ? ColorFilter.mode(
                  iconColor ?? AppColors.gray334155,
                  BlendMode.srcIn,
                )
              : null,
        ),
        Text(
          text,
          textDirection: textDirection,
          style:
              textStyle ??
              CustomAppFontStyle.regular12.copyWith(color: AppColors.primary),
        ),
        ?lastWidget,
      ],
    );
  }
}
