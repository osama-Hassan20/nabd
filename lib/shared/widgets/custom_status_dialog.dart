import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:go_router/go_router.dart';

class CustomStatusDialog extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool activate;
  final String? iconPath;

  final VoidCallback? onConfirm;
  final double iconSize;

  const CustomStatusDialog({
    super.key,
    required this.title,
    required this.subtitle,
    this.activate = true,

    required this.onConfirm,
    this.iconPath,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomAssetImage(
              path:
                  iconPath ??
                  (!activate
                      ? AppIcons.activeSwitcher
                      : AppIcons.inActiveSwitcher),
              width: iconSize,
              height: iconSize,
            ),
            const SizedBox(height: 24),
            Text(
              title ?? "",
              style: CustomAppFontStyle.medium15.copyWith(
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle ?? "",
              style: CustomAppFontStyle.regular14.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: CustomPushButton(
                    height: 48,
                    backgroundColor: colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      context.pop();
                    },
                    child: Center(
                      child: Text(
                        "الغاء",
                        style: CustomAppFontStyle.regular14.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CustomPushButton(
                    height: 48,
                    backgroundColor: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                    onTap: onConfirm,
                    child: Center(
                      child: Text(
                        "تأكيد",
                        style: CustomAppFontStyle.regular15.copyWith(
                          color: Colors.white,
                        ),
                      ),
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

class CustomDeleteDialog extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final VoidCallback? onConfirm;

  const CustomDeleteDialog({
    super.key,
    this.title,
    this.subtitle,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomAssetImage(
              path: AppIcons.delete,
              width: 36,
              height: 36,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              title ?? "",
              style: CustomAppFontStyle.medium15.copyWith(
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle ?? "",
              style: CustomAppFontStyle.regular14.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: CustomPushButton(
                    height: 48,
                    backgroundColor: colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      context.pop();
                    },
                    child: Center(
                      child: Text(
                        "الغاء",
                        style: CustomAppFontStyle.regular14.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CustomPushButton(
                    height: 48,
                    backgroundColor: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                    onTap: onConfirm,
                    child: Center(
                      child: Text(
                        "حذف",
                        style: CustomAppFontStyle.regular15.copyWith(
                          color: Colors.white,
                        ),
                      ),
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
