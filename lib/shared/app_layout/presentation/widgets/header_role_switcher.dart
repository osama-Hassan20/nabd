import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/user_role_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';

class HeaderRoleSwitcher extends StatelessWidget {
  const HeaderRoleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final sessionCubit = getIt<SessionCubit>();

    return BlocBuilder<SessionCubit, SessionState>(
      bloc: sessionCubit,
      builder: (context, state) {
        final currentRole = state.currentRole ?? UserRoleEnum.admin;

        return PopupMenuButton<UserRoleEnum>(
          tooltip: 'تبديل الدور (وضع التطوير)',
          onSelected: (role) {
            sessionCubit.switchRole(role);
          },
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.grayE2E8F0),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: UserRoleEnum.admin,
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Admin (مدير)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: UserRoleEnum.doctor,
              child: Row(
                children: [
                  Icon(Icons.medical_services, size: 18, color: AppColors.secondary),
                  SizedBox(width: 8),
                  Text('Doctor (طبيب)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: UserRoleEnum.reception,
              child: Row(
                children: [
                  Icon(Icons.support_agent, size: 18, color: AppColors.warning),
                  SizedBox(width: 8),
                  Text('Reception (استقبال)'),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bug_report_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'DEV: ${currentRole.name}',
                  style: CustomAppFontStyle.semiBold12.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

