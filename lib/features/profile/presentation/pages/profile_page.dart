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
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/settings/presentation/widgets/dialogs/local_passcode_dialogs.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      bloc: getIt<SessionCubit>(),
      builder: (context, sessionState) {
        final user = sessionState.currentUser;
        final fullName = user?.fullName ?? sessionState.userName ?? 'المستخدم';
        final jobTitle = user?.jobTitle ?? 'طاقم العمل الطبي';
        final email = user?.email ?? 'غير محدد';
        final phone = user?.phone ?? 'غير محدد';
        final isOwner = user?.isOwner ?? false;
        final initials = _getInitials(fullName);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Hero Header Card
                  CustomContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.grayE2E8F0),
                    backGroundColor: AppColors.white,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Initials Big Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: CustomAppFontStyle.bold24.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Name & Role Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    fullName,
                                    style: CustomAppFontStyle.bold20.copyWith(
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                  if (isOwner) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.workspace_premium_rounded,
                                            size: 14,
                                            color: Color(0xFFD97706),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'مالك المنشأة',
                                            style: CustomAppFontStyle.medium12.copyWith(
                                              color: const Color(0xFFD97706),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                jobTitle,
                                style: CustomAppFontStyle.regular14.copyWith(
                                  color: AppColors.gray71717A,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Active Status Badge
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'الحساب نشط ومتصل بالنظام',
                                    style: CustomAppFontStyle.medium12.copyWith(
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 1: Contact & Personal Info
                  Text(
                    'البيانات الشخصية وبيانات الاتصال',
                    style: CustomAppFontStyle.bold16.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomContainer(
                    padding: const EdgeInsets.all(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.grayE2E8F0),
                    backGroundColor: AppColors.white,
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.email_outlined,
                          label: 'البريد الإلكتروني',
                          value: email,
                        ),
                        const Divider(color: AppColors.grayE2E8F0, height: 24),
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'رقم الهاتف',
                          value: phone,
                        ),
                        const Divider(color: AppColors.grayE2E8F0, height: 24),
                        _buildInfoRow(
                          icon: Icons.badge_outlined,
                          label: 'الفرع الرئيسي',
                          value: sessionState.activeBranchId == 'branch_1'
                              ? 'فرع المهندسين (الرئيسي)'
                              : (sessionState.activeBranchId == 'branch_2'
                                  ? 'فرع المعادي'
                                  : 'فرع التجمع'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 2: Security & Local Passcode
                  Text(
                    'الأمان والخصوصية',
                    style: CustomAppFontStyle.bold16.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  BlocBuilder<LocalPasscodeCubit, LocalPasscodeState>(
                    bloc: getIt<LocalPasscodeCubit>(),
                    builder: (context, passcodeState) {
                      return CustomContainer(
                        padding: const EdgeInsets.all(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grayE2E8F0),
                        backGroundColor: AppColors.white,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: passcodeState.isEnabled
                                            ? AppColors.primaryLight
                                            : AppColors.fillDisableColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        passcodeState.isEnabled
                                            ? Icons.lock_rounded
                                            : Icons.lock_open_rounded,
                                        color: passcodeState.isEnabled
                                            ? AppColors.primary
                                            : AppColors.gray71717A,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'رمز القفل المحلي (Local Passcode)',
                                          style: CustomAppFontStyle.semiBold14.copyWith(
                                            color: AppColors.darkText,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          passcodeState.isEnabled
                                              ? 'مفعّل - القفل التلقائي بعد ${passcodeState.autoLockMinutes} دقيقة'
                                              : 'معطّل - انقر لإنشاء رمز قفل لحماية الشاشة',
                                          style: CustomAppFontStyle.regular12.copyWith(
                                            color: AppColors.gray71717A,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                CustomPushButton(
                                  height: 36,
                                  radius: 10,
                                  backgroundColor: passcodeState.isEnabled
                                      ? AppColors.fillDisableColor
                                      : AppColors.primary,
                                  onTap: () {
                                    if (passcodeState.isEnabled) {
                                      ManageLocalPasscodeDialog.show(context);
                                    } else {
                                      CreateLocalPasscodeDialog.show(context);
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Center(
                                      child: Text(
                                        passcodeState.isEnabled ? 'إدارة' : 'تفعيل',
                                        style: CustomAppFontStyle.semiBold13.copyWith(
                                          color: passcodeState.isEnabled
                                              ? AppColors.darkText
                                              : AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  CustomPushButton(
                    height: 48,
                    radius: 12,
                    backgroundColor: const Color(0xFFFEE2E2),
                    onTap: () {
                      getIt<SessionCubit>().logout();
                      context.go(AppRouter.login);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'تسجيل الخروج من الحساب',
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: AppColors.error,
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
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.gray71717A),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: CustomAppFontStyle.regular12.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: CustomAppFontStyle.medium14.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
