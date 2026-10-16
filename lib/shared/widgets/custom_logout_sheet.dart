import 'package:purexo/core/storage/cache_helper.dart';
import 'package:purexo/core/utils/extensions/theme_mode_extensions.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';

import '../../core/utils/theme/app_colors.dart';
import '../../core/utils/theme/app_icons.dart';
import '../../core/utils/theme/custom_app_font_styles.dart';
import '../../shared/widgets/custom_push_container_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purexo/shared/cubit/basic_cubit.dart';
import 'package:purexo/core/dependency_injection/dependency_injection.dart';
import 'package:purexo/core/services/notification_service.dart';
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
    bool isDark = context.isDarkMode;
    return SafeArea(
      child: Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        constraints: BoxConstraints(maxWidth: 650),

        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Center(
                child: CustomAssetImage(
                  path: AppIcons.logoutSheet,
                  width: 40,
                  height: 40,
                  color: AppColors.red,
                ),
              ),
              const SizedBox(),
              Text(
                title ?? "هل أنت متأكد من تسجيل الخروج؟",
                style: CustomAppFontStyle.regular24,
              ),
              Text(
                description ?? "سيتم إنهاء جلستك الحالية، وستحتاج إلى تسجيل الدخول مرة أخرى.",
                style: CustomAppFontStyle.regular16.copyWith(
                  color: AppColors.gray334155,
                ),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: CustomPushButton(
                        height: 48,

                        onTap: isLoading ? null : () => context.pop(),
                        backgroundColor: isDark
                            ? AppColors.darkBackground
                            : AppColors.grayf2,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        radius: 24,

                        child: Text(
                          cancelText ?? "إلغاء",
                          style: CustomAppFontStyle.regular16.copyWith(
                            color: AppColors.gray334155,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: CustomPushButton(
                        height: 48,
                        isLoading: isLoading,
                        onTap: () {
                          onTap();
                          try {
                            getIt<NotificationService>()
                                .removeTokenFromBackend();
                          } catch (_) {}
                          AppSharedPreferences.clearAll();
                          context.read<BasicCubit>().clearData();
                        },
                        backgroundColor: AppColors.red02,
                        padding: const EdgeInsets.symmetric(vertical: 13.5),
                        radius: 24,
                        child: Center(
                          child: Text(
                            logoutText ?? "تأكيد تسجيل الخروج",
                            style: CustomAppFontStyle.regular16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
