import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/config/app_config.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/routing/app_router.dart';
import 'package:eyadty/core/animation/slide_transition_animation.dart';
import 'package:eyadty/core/animation/scale_transition_animation.dart';
import 'package:eyadty/core/animation/hover_scale_animation.dart';
import 'package:eyadty/core/utils/theme/app_animations.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_check_box.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:toastification/toastification.dart';

import '../../cubits/login/login_cubit.dart';
import '../must_change_password_dialog.dart';

class LoginBody extends StatefulWidget {
  const LoginBody({super.key});

  @override
  State<LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<LoginBody> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocus = FocusNode();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (formKey.currentState!.validate()) {
      context.read<LoginCubit>().loginInto(
            identifier: identifierController.text,
            password: passwordController.text,
          );
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.grayE2E8F0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'forgot_password_title'.tr(),
                        style: CustomAppFontStyle.bold16.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.grayE2E8F0),
                const SizedBox(height: 16),
                Text(
                  'forgot_password_desc'.tr(),
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: AppColors.gray71717A,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                CustomPushButton(
                  height: 44,
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Center(
                    child: Text(
                      'understood'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 960;

    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is SuccessLoginPushState) {
          CustomToast(
            context: context,
            header: 'login_welcome_message'.tr(),
          ).showTopToast();
          final from = GoRouterState.of(context).uri.queryParameters['from'];
          final session = getIt<SessionCubit>();
          if (from != null && from.isNotEmpty) {
            final reqPerm = getRequiredPermissionForRoute(from);
            if (reqPerm == null || session.can(reqPerm)) {
              context.go(from);
              return;
            }
          }
          context.go(getDefaultRouteForSession(session));
        } else if (state is FailedLoginPushState) {
          CustomToast(
            context: context,
            header: state.errMessage.tr(),
            type: ToastificationType.error,
          ).showTopToast();
        } else if (state is MustChangePasswordLoginState) {
          MustChangePasswordDialog.show(
            context,
            userId: state.userId,
            temporaryPassword: state.temporaryPassword,
            onPasswordChangedSuccess: () async {
              final userRes =
                  await getIt<StaffUsersRepo>().getStaffUserById(state.userId);
              if (!context.mounted) return;
              userRes.fold(
                (_) {
                  final session = getIt<SessionCubit>();
                  context.go(getDefaultRouteForSession(session));
                },
                (user) => context
                    .read<LoginCubit>()
                    .handlePasswordChangedSuccess(user),
              );
            },
          );
        } else if (state is FillRemeberMeDataState) {
          identifierController.text = state.userName;
        }
      },
      child: isDesktop
          ? _DesktopSplitLoginLayout(
              identifierController: identifierController,
              passwordController: passwordController,
              passwordFocus: passwordFocus,
              formKey: formKey,
              onSubmit: _submitLogin,
              onForgotPassword: () => _showForgotPasswordDialog(context),
            )
          : _MobileStackedLoginLayout(
              identifierController: identifierController,
              passwordController: passwordController,
              passwordFocus: passwordFocus,
              formKey: formKey,
              onSubmit: _submitLogin,
              onForgotPassword: () => _showForgotPasswordDialog(context),
            ),
    );
  }
}

/// ─── Desktop Layout: Side-by-Side Split Screen ──────────────────────────────
class _DesktopSplitLoginLayout extends StatelessWidget {
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;

