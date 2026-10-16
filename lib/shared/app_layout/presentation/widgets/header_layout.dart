import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_list_tile.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'package:go_router/go_router.dart';

import 'header_branch_switcher.dart';

class CustomHeaderLayout extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomHeaderLayout({
    super.key,
    required this.isLogin,
    required this.scaffoldKey,
    this.title,
    this.subtitle,
  });

  final bool isLogin;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String? title;
  final String? subtitle;

  @override
  Size get preferredSize => const Size.fromHeight(75);

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = AdaptiveLayout.isDesktop(context);

    // Mobile & Tablet: Render Custom Responsive AppBar
    if (!isDesktop) {
      return Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fillDisableColor),
        ),
        child: Row(
          children: [
            // Menu / Drawer Button for Mobile & Tablet
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.fillDisableColor,
                fixedSize: const Size(44, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              iconSize: 22,
              tooltip: 'menu'.tr(),
              onPressed: () {
                scaffoldKey.currentState?.openDrawer();
              },
              icon: const CustomAssetImage(
                path: AppIcons.drawer,
                color: AppColors.gray7A828E,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title ?? 'dashboard'.tr(),
                style: CustomAppFontStyle.bold18.copyWith(
                  color: AppColors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Branch Switcher on Mobile/Tablet
            const HeaderBranchSwitcher(),
            const SizedBox(width: 8),
            _buildProfileAvatar(context),
          ],
        ),
      );
    }

    // Desktop: Render Full Header Layout with Branch Switcher
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 12),
      child: CustomListTile(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        border: Border.all(color: Colors.transparent),
        title: title ?? 'dashboard_header'.tr(),
        subtitle: subtitle ?? 'dashboard_subtitle'.tr(),
        titleTextStyle: CustomAppFontStyle.regular24.copyWith(
          color: AppColors.black,
        ),
        subTitleStyle: CustomAppFontStyle.regular14.copyWith(
          color: AppColors.gray7A828E,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            const HeaderBranchSwitcher(),
            _buildProfileAvatar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        context.go(AppRouter.settings);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.fillDisableColor, width: 2),
        ),
        child: const Center(child: CustomAssetImage(path: AppIcons.settings)),
      ),
    );
  }
}
