import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class ChangePasswordDialog extends StatefulWidget {
  final bool isFullScreen;
  final SettingsCubit settingsCubit;

  const ChangePasswordDialog({
    super.key,
    this.isFullScreen = false,
    required this.settingsCubit,
  });

  static Future<bool?> show({
    required BuildContext context,
    SettingsCubit? settingsCubit,
  }) {
    SettingsCubit? cubit = settingsCubit;
    if (cubit == null) {
      try {
        cubit = context.read<SettingsCubit>();
      } catch (_) {
        cubit = getIt<SettingsCubit>();
      }
    }

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        final child = BlocProvider.value(
          value: cubit!,
          child: ChangePasswordDialog(
            isFullScreen: isMobile,
            settingsCubit: cubit,
          ),
        );

        if (isMobile) {
          return Dialog.fullscreen(child: child);
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final currentPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (currentPass.isEmpty) {
      CustomToast(
        context: context,
        header: 'field_required'.tr(),
      ).showErrorToast();
      return;
    }

    if (newPass.length < 6) {
      CustomToast(
        context: context,
        header: 'password_too_short'.tr(),
      ).showErrorToast();
      return;
    }

    if (newPass != confirmPass) {
      CustomToast(
        context: context,
        header: 'passwords_do_not_match'.tr(),
      ).showErrorToast();
      return;
    }

    final success = await widget.settingsCubit.changePassword(
      currentPassword: currentPass,
      newPassword: newPass,
    );

    if (!mounted) return;

    if (success) {
      CustomToast(
        context: context,
        header: 'password_changed_successfully'.tr(),
      ).showTopToast();
      Navigator.of(context).pop(true);
    } else {
      final err = widget.settingsCubit.state.errMessage;
      CustomToast(
        context: context,
        header: (err != null ? err.tr() : 'current_password_incorrect'.tr()),
      ).showErrorToast();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      bloc: widget.settingsCubit,
      builder: (context, state) {
        final isLoading = state.actionStatus == RequestStatusEnum.loading;

        final content = Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(widget.isFullScreen ? 0 : 16),
            border: widget.isFullScreen
                ? null
                : Border.all(color: AppColors.grayE2E8F0),
          ),
          child: Column(
            mainAxisSize:
                widget.isFullScreen ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextFormField(
                          controller: _currentPasswordController,
                          headerText: 'current_password'.tr(),
                          hintText: '••••••••',
                          isObeseureText: _obscureCurrent,
                          suffixWidget: IconButton(
                            icon: Icon(
                              _obscureCurrent
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.gray7A828E,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrent = !_obscureCurrent;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        CustomTextFormField(
                          controller: _newPasswordController,
                          headerText: 'new_password'.tr(),
                          hintText: '••••••••',
                          isObeseureText: _obscureNew,
                          suffixWidget: IconButton(
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.gray7A828E,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNew = !_obscureNew;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        CustomTextFormField(
                          controller: _confirmPasswordController,
                          headerText: 'confirm_new_password'.tr(),
                          hintText: '••••••••',
                          isObeseureText: _obscureConfirm,
                          suffixWidget: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.gray7A828E,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              _buildFooter(context, isLoading),
            ],
          ),
        );

        if (widget.isFullScreen) {
          return Scaffold(backgroundColor: AppColors.white, body: content);
        }

        return content;
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const CustomAssetImage(
              path: AppIcons.lock,
              width: 20,
              height: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'change_password'.tr(),
                  style: CustomAppFontStyle.semiBold18.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  'security_settings_desc'.tr(),
                  style: CustomAppFontStyle.regular12.copyWith(
                    color: AppColors.gray7A828E,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: AppColors.gray7A828E,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: CustomPushButton(
              height: 44,
              backgroundColor: AppColors.grayf2,
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: Text(
                  'cancel'.tr(),
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.grayMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomPushButton(
              height: 44,
              backgroundColor: AppColors.primary,
              isLoading: isLoading,
              borderRadius: BorderRadius.circular(8),
              onTap: isLoading ? null : _handleSubmit,
              child: Center(
                child: Text(
                  'save_changes'.tr(),
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.white,
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
