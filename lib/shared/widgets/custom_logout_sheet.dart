import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/routing/app_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';

import '../../core/utils/theme/app_colors.dart';
import '../../core/utils/theme/app_icons.dart';
import '../../core/utils/theme/custom_app_font_styles.dart';
import '../../shared/widgets/custom_push_container_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/shared/cubit/basic_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/services/notification_service.dart';
import 'package:go_router/go_router.dart';

class CustomLogOutSheet extends StatelessWidget {
  const CustomLogOutSheet({
    super.key,
    required this.onTap,
    this.isLoading = false,
    this.title,
    this.description,
    this.cancelText,
    this.logoutText,
  });

  final void Function() onTap;
  final bool isLoading;
  final String? title, description, cancelText, logoutText;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return SafeArea(
      child: Dialog(
        backgroundColor: colors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderSubtle),
        ),
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CustomAssetImage(
                    path: AppIcons.logoutSheet,
                    width: 32,
                    height: 32,
                    color: AppColors.red,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title ?? "هل أنت متأكد من تسجيل الخروج؟",
                style: CustomAppFontStyle.bold18.copyWith(
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description ??
                    "سيتم إنهاء جلستك الحالية، وستحتاج إلى تسجيل الدخول مرة أخرى.",
                style: CustomAppFontStyle.regular14.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomPushButton(
                      height: 44,
                      onTap: isLoading ? null : () => context.pop(),
                      backgroundColor: colors.surfaceLevel1,
                      boxBorder: Border.all(color: colors.borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      radius: 12,
                      child: Text(
                        cancelText ?? "إلغاء",
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomPushButton(
                      height: 44,
                      isLoading: isLoading,
                      onTap: () {
                        // 1. Close dialog cleanly first
                        Navigator.of(context, rootNavigator: true).pop();

                        // 2. Perform session logout
                        if (getIt.isRegistered<SessionCubit>()) {
                          getIt<SessionCubit>().logout();
                        }
                        try {
                          getIt<NotificationService>().removeTokenFromBackend();
                        } catch (_) {}
                        try {
                          context.read<BasicCubit>().clearData();
                        } catch (_) {}

                        // 3. Callback
                        try {
                          onTap();
                        } catch (_) {}

                        // 4. Force router redirect
                        try {
                          appRouter.go(AppRouter.login);
                        } catch (_) {}
                      },
                      backgroundColor: AppColors.red,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      radius: 12,
                      child: Center(
                        child: Text(
                          logoutText ?? "تأكيد تسجيل الخروج",
                          style: CustomAppFontStyle.semiBold14.copyWith(
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
      ),
    );
  }
}
