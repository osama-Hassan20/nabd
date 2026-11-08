import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:toastification/toastification.dart';

class MustChangePasswordDialog extends StatefulWidget {
  final String userId;
  final String temporaryPassword;
  final VoidCallback onPasswordChangedSuccess;

  const MustChangePasswordDialog({
    super.key,
    required this.userId,
    required this.temporaryPassword,
    required this.onPasswordChangedSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String temporaryPassword,
    required VoidCallback onPasswordChangedSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: MustChangePasswordDialog(
              userId: userId,
              temporaryPassword: temporaryPassword,
              onPasswordChangedSuccess: onPasswordChangedSuccess,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<MustChangePasswordDialog> createState() =>
      _MustChangePasswordDialogState();
}

class _MustChangePasswordDialogState extends State<MustChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentPasswordController;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController =
        TextEditingController(text: widget.temporaryPassword);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitChange() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repo = getIt<StaffUsersRepo>();
    final result = await repo.changePasswordOnFirstLogin(
      userId: widget.userId,
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        CustomToast(
          context: context,
          header: failure.errMessage.tr(),
          type: ToastificationType.error,
        ).showTopToast();
      },
      (_) {
        CustomToast(
          context: context,
          header: 'password_changed_successfully'.tr(),
          type: ToastificationType.success,
        ).showTopToast();
        Navigator.of(context, rootNavigator: true).pop();
        widget.onPasswordChangedSuccess();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header Icon & Title ─────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.warning,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'must_change_password_title'.tr(),
                        style: CustomAppFontStyle.bold16.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'must_change_password_desc'.tr(),
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: AppColors.gray71717A,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.grayE2E8F0),
            const SizedBox(height: 20),

            // ─── Current / Temporary Password Field ──────────────────────────
            CustomTextFormField(
              controller: _currentPasswordController,
              headerText: 'current_password'.tr(),
              hintText: 'password_hint'.tr(),
              isObeseureText: _obscureCurrent,
              prefixWidget: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.gray71717A,
                size: 20,
              ),
              suffixWidget: IconButton(
                icon: Icon(
                  _obscureCurrent
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.gray71717A,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'please_enter_password'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ─── New Password Field ──────────────────────────────────────────
            CustomTextFormField(
              controller: _newPasswordController,
              headerText: 'new_password'.tr(),
              hintText: 'password_hint'.tr(),
              isObeseureText: _obscureNew,
              prefixWidget: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.gray71717A,
                size: 20,
              ),
              suffixWidget: IconButton(
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.gray71717A,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'please_enter_password'.tr();
                }
                if (val.length < 8) {
                  return 'password_must_be_8_chars'.tr();
                }
                if (val == _currentPasswordController.text) {
                  return 'password_must_differ'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ─── Confirm New Password Field ──────────────────────────────────
            CustomTextFormField(
              controller: _confirmPasswordController,
              headerText: 'confirm_new_password'.tr(),
              hintText: 'password_hint'.tr(),
              isObeseureText: _obscureConfirm,
              prefixWidget: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.gray71717A,
                size: 20,
              ),
              suffixWidget: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.gray71717A,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'please_enter_password'.tr();
                }
                if (val != _newPasswordController.text) {
                  return 'passwords_do_not_match'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            // ─── Submit Button ───────────────────────────────────────────────
            CustomPushButton(
              height: 48,
              radius: 12,
              backgroundColor: AppColors.primary,
              isLoading: _isLoading,
              onTap: _submitChange,
              child: Center(
                child: Text(
                  'save_password_and_continue'.tr(),
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
