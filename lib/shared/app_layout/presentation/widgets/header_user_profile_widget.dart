import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:popover/popover.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_cubit.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/cubits/theme/app_theme_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_theme_mode.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/settings/presentation/widgets/dialogs/local_passcode_dialogs.dart';

class HeaderUserProfileWidget extends StatelessWidget {
  const HeaderUserProfileWidget({super.key});

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final cleaned = name.replaceAll(RegExp(r'^(د\.|م\.|أ\.)\s*'), '').trim();
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]} ${parts[1][0]}'.toUpperCase();
  }

  void _showProfilePopover(
    BuildContext buttonContext,
    String userName,
    String jobTitle,
  ) {
    final isDark = buttonContext.isDarkMode;
    final colors = buttonContext.themeColors;

    showPopover(
      context: buttonContext,
      direction: PopoverDirection.bottom,
      width: 270,
      height: 390,
      arrowHeight: 10,
      arrowWidth: 20,
      radius: 16,
      backgroundColor: colors.cardBackground,
      barrierColor: Colors.black26,
      bodyBuilder: (popoverCtx) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Info (Matches Image 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: CustomAppFontStyle.bold15.copyWith(
                      color: isDark ? AppColors.white : AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    jobTitle,
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.gray334155 : AppColors.grayE2E8F0,
            ),

            // 1. الملف الشخصي (Profile)
            _buildMenuItem(
              popoverCtx: popoverCtx,
              icon: Icons.account_circle_outlined,
              label: 'profile'.tr(),
              isDark: isDark,
              onTap: () {
                Navigator.of(popoverCtx).pop();
                buttonContext.go(AppRouter.profile);
              },
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.gray334155 : AppColors.grayE2E8F0,
            ),

            // 2. الإشعارات (Notifications)
            _buildMenuItem(
              popoverCtx: popoverCtx,
              icon: Icons.notifications_outlined,
              label: 'notifications'.tr(),
              isDark: isDark,
              onTap: () {
                Navigator.of(popoverCtx).pop();
                buttonContext.go(AppRouter.notifications);
              },
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.gray334155 : AppColors.grayE2E8F0,
            ),

            // 3. الأمان (Security)
            _buildMenuItem(
              popoverCtx: popoverCtx,
              icon: Icons.security_outlined,
              label: 'الأمان',
              isDark: isDark,
              onTap: () {
                Navigator.of(popoverCtx).pop();
                final passcodeCubit = getIt<LocalPasscodeCubit>();
                if (passcodeCubit.state.isEnabled) {
                  ManageLocalPasscodeDialog.show(buttonContext);
                } else {
                  CreateLocalPasscodeDialog.show(buttonContext);
                }
              },
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.gray334155 : AppColors.grayE2E8F0,
            ),

            // 4. الإعدادات (Settings)
            _buildMenuItem(
              popoverCtx: popoverCtx,
              icon: Icons.settings_outlined,
              label: 'settings'.tr(),
              isDark: isDark,
              onTap: () {
                Navigator.of(popoverCtx).pop();
                buttonContext.go(AppRouter.settings);
              },
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.gray334155 : AppColors.grayE2E8F0,
            ),

            // 4.5 تبديل النمط السريع (Theme Quick Switch)
            _buildThemeSelectorItem(
              popoverCtx: popoverCtx,
              buttonContext: buttonContext,
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.gray334155 : AppColors.grayE2E8F0,
            ),

            // 5. تسجيل الخروج (Log out - Red)
            _buildMenuItem(
              popoverCtx: popoverCtx,
              icon: Icons.logout_rounded,
              label: 'log_out'.tr(),
              isDark: isDark,
              textColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: () {
                Navigator.of(popoverCtx).pop();
                getIt<SessionCubit>().logout();
                buttonContext.go(AppRouter.login);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext popoverCtx,
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? (isDark ? AppColors.white : AppColors.darkText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: CustomAppFontStyle.medium14.copyWith(
                  color: textColor ?? (isDark ? AppColors.white : AppColors.darkText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      bloc: getIt<SessionCubit>(),
      builder: (context, state) {
        final user = state.currentUser;
        final userName = user?.fullName ?? state.userName ?? 'المستخدم';
        final jobTitle = user?.isOwner == true
            ? 'طبيب مالك'
            : (user?.jobTitle ?? 'طاقم العيادة');
        final initials = _getInitials(userName);

        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            _showProfilePopover(context, userName, jobTitle);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.themeColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Initials Circle Avatar
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.themeColors.primaryLight,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: CustomAppFontStyle.bold13.copyWith(
                        color: context.themeColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // User Name
                Text(
                  userName,
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: context.themeColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),

                // Down Chevron
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: context.themeColors.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeSelectorItem({
    required BuildContext popoverCtx,
    required BuildContext buttonContext,
  }) {
    if (!getIt.isRegistered<AppThemeCubit>()) {
      return const SizedBox.shrink();
    }

    final cubit = getIt<AppThemeCubit>();
    final currentMode = buttonContext.appThemeMode;
    final colors = buttonContext.themeColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'المظهر (Multi Mode)',
                style: CustomAppFontStyle.medium13.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: AppThemeMode.values.map((mode) {
              final isSelected = mode == currentMode;
              final modeColors = AppThemeColors.forMode(mode);

              return Tooltip(
                message: _getThemeName(mode),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    cubit.setThemeMode(mode);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: modeColors.scaffoldBackground,
                      border: Border.all(
                        color: isSelected
                            ? modeColors.primary
                            : modeColors.borderSubtle,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: modeColors.primary.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: modeColors.primary,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 8, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'نهاري';
      case AppThemeMode.dark:
        return 'داكن';
      case AppThemeMode.sunny:
        return 'مشمس';
      case AppThemeMode.night:
        return 'ليلي';
      case AppThemeMode.emerald:
        return 'زمردي';
    }
  }
}
