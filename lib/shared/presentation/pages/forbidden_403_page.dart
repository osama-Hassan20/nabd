import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/routes.dart';
import '../../../core/utils/theme/app_colors.dart';
import '../../../core/utils/theme/custom_app_font_styles.dart';
import '../../widgets/custom_push_container_button.dart';

class Forbidden403Page extends StatelessWidget {
  const Forbidden403Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_person_rounded,
                    color: AppColors.error,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'forbidden_403_title'.tr(),
                style: CustomAppFontStyle.bold22.copyWith(
                  color: AppColors.darkText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'forbidden_403_subtitle'.tr(),
                style: CustomAppFontStyle.regular14.copyWith(
                  color: AppColors.gray7A828E,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              CustomPushButton(
                height: 48,
                backgroundColor: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  context.go(AppRouter.bookings);
                },
                child: Center(
                  child: Text(
                    'forbidden_403_back_home'.tr(),
                    style: CustomAppFontStyle.bold14.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

