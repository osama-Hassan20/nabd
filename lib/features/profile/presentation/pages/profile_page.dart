import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_cubit.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_state.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_gradient.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/settings/presentation/widgets/dialogs/change_password_dialog.dart';
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
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;

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

        final branchName = sessionState.activeBranchId == 'branch_1'
            ? 'فرع المهندسين (الرئيسي)'
            : (sessionState.activeBranchId == 'branch_2'
                ? 'فرع المعادي'
                : 'فرع التجمع');

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Profile Hero Header Card (Full Width) ─────────────────
                _buildHeroCard(
                  fullName: fullName,
                  jobTitle: jobTitle,
                  initials: initials,
                  isOwner: isOwner,
                  isDesktop: isDesktop,
                  branchName: branchName,
                ),
                const SizedBox(height: 20),

                // ─── Main Content Grid (Balanced 2 Columns on Desktop) ─────
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Right Column: Personal & Contact Information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSectionHeader(
                              'البيانات الشخصية وبيانات الاتصال',
                              Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 10),
                            _buildPersonalInfoCard(
                              email: email,
                              phone: phone,
                              branchName: branchName,
                              isOwner: isOwner,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Left Column: Security, Privacy & Account Actions
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSectionHeader(
                              'الأمان والخصوصية',
                              Icons.shield_outlined,
                            ),
                            const SizedBox(height: 10),
                            _buildSecurityCard(context),
                            const SizedBox(height: 16),
                            _buildLogoutButton(context),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  // Mobile & Tablet Layout (Single Full-Width Column)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionHeader(
                        'البيانات الشخصية وبيانات الاتصال',
                        Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                      _buildPersonalInfoCard(
                        email: email,
                        phone: phone,
                        branchName: branchName,
                        isOwner: isOwner,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        'الأمان والخصوصية',
                        Icons.shield_outlined,
                      ),
                      const SizedBox(height: 10),
                      _buildSecurityCard(context),
                      const SizedBox(height: 20),
                      _buildLogoutButton(context),
                    ],
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: CustomAppFontStyle.bold16.copyWith(
            color: AppColors.darkText,
          ),
        ),
      ],
    );
  }

  // ─── Hero Card ─────────────────────────────────────────────────────────────
  Widget _buildHeroCard({
    required String fullName,
    required String jobTitle,
    required String initials,
    required bool isOwner,
    required bool isDesktop,
    required String branchName,
  }) {
    return CustomContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.grayE2E8F0),
      backGroundColor: AppColors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Initials Big Avatar with Gradient
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradient.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      fullName,
                      style: CustomAppFontStyle.bold20.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                    if (isOwner)
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
                ),
                const SizedBox(height: 6),
                Text(
                  jobTitle,
                  style: CustomAppFontStyle.regular14.copyWith(
                    color: AppColors.gray71717A,
                  ),
                ),
                const SizedBox(height: 8),
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

          // Desktop Quick Info Badges
          if (isDesktop) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLevel1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grayE2E8F0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الفرع المتصل به حالياً',
                    style: CustomAppFontStyle.regular11.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        branchName,
                        style: CustomAppFontStyle.bold13.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Personal Info Card ────────────────────────────────────────────────────
  Widget _buildPersonalInfoCard({
    required String email,
    required String phone,
    required String branchName,
    required bool isOwner,
  }) {
    return CustomContainer(
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
            icon: Icons.business_outlined,
            label: 'الفرع الرئيسي التابع له',
            value: branchName,
          ),
          const Divider(color: AppColors.grayE2E8F0, height: 24),
          _buildInfoRow(
            icon: Icons.verified_user_outlined,
            label: 'مستوى الصلاحية بالنظام',
            value: isOwner
                ? 'وصول إداري كامل للمنشأة وكافة الفروع'
                : 'صلاحيات مخصصة حسب الدور الطبي',
          ),
        ],
      ),
    );
  }

  // ─── Security Card ─────────────────────────────────────────────────────────
  Widget _buildSecurityCard(BuildContext context) {
    return BlocBuilder<LocalPasscodeCubit, LocalPasscodeState>(
      bloc: getIt<LocalPasscodeCubit>(),
      builder: (context, passcodeState) {
        return CustomContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grayE2E8F0),
          backGroundColor: AppColors.white,
          child: Column(
            children: [
              // Row 1: Local Passcode
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
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
                        Expanded(
                          child: Column(
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
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CustomPushButton(
                    height: 36,
                    radius: 8,
                    backgroundColor: passcodeState.isEnabled
                        ? AppColors.surfaceLevel1
                        : AppColors.primary,
                    boxBorder: Border.all(
                      color: passcodeState.isEnabled
                          ? AppColors.grayE2E8F0
                          : AppColors.primary,
                    ),
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
              const Divider(color: AppColors.grayE2E8F0, height: 28),

              // Row 2: Account Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.key_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'كلمة مرور الحساب',
                                style: CustomAppFontStyle.semiBold14.copyWith(
                                  color: AppColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'تحديث كلمة المرور الدخول للنظام والمنشأة',
                                style: CustomAppFontStyle.regular12.copyWith(
                                  color: AppColors.gray71717A,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CustomPushButton(
                    height: 36,
                    radius: 8,
                    backgroundColor: AppColors.surfaceLevel1,
                    boxBorder: Border.all(color: AppColors.grayE2E8F0),
                    onTap: () => ChangePasswordDialog.show(context: context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Center(
                        child: Text(
                          'تغيير',
                          style: CustomAppFontStyle.semiBold13.copyWith(
                            color: AppColors.darkText,
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
    );
  }

  // ─── Logout Button ─────────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return CustomPushButton(
      height: 46,
      radius: 12,
      backgroundColor: const Color(0xFFFEE2E2),
      boxBorder: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
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
    );
  }

  // ─── Helper Info Row ───────────────────────────────────────────────────────
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
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