  const _DesktopSplitLoginLayout({
    required this.identifierController,
    required this.passwordController,
    required this.passwordFocus,
    required this.formKey,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Row(
        children: [
          // ─── Side 1: Brand Showcase Section ───────────────────────────────
          const Expanded(
            flex: 6,
            child: SlideTransitionAnimation(
              duration: AppAnimations.slow,
              begin: Offset(-0.04, 0.0),
              curve: AppAnimations.defaultCurve,
              child: _BrandShowcaseSide(),
            ),
          ),

          // ─── Side 2: Clean Form Section ──────────────────────────────────
          Expanded(
            flex: 7,
            child: Container(
              height: double.infinity,
              color: AppColors.lightBackground,
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 36,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: SlideTransitionAnimation(
                      duration: AppAnimations.slow,
                      begin: const Offset(0.0, 0.04),
                      curve: AppAnimations.defaultCurve,
                      child: ScaleTransitionAnimation(
                        duration: AppAnimations.slow,
                        begin: 0.96,
                        end: 1.0,
                        curve: AppAnimations.defaultCurve,
                        child: CustomContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 36,
                          ),
                          backGroundColor: AppColors.white,
                          border: Border.all(color: AppColors.grayE2E8F0),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SlideTransitionAnimation(
                                duration: AppAnimations.medium,
                                delay: AppAnimations.staggerShort,
                                begin: const Offset(0.0, 0.08),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'login_into_account'.tr(),
                                      style: CustomAppFontStyle.bold24.copyWith(
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'login_into_account_desc'.tr(),
                                      style: CustomAppFontStyle.regular14.copyWith(
                                        color: AppColors.gray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              _LoginFormFields(
                                identifierController: identifierController,
                                passwordController: passwordController,
                                passwordFocus: passwordFocus,
                                formKey: formKey,
                                onSubmit: onSubmit,
                                onForgotPassword: onForgotPassword,
                                isMobile: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Desktop Brand Showcase Side (Logo, Highlights, Taglines) ───────────────
class _BrandShowcaseSide extends StatelessWidget {
  const _BrandShowcaseSide();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18181B), Color(0xFF111111), Color(0xFF0D0D0E)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomAssetImage(
                      path: AppIcons.appLogo,
                      width: 48,
                      height: 48,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'app_name'.tr(),
                          style: CustomAppFontStyle.bold22.copyWith(
                            color: AppColors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'clinic_management_system'.tr(),
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'smart_clinic_revolution'.tr(),
                      style: CustomAppFontStyle.bold26.copyWith(
                        fontSize: 32,
                        color: AppColors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'brand_showcase_description'.tr(),
                      style: CustomAppFontStyle.regular15.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 36),
                    _FeatureHighlightRow(
                      iconPath: AppIcons.clock,
                      text: 'feature_live_queue'.tr(),
                    ),
                    const SizedBox(height: 16),
                    _FeatureHighlightRow(
                      iconPath: AppIcons.checkmarkCircle,
                      text: 'feature_smart_booking'.tr(),
                    ),
                    const SizedBox(height: 16),
                    _FeatureHighlightRow(
                      iconPath: AppIcons.appLogo,
                      text: 'feature_analytics'.tr(),
                    ),
                  ],
                ),
                Text(
                  'all_rights_reserved'.tr(),
                  style: CustomAppFontStyle.regular12.copyWith(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureHighlightRow extends StatelessWidget {
  final String iconPath;
  final String text;

  const _FeatureHighlightRow({required this.iconPath, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          alignment: Alignment.center,
          child: CustomAssetImage(
            path: iconPath,
            color: AppColors.primaryLight,
            width: 18,
            height: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: CustomAppFontStyle.medium14.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

/// ─── Mobile Layout: Stacked Single-Column Screen ────────────────────────────
class _MobileStackedLoginLayout extends StatelessWidget {
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;

  const _MobileStackedLoginLayout({
    required this.identifierController,
    required this.passwordController,
    required this.passwordFocus,
    required this.formKey,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SlideTransitionAnimation(
                  duration: AppAnimations.medium,
                  begin: const Offset(0.0, -0.08),
                  child: ScaleTransitionAnimation(
                    duration: AppAnimations.medium,
                    begin: 0.9,
                    end: 1.0,
                    child: Column(
                      children: [
                        CustomAssetImage(
                          path: AppIcons.appLogo,
                          fit: BoxFit.fitWidth,
                          width: 120,
                          height: 120,
                        ),
                        Text(
                          'welcome_to_dashboard'.tr(),
                          textAlign: TextAlign.center,
                          style: CustomAppFontStyle.bold20.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'login_subtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: CustomAppFontStyle.regular13.copyWith(
                            color: AppColors.gray,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SlideTransitionAnimation(
                  duration: AppAnimations.medium,
                  delay: AppAnimations.staggerShort,
                  begin: const Offset(0.0, 0.06),
                  child: ScaleTransitionAnimation(
                    duration: AppAnimations.medium,
                    delay: AppAnimations.staggerShort,
                    begin: 0.95,
                    end: 1.0,
                    child: CustomContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      backGroundColor: AppColors.white,
                      border: Border.all(color: AppColors.grayE2E8F0),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      child: _LoginFormFields(
                        identifierController: identifierController,
                        passwordController: passwordController,
                        passwordFocus: passwordFocus,
                        formKey: formKey,
                        onSubmit: onSubmit,
                        onForgotPassword: onForgotPassword,
                        isMobile: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ─── Shared Form Fields Component (Used in both Desktop & Mobile) ───────────
class _LoginFormFields extends StatelessWidget {
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final bool isMobile;

  const _LoginFormFields({
    required this.identifierController,
    required this.passwordController,
    required this.passwordFocus,
    required this.formKey,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Demo Mode Safety Indicator
          if (AppConfig.isDemoMode) ...[
            Container(
              key: const Key('demo_mode_indicator_banner'),
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'demo_mode_banner'.tr(),
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: AppColors.warning,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Identifier Field
          SlideTransitionAnimation(
            duration: AppAnimations.medium,
            delay: AppAnimations.staggerShort,
            begin: const Offset(0.0, 0.06),
            child: CustomTextFormField(
              controller: identifierController,
              headerText: 'email_or_phone_label'.tr(),
              hintText: 'email_or_phone_hint'.tr(),
              prefixWidget: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.gray71717A,
                size: 20,
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(passwordFocus),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'please_enter_email_or_phone'.tr();
                }
                return null;
              },
            ),
          ),
          SizedBox(height: isMobile ? 14 : 16),

          // Password Field
          SlideTransitionAnimation(
            duration: AppAnimations.medium,
            delay: AppAnimations.staggerMedium,
            begin: const Offset(0.0, 0.06),
            child: BlocBuilder<LoginCubit, LoginState>(
              buildWhen: (prev, curr) => curr is ChangeVisibilityState,
              builder: (context, state) {
                bool isHidden = true;
                if (state is ChangeVisibilityState) {
                  isHidden = state.value;
                }
                return CustomTextFormField(
                  controller: passwordController,
                  focusNode: passwordFocus,
                  headerText: 'password'.tr(),
                  hintText: 'password_hint'.tr(),
                  isObeseureText: isHidden,
                  prefixWidget: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.gray71717A,
                    size: 20,
                  ),
                  suffixWidget: IconButton(
                    icon: Icon(
                      isHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.gray71717A,
                      size: 20,
                    ),
                    onPressed: () {
                      context.read<LoginCubit>().changeVisibility(isHidden);
                    },
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onSubmit(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'please_enter_password'.tr();
                    }
                    return null;
                  },
                );
              },
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),

          // Options Row: Remember Me & Forgot Password
          SlideTransitionAnimation(
            duration: AppAnimations.medium,
            delay: AppAnimations.staggerLong,
            begin: const Offset(0.0, 0.06),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BlocBuilder<LoginCubit, LoginState>(
                      buildWhen: (prev, curr) => curr is RememberMeState,
                      builder: (context, state) {
                        bool isChecked = false;
                        if (state is RememberMeState) {
                          isChecked = state.value;
                        }
                        return CustomCheckBox(
                          value: isChecked,
                          onChanged: (value) {
                            context.read<LoginCubit>().rememberMe(value);
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final cubit = context.read<LoginCubit>();
                        final current = (cubit.state is RememberMeState)
                            ? !(cubit.state as RememberMeState).value
                            : true;
                        cubit.rememberMe(current);
                      },
                      child: Text(
                        'remember_me'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: AppColors.gray334155,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onForgotPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'forgot_password'.tr(),
                    style: CustomAppFontStyle.medium13.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),

          // Submit Button
          SlideTransitionAnimation(
            duration: AppAnimations.medium,
            delay: AppAnimations.staggerExtraLong,
            begin: const Offset(0.0, 0.06),
            child: BlocBuilder<LoginCubit, LoginState>(
              buildWhen: (prev, curr) => curr is LoginPushState,
              builder: (context, state) {
                return HoverScaleAnimation(
                  hoverScale: 1.02,
                  tapScale: 0.98,
                  child: CustomPushButton(
                    height: isMobile ? 48 : 52,
                    radius: 12,
                    backgroundColor: AppColors.primary,
                    isLoading: state is LoadingLoginPushState,
                    onTap: onSubmit,
                    child: Center(
                      child: Text(
                        'login'.tr(),
                        style: CustomAppFontStyle.semiBold16.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ─── Direct Demo Role Accounts Section ─────────────────────────────
          if (AppConfig.isDemoMode) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.grayE2E8F0)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'demo_accounts_title'.tr(),
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.grayE2E8F0)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildRoleDemoChip(
                  label: 'demo_owner'.tr(),
                  email: 'owner@eyadty.com',
                  color: AppColors.primary,
                  icon: Icons.workspace_premium_rounded,
                ),
                _buildRoleDemoChip(
                  label: 'demo_med_dir'.tr(),
                  email: 'med_dir@eyadty.com',
                  color: const Color(0xFF0284C7),
                  icon: Icons.health_and_safety_rounded,
                ),
                _buildRoleDemoChip(
                  label: 'demo_manager'.tr(),
                  email: 'manager@eyadty.com',
                  color: AppColors.secondary,
                  icon: Icons.business_center_rounded,
                ),
                _buildRoleDemoChip(
                  label: 'demo_doctor'.tr(),
                  email: 'doctor@eyadty.com',
                  color: const Color(0xFF059669),
                  icon: Icons.medical_services_rounded,
                ),
                _buildRoleDemoChip(
                  label: 'demo_nurse'.tr(),
                  email: 'nurse@eyadty.com',
                  color: const Color(0xFFEC4899),
                  icon: Icons.favorite_rounded,
                ),
                _buildRoleDemoChip(
                  label: 'demo_reception'.tr(),
                  email: 'reception@eyadty.com',
                  color: AppColors.warning,
                  icon: Icons.support_agent_rounded,
                ),
                _buildRoleDemoChip(
                  label: 'demo_cashier'.tr(),
                  email: 'cashier@eyadty.com',
                  color: const Color(0xFF10B981),
                  icon: Icons.account_balance_wallet_rounded,
                ),
                _buildRoleDemoChip(
                  label: 'demo_hr'.tr(),
                  email: 'hr@eyadty.com',
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.badge_rounded,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleDemoChip({
    required String label,
    required String email,
    required Color color,
    required IconData icon,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        identifierController.text = email;
        passwordController.text = '123456';
        onSubmit();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: CustomAppFontStyle.medium12.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
