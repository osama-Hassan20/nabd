import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_check_box.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:toastification/toastification.dart';

import '../../../data/models/login/login_param_model.dart';
import '../../cubits/login/login_cubit.dart';
import 'custom_password_field.dart';
import 'custom_phone_field.dart';

class LoginBody extends StatefulWidget {
  const LoginBody({super.key});

  @override
  State<LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<LoginBody> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode password = FocusNode();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    password.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (formKey.currentState!.validate()) {
      context.read<LoginCubit>().loginInto(
        model: LoginParamModel(
          password: passwordController.text,
          userName: phoneController.text,
        ),
      );
    }
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
          context.go(AppRouter.bookings);
        } else if (state is FailedLoginPushState) {
          CustomToast(
            context: context,
            header: state.errMessage.tr(),
            type: ToastificationType.error,
          ).showTopToast();
        } else if (state is FillRemeberMeDataState) {
          phoneController.text = state.userName;
          passwordController.text = state.password;
        }
      },
      child: isDesktop
          ? _DesktopSplitLoginLayout(
              phoneController: phoneController,
              passwordController: passwordController,
              passwordFocus: password,
              formKey: formKey,
              onSubmit: _submitLogin,
            )
          : _MobileStackedLoginLayout(
              phoneController: phoneController,
              passwordController: passwordController,
              passwordFocus: password,
              formKey: formKey,
              onSubmit: _submitLogin,
            ),
    );
  }
}

/// ─── Desktop Layout: Side-by-Side Split Screen ──────────────────────────────
class _DesktopSplitLoginLayout extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;

  const _DesktopSplitLoginLayout({
    required this.phoneController,
    required this.passwordController,
    required this.passwordFocus,
    required this.formKey,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Row(
        children: [
          // ─── Side 1: Brand Showcase Section (Flex 5) ─────────────────────
          const Expanded(flex: 6, child: _BrandShowcaseSide()),

          // ─── Side 2: Clean Form Section (Flex 6) ─────────────────────────
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
                    constraints: const BoxConstraints(maxWidth: 600),
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
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                          const SizedBox(height: 32),
                          _LoginFormFields(
                            phoneController: phoneController,
                            passwordController: passwordController,
                            passwordFocus: passwordFocus,
                            formKey: formKey,
                            onSubmit: onSubmit,
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
          // Soft ambient circular glow 1
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
          // Soft ambient circular glow 2
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          // Main Showcase Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo Box
                Container(
                  width: 300,
                  height: 300,
                  padding: const EdgeInsets.all(18),

                  child: const CustomAssetImage(
                    path: AppIcons.appLogo,
                    fit: BoxFit.contain,
                    color: AppColors.white,
                  ),
                ),

                // App Title

                // Subtitle Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'purexo_dashboard_tag'.tr(),
                    style: CustomAppFontStyle.medium14.copyWith(
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tagline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'brand_tagline'.tr(),
                    textAlign: TextAlign.center,
                    style: CustomAppFontStyle.regular15.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Feature Highlights List
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        iconPath: AppIcons.calendar,
                        text: 'feature_smart_bookings'.tr(),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        iconPath: AppIcons.team,
                        text: 'feature_technicians_tracking'.tr(),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        iconPath: AppIcons.dashboard,
                        text: 'feature_advanced_analytics'.tr(),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // Footer version tag
                Text(
                  'Eyadty Clinic SaaS Platform © 2026',
                  style: CustomAppFontStyle.regular12.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({required String iconPath, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomAssetImage(
              path: iconPath,
              width: 18,
              height: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: CustomAppFontStyle.medium14.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Mobile Layout: Upper Branding + Lower Form Card ────────────────────────
class _MobileStackedLoginLayout extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;

  const _MobileStackedLoginLayout({
    required this.phoneController,
    required this.passwordController,
    required this.passwordFocus,
    required this.formKey,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ─── Upper Section: Brand Header ─────────────────────────────
                CustomAssetImage(
                  path: AppIcons.appLogo,
                  fit: BoxFit.fitWidth,
                  width: 160,
                  height: 160,
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
                const SizedBox(height: 22),

                // ─── Lower Section: Form Card ────────────────────────────────
                CustomContainer(
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
                    phoneController: phoneController,
                    passwordController: passwordController,
                    passwordFocus: passwordFocus,
                    formKey: formKey,
                    onSubmit: onSubmit,
                    isMobile: true,
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
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;
  final bool isMobile;

  const _LoginFormFields({
    required this.phoneController,
    required this.passwordController,
    required this.passwordFocus,
    required this.formKey,
    required this.onSubmit,
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
          // Username Field
          CustomUserNameField(
            hintText: 'username_hint'.tr(),
            validatorFun: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'please_enter_username'.tr();
              }
              return null;
            },
            tempColor: AppColors.white,
            onFieldSubmitted: (value) {
              if (value != null && value.trim().isNotEmpty) {
                FocusScope.of(context).requestFocus(passwordFocus);
              }
            },
            nameController: phoneController,
          ),
          SizedBox(height: isMobile ? 14 : 16),

          // Password Field
          BlocBuilder<LoginCubit, LoginState>(
            buildWhen: (prev, curr) => curr is ChangeVisibilityState,
            builder: (context, state) {
              bool isHidden = true;
              if (state is ChangeVisibilityState) {
                isHidden = state.value;
              }
              return CustomPasswordField(
                tempColor: AppColors.white,
                isHidden: isHidden,
                hintText: 'password_hint'.tr(),
                validationError: 'please_enter_password'.tr(),
                passwordController: passwordController,
                passwordFocus: passwordFocus,
                formKey: formKey,
                onFiledSumbitted: onSubmit,
                changeVisibilty: () {
                  context.read<LoginCubit>().changeVisibility(isHidden);
                },
              );
            },
          ),
          SizedBox(height: isMobile ? 16 : 20),

          // Remember Me Option
          Row(
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
          SizedBox(height: isMobile ? 24 : 32),

          // Submit Button
          BlocBuilder<LoginCubit, LoginState>(
            buildWhen: (prev, curr) => curr is LoginPushState,
            builder: (context, state) {
              return CustomPushButton(
                height: isMobile ? 48 : 52,
                radius: 100,
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
              );
            },
          ),
        ],
      ),
    );
  }
}
