import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:popover/popover.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_cubit.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
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

    showPopover(
      context: buttonContext,
      direction: PopoverDirection.bottom,
      width: 250,
      height: 310,
      arrowHeight: 10,
      arrowWidth: 20,
      radius: 16,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
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
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.grayE2E8F0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Initials Circle Avatar
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFCCFBF1), // Mint Teal (Matches Image 4)
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: CustomAppFontStyle.bold13.copyWith(
                        color: const Color(0xFF0F766E), // Dark Teal
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // User Name
                Text(
                  userName,
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(width: 4),

                // Down Chevron
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.gray71717A,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
