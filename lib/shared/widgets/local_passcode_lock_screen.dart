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
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';

class LocalPasscodeLockScreen extends StatefulWidget {
  const LocalPasscodeLockScreen({super.key});

  @override
  State<LocalPasscodeLockScreen> createState() =>
      _LocalPasscodeLockScreenState();
}

class _LocalPasscodeLockScreenState extends State<LocalPasscodeLockScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _localError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _passcodeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _passcodeController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _localError = 'please_enter_password'.tr();
      });
      return;
    }

    final cubit = getIt<LocalPasscodeCubit>();
    final success = cubit.unlock(text);
    if (!success) {
      setState(() {
        _localError = 'passcode_incorrect'.tr();
      });
      _passcodeController.clear();
      _focusNode.requestFocus();
    } else {
      setState(() {
        _localError = null;
      });
    }
  }

  void _handleLogout() {
    // Logout user, disable lock view, navigate to login
    getIt<LocalPasscodeCubit>().unlock(''); // force clear state
    getIt<SessionCubit>().logout();
    context.go(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate Navy
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: BlocBuilder<LocalPasscodeCubit, LocalPasscodeState>(
              bloc: getIt<LocalPasscodeCubit>(),
              builder: (context, state) {
                final displayError = _localError ??
                    (state.errorMessage != null ? state.errorMessage!.tr() : null);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Security Icon / Safe Vault
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock_rounded,
                          color: AppColors.primaryLight,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'enter_local_passcode_title'.tr(),
                      textAlign: TextAlign.center,
                      style: CustomAppFontStyle.bold24.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'enter_local_passcode_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: CustomAppFontStyle.regular14.copyWith(
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Passcode Input Field
                    CustomTextFormField(
                      controller: _passcodeController,
                      focusNode: _focusNode,
                      headerText: 'your_passcode'.tr(),
                      hintText: '••••',
                      isObeseureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      prefixWidget: const Icon(
                        Icons.pin_outlined,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),

                    if (displayError != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          displayError,
                          style: CustomAppFontStyle.medium13.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Submit / Unlock Button
                    CustomPushButton(
                      height: 48,
                      width: double.infinity,
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      onTap: _submit,
                      child: Center(
                        child: Text(
                          'unlock'.tr(),
                          style: CustomAppFontStyle.semiBold16.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Log out fallback button
                    TextButton(
                      onPressed: _handleLogout,
                      child: Text(
                        'log_out'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
