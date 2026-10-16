import 'package:purexo/core/utils/extensions/theme_mode_extensions.dart';

import '../../core/utils/theme/app_colors.dart';
import '../../core/utils/theme/custom_app_font_styles.dart';
import '../../shared/widgets/custom_push_container_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class CustomTwoOptionDialog extends StatelessWidget {
  const CustomTwoOptionDialog({
    super.key,
    required this.title,
    this.firstOption,
    this.backGroundColor,
    required this.buttonTitle,
    required this.onTap,
    this.iconPathBeside,
    this.isLoading = false,
    this.iconColor,
    this.contentWidget,
    this.titleTextStyle,
    this.subTitle,
    this.cancelTitle,
    this.cancelTitleTextStyle,
    this.subTitleTextStyle,
    this.titleTextAlign,
  });

  final String title;
  final String? cancelTitle;
  final Widget? subTitle;
  final Widget? firstOption;
  final Color? backGroundColor;
  final String buttonTitle;
  final void Function() onTap;
  final String? iconPathBeside;
  final bool isLoading;
  final Color? iconColor;
  final Widget? contentWidget;
  final TextStyle? titleTextStyle;
  final TextStyle? cancelTitleTextStyle;
  final TextStyle? subTitleTextStyle;
  final TextAlign? titleTextAlign;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = context.isDarkMode;
    return Dialog(
      constraints: BoxConstraints(maxWidth: 700),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 24,
          mainAxisSize: MainAxisSize.min,
          children: [
            ?contentWidget,
            Text(
              title,
              style: titleTextStyle ?? CustomAppFontStyle.regular14,
              textAlign: titleTextAlign,
            ),
            ?subTitle,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                firstOption ??
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        cancelTitle ?? "إلغاء",
                        style:
                            cancelTitleTextStyle ??
                            CustomAppFontStyle.regular12.copyWith(
                              color: isDarkMode
                                  ? AppColors.white
                                  : AppColors.gray334155,
                            ),
                      ),
                    ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 2,
                  child: CustomPushButton(
                    height: 48,
                    onTap: onTap,
                    isLoading: isLoading,
                    child: Row(
                      spacing: 8,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(buttonTitle, style: CustomAppFontStyle.medium16),

                        if (iconPathBeside != null)
                          SvgPicture.asset(
                            iconPathBeside!,
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              iconColor ?? AppColors.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
