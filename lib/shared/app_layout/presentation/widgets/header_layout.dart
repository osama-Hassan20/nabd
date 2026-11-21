import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_cubit.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_state.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_list_tile.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

import 'header_branch_switcher.dart';
import 'header_reception_signal_widget.dart';
import 'header_user_profile_widget.dart';

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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.themeColors.borderSubtle),
        ),
        child: Row(
          children: [
            // Menu / Drawer Button for Mobile & Tablet
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: context.themeColors.surfaceLevel1,
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
              icon: CustomAssetImage(
                path: AppIcons.drawer,
                color: context.themeColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title ?? 'dashboard'.tr(),
                style: CustomAppFontStyle.bold18.copyWith(
                  color: context.themeColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Reception Buzzer Signal Button (Matches Images 1 & 2)
            const HeaderReceptionSignalWidget(),
            const SizedBox(width: 8),
            // Quick Lock Button (Telegram-style lock icon - Matches Image 9)
            _buildQuickLockButton(context),
            const SizedBox(width: 8),
            // Branch Switcher on Mobile/Tablet
            const HeaderBranchSwitcher(),
            const SizedBox(width: 8),
            // User Profile Widget (Matches Image 4)
            const HeaderUserProfileWidget(),
          ],
        ),
      );
    }

    // Desktop: Render Full Header Layout with Signal, Branch Switcher & Quick Lock
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 12),
      child: CustomListTile(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        border: Border.all(color: Colors.transparent),
        title: title ?? 'dashboard_header'.tr(),
        subtitle: subtitle ?? 'dashboard_subtitle'.tr(),
        titleTextStyle: CustomAppFontStyle.regular24.copyWith(
          color: context.themeColors.textPrimary,
        ),
        subTitleStyle: CustomAppFontStyle.regular14.copyWith(
          color: context.themeColors.textSecondary,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            // Reception Buzzer Signal Button (Matches Images 1 & 2)
            const HeaderReceptionSignalWidget(),
            // Telegram-style Quick Passcode Lock Button (Matches Image 9)
            _buildQuickLockButton(context),
            // Branch Switcher (only shows if user has multiple branches)
            const HeaderBranchSwitcher(),
            // User Profile Widget (Initials + Name + Dropdown - Matches Image 4)
            const HeaderUserProfileWidget(),
          ],
        ),
      ),
    );
  }

  /// Telegram-style Lock Button in the Header (Matches Screenshot 9)
  Widget _buildQuickLockButton(BuildContext context) {
    if (!getIt.isRegistered<LocalPasscodeCubit>()) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<LocalPasscodeCubit, LocalPasscodeState>(
      bloc: getIt<LocalPasscodeCubit>(),
      builder: (context, state) {
        if (!state.isEnabled) return const SizedBox.shrink();

        return Tooltip(
          message: 'quick_lock_tooltip'.tr(),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              getIt<LocalPasscodeCubit>().lock();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
