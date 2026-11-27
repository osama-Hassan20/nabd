import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/config/app_config.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_cubit.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_state.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/offline/store/transactional_local_store.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
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
                  context: context,
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
                              context,
                              'البيانات الشخصية وبيانات الاتصال',
                              Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 10),
                            _buildPersonalInfoCard(
                              context: context,
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
                              context,
                              'الأمان والخصوصية',
                              Icons.shield_outlined,
                            ),
                            const SizedBox(height: 10),
                            _buildSecurityCard(context),
                            if (isOwner) ...[
                              const SizedBox(height: 16),
                              _buildQaBackendModeCard(context),
                            ],
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
                        context,
                        'البيانات الشخصية وبيانات الاتصال',
                        Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                      _buildPersonalInfoCard(
                        context: context,
                        email: email,
                        phone: phone,
                        branchName: branchName,
                        isOwner: isOwner,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        context,
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
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final colors = context.themeColors;
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: CustomAppFontStyle.bold16.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ─── Hero Card ─────────────────────────────────────────────────────────────
  Widget _buildHeroCard({
    required BuildContext context,
    required String fullName,
    required String jobTitle,
    required String initials,
    required bool isOwner,
    required bool isDesktop,
    required String branchName,
  }) {
    final colors = context.themeColors;
    return CustomContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: colors.borderSubtle),
      backGroundColor: colors.cardBackground,
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
                  color: colors.primary.withValues(alpha: 0.28),
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
                        color: colors.textPrimary,
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
                    color: colors.textSecondary,
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
                color: colors.surfaceLevel1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الفرع المتصل به حالياً',
                    style: CustomAppFontStyle.regular11.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        branchName,
                        style: CustomAppFontStyle.bold13.copyWith(
                          color: colors.textPrimary,
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
    required BuildContext context,
    required String email,
    required String phone,
    required String branchName,
    required bool isOwner,
  }) {
    final colors = context.themeColors;
    return CustomContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.borderSubtle),
      backGroundColor: colors.cardBackground,
      child: Column(
        children: [
          _buildInfoRow(
            context: context,
            icon: Icons.email_outlined,
            label: 'البريد الإلكتروني',
            value: email,
          ),
          Divider(color: colors.borderSubtle, height: 24),
          _buildInfoRow(
            context: context,
            icon: Icons.phone_outlined,
            label: 'رقم الهاتف',
            value: phone,
          ),
          Divider(color: colors.borderSubtle, height: 24),
          _buildInfoRow(
            context: context,
            icon: Icons.business_outlined,
            label: 'الفرع الرئيسي التابع له',
            value: branchName,
          ),
          Divider(color: colors.borderSubtle, height: 24),
          _buildInfoRow(
            context: context,
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
    final colors = context.themeColors;
    return BlocBuilder<LocalPasscodeCubit, LocalPasscodeState>(
      bloc: getIt<LocalPasscodeCubit>(),
      builder: (context, passcodeState) {
        return CustomContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
          backGroundColor: colors.cardBackground,
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
                                ? colors.primary.withValues(alpha: 0.12)
                                : colors.surfaceLevel1,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            passcodeState.isEnabled
                                ? Icons.lock_rounded
                                : Icons.lock_open_rounded,
                            color: passcodeState.isEnabled
                                ? colors.primary
                                : colors.textSecondary,
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
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                passcodeState.isEnabled
                                    ? 'مفعّل - القفل التلقائي بعد ${passcodeState.autoLockMinutes} دقيقة'
                                    : 'معطّل - انقر لإنشاء رمز قفل لحماية الشاشة',
                                style: CustomAppFontStyle.regular12.copyWith(
                                  color: colors.textSecondary,
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
                        ? colors.surfaceLevel1
                        : colors.primary,
                    boxBorder: Border.all(
                      color: passcodeState.isEnabled
                          ? colors.borderSubtle
                          : colors.primary,
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
                                ? colors.textPrimary
                                : colors.textInverse,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Divider(color: colors.borderSubtle, height: 28),

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
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.key_rounded,
                            color: colors.primary,
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
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'تحديث كلمة المرور الدخول للنظام والمنشأة',
                                style: CustomAppFontStyle.regular12.copyWith(
                                  color: colors.textSecondary,
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
                    backgroundColor: colors.surfaceLevel1,
                    boxBorder: Border.all(color: colors.borderSubtle),
                    onTap: () => ChangePasswordDialog.show(context: context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Center(
                        child: Text(
                          'تغيير',
                          style: CustomAppFontStyle.semiBold13.copyWith(
                            color: colors.textPrimary,
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

  Widget _buildQaBackendModeCard(BuildContext context) {
    final colors = context.themeColors;
    final isLocal = AppConfig.isLocalMode;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.developer_mode_rounded, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'إعدادات الخادم (QA)',
                  style: CustomAppFontStyle.bold14.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'BASE_URL: ${AppConfig.baseUrl}',
              style: CustomAppFontStyle.regular12.copyWith(color: colors.textSecondary),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLocal ? 'الوضع الحالي: محلي (Local)' : 'الوضع الحالي: خادم بعيد (Remote)',
                        style: CustomAppFontStyle.semiBold13.copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'تبديل الوضع يمسح البيانات المحلية ويسجل الخروج',
                        style: CustomAppFontStyle.regular11.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  key: const Key('qa_backend_mode_switch'),
                  value: !isLocal,
                  onChanged: (useRemote) async {
                    final nextMode = useRemote ? BackendMode.remote : BackendMode.local;
                    if (getIt.isRegistered<TransactionalLocalStore>()) {
                      await getIt<TransactionalLocalStore>().clear();
                    }
                    await AppConfig.setRuntimeBackendMode(nextMode);
                    await getIt.reset();
                    await setupGetIt();
                    if (context.mounted) {
                      getIt<SessionCubit>().logout();
                      context.go(AppRouter.login);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper Info Row ───────────────────────────────────────────────────────
  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colors = context.themeColors;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: CustomAppFontStyle.regular12.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: CustomAppFontStyle.medium14.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
