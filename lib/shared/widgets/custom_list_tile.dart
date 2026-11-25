import 'package:eyadty/core/layout_adaptive/widgets/custom_text.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';

import '../../../core/utils/theme/app_colors.dart';
import '../../../core/utils/theme/app_icons.dart';
import '../../../core/utils/theme/custom_app_font_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomListTile extends StatelessWidget {
  const CustomListTile({
    super.key,
    this.backgroundColor,
    this.padding,
    this.title,
    this.titleTextDirection,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.subTitleStyle,
    this.titleTextStyle,
    this.subTitleInstead,
    this.leadingIconPath,
    this.titleColor,
    this.iconColor,
    this.enableColor = true,
    this.enableArrow = false,
    this.topPaddingInLeadingIcon = 0,
    this.leadingSize,
    this.titleMaxLines = 1,
    this.subtitleMaxLines = 1,
    this.trailing,
    this.expantionWidget,
    this.borderRaduis = 8,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.titleInstead,
    this.leadingIconInstead,
    this.enableShadow = false,
    this.border,
    this.spacing,
    this.subtitleTextDirection,
    this.horizontalSpacing,
    this.trailingText,
    this.trailingTextStyle,
    this.mainAxisSize = MainAxisSize.min,
    this.enableSelectableText = true,
    this.trailingTextDirection,
    this.textAlign = TextAlign.end,
  });

  final Color? backgroundColor;
  final String? title;
  final String? subtitle;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final String? leadingIconPath;
  final Color? titleColor;
  final Size? leadingSize;
  final Color? iconColor;
  final TextStyle? subTitleStyle;
  final bool enableArrow;
  final EdgeInsetsGeometry? padding;
  final Widget? titleInstead;
  final Widget? subTitleInstead;
  final bool enableColor;
  final Widget? trailing;
  final CrossAxisAlignment crossAxisAlignment;
  final double borderRaduis;
  final double topPaddingInLeadingIcon;
  final TextStyle? titleTextStyle;
  final int titleMaxLines;
  final int subtitleMaxLines;
  final TextDirection? titleTextDirection;
  final TextDirection? trailingTextDirection;
  final Widget? leadingIconInstead;
  final Widget? expantionWidget;
  final bool enableShadow;
  final Border? border;
  final double? spacing;
  final TextDirection? subtitleTextDirection;
  final double? horizontalSpacing;
  final String? trailingText;
  final TextStyle? trailingTextStyle;
  final MainAxisSize mainAxisSize;
  final bool enableSelectableText;
  final TextAlign textAlign;
  @override
  Widget build(BuildContext context) {
    bool isDark = context.isDarkMode;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          // border:
          //     border ??
          //     Border.all(
          //       color: isDark ? AppColors.borderLight : AppColors.borderLight,
          //     ),
          boxShadow: enableShadow
              ? [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
          color:
              backgroundColor ??
              (isDark ? AppColors.darkBackground : AppColors.fillDisableColor),
          borderRadius: BorderRadius.circular(borderRaduis),
        ),
        child: Column(
          mainAxisSize: mainAxisSize,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: expantionWidget != null ? spacing ?? 5 : spacing ?? 0,
          children: [
            Row(
              mainAxisSize: mainAxisSize,
              crossAxisAlignment: crossAxisAlignment,
              children: [
                if (leadingIconPath != null)
                  Padding(
                    padding: EdgeInsets.only(top: topPaddingInLeadingIcon),
                    child: SvgPicture.asset(
                      leadingIconPath!,
                      width: leadingSize?.width ?? 20,
                      height: leadingSize?.height ?? 20,
                      colorFilter: enableColor
                          ? ColorFilter.mode(
                              iconColor ?? AppColors.gray334155,
                              BlendMode.srcIn,
                            )
                          : null,
                    ),
                  ),
                ?leadingIconInstead,
                if (leadingIconPath != null || leadingIconInstead != null)
                  SizedBox(width: horizontalSpacing ?? 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: spacing ?? 4,
                    children: [
                      titleInstead ??
                          CustomText(
                            title ?? "",
                            isSelectable: enableSelectableText,
                            maxLines: titleMaxLines,
                            textDirection: titleTextDirection,
                            overflow: TextOverflow.ellipsis,
                            style:
                                titleTextStyle ??
                                CustomAppFontStyle.regular16.copyWith(
                                  color: titleColor ?? AppColors.gray334155,
                                ),
                          ),
                      if (subTitleInstead != null)
                        subTitleInstead!
                      else if (subtitle != null)
                        CustomText(
                          subtitle!,
                          maxLines: subtitleMaxLines,
                          overflow: TextOverflow.ellipsis,
                          textDirection: subtitleTextDirection,
                          style: subTitleStyle ?? CustomAppFontStyle.light14,
                        ),
                    ],
                  ),
                ),
                if (enableArrow) const SizedBox(width: 12),
                if (enableArrow)
                  RotatedBox(
                    quarterTurns: 2,
                    child: SvgPicture.asset(AppIcons.arrowBack),
                  ),
                if (trailing != null)
                  trailing!
                else if (trailingText != null)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: CustomText(
                        trailingText!,
                        maxLines: 2,
                        textAlign: textAlign,
                        overflow: TextOverflow.ellipsis,
                        textDirection: trailingTextDirection,
                        style:
                            trailingTextStyle ??
                            CustomAppFontStyle.regular14.copyWith(
                              color: AppColors.darkBackground,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
            ?expantionWidget,
          ],
        ),
      ),
    );
  }
}
