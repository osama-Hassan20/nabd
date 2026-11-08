import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/presentation/cubit/staff_users_cubit.dart';

class ResetPasswordDialog extends StatefulWidget {
  final StaffUserModel user;

  const ResetPasswordDialog({
    super.key,
    required this.user,
  });

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _passwordController;
  final bool _obscure = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(text: _generateRandomPass());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String _generateRandomPass() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#%*';
    final rnd = Random.secure();
    return List.generate(10, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = getIt.isRegistered<SessionCubit>()
        ? getIt<SessionCubit>().currentUser?.id ?? 'USER-OWNER'
        : 'USER-OWNER';
    final cubit = context.read<StaffUsersCubit>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grayE2E8F0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_reset_rounded,
                        color: Color(0xFF6366F1),
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'reset_password'.tr(),
                  style: CustomAppFontStyle.bold18.copyWith(
                    color: AppColors.darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'reset_password_modal_desc'.tr(
                    namedArgs: {'name': widget.user.fullName ?? ''},
                  ),
                  style: CustomAppFontStyle.regular12.copyWith(
                    color: AppColors.gray71717A,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Temporary Password Field
                CustomTextFormField(
                  controller: _passwordController,
                  headerText: 'temporary_password'.tr(),
                  hintText: 'password_hint'.tr(),
                  isObeseureText: _obscure,
                  prefixWidget: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.gray71717A,
                    size: 20,
                  ),
                  suffixWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'نسخ كلمة المرور',
                        color: AppColors.primary,
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _passwordController.text),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ كلمة المرور إلى الحافظة'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.autorenew_rounded, size: 18),
                        tooltip: 'توليد كلمة مرور جديدة',
                        color: const Color(0xFF6366F1),
                        onPressed: () {
                          setState(() {
                            _passwordController.text = _generateRandomPass();
                          });
                        },
                      ),
                    ],
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'please_enter_password'.tr();
                    }
                    if (val.length < 8) {
                      return 'password_must_be_8_chars'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Note to admin
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'reset_password_first_login_notice'.tr(),
                          style: CustomAppFontStyle.regular11.copyWith(
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomPushButton(
                        height: 44,
                        backgroundColor: AppColors.white,
                        boxBorder: Border.all(color: AppColors.grayE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                        onTap: _isLoading ? null : () => context.pop(),
                        child: Center(
                          child: Text(
                            'cancel'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: AppColors.gray71717A,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomPushButton(
                        height: 44,
                        backgroundColor: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(10),
                        isLoading: _isLoading,
                        onTap: _isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setState(() => _isLoading = true);
                                final ok = await cubit.resetPassword(
                                  userId: widget.user.id ?? '',
                                  newTempPassword:
                                      _passwordController.text.trim(),
                                  currentUserId: currentUserId,
                                );
                                if (!mounted) return;
                                setState(() => _isLoading = false);
                                if (ok && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                        child: Center(
                          child: Text(
                            'save'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: AppColors.white,
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
      ),
    );
  }
}
