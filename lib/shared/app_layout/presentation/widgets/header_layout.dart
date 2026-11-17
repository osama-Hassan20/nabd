import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_cubit.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_state.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_list_tile.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

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
            // Quick Lock Button (Telegram-style lock icon)
            _buildQuickLockButton(context),
            const SizedBox(width: 8),
            // Branch Switcher on Mobile/Tablet
            const HeaderBranchSwitcher(),
            const SizedBox(width: 8),
            _buildProfileAvatar(context),
          ],
        ),
      );
    }

    // Desktop: Render Full Header Layout with Branch Switcher & Quick Lock
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
            // Telegram-style Quick Passcode Lock Button
            _buildQuickLockButton(context),
            // Branch Switcher (only shows if user has multiple branches)
            const HeaderBranchSwitcher(),
            // User Avatar & Settings/Logout
            _buildProfileAvatar(context),
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

  Widget _buildProfileAvatar(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'profile'.tr(),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.grayE2E8F0),
      ),
      onSelected: (value) {
        if (value == 'settings') {
          context.go(AppRouter.settings);
        } else if (value == 'logout') {
          getIt<SessionCubit>().logout();
          context.go(AppRouter.login);
        }
      },
      itemBuilder: (ctx) {
        final session = getIt<SessionCubit>();
        final userName = session.currentUser?.fullName ?? session.state.userName ?? 'المستخدم';
        final jobTitle = session.currentUser?.jobTitle ?? '';

        return [
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: CustomAppFontStyle.bold14.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                if (jobTitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    jobTitle,
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ],
                const Divider(color: AppColors.grayE2E8F0),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'settings',
            child: Row(
              children: [
                const Icon(Icons.settings_outlined, size: 20, color: AppColors.gray71717A),
                const SizedBox(width: 12),
                Text('settings'.tr(), style: CustomAppFontStyle.medium14),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                const Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
                const SizedBox(width: 12),
                Text(
                  'log_out'.tr(),
                  style: CustomAppFontStyle.medium14.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.fillDisableColor, width: 2),
          color: AppColors.primaryLight,
        ),
        child: const Center(
          child: Icon(
            Icons.person_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
