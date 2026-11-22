import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:toastification/toastification.dart';

/// ─── Create Local Passcode Dialog (Matches Telegram Screenshot 5) ───────────
class CreateLocalPasscodeDialog extends StatefulWidget {
  const CreateLocalPasscodeDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const CreateLocalPasscodeDialog(),
    );
  }

  @override
  State<CreateLocalPasscodeDialog> createState() =>
      _CreateLocalPasscodeDialogState();
}

class _CreateLocalPasscodeDialogState extends State<CreateLocalPasscodeDialog> {
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _confirmPasscodeController =
      TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _passcodeController.dispose();
    _confirmPasscodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pass = _passcodeController.text.trim();
    final confirm = _confirmPasscodeController.text.trim();

    if (pass.isEmpty || pass.length < 4) {
      setState(() {
        _errorMessage = 'passcode_min_length_error'.tr();
      });
      return;
    }

    if (pass != confirm) {
      setState(() {
        _errorMessage = 'passcode_mismatch_error'.tr();
      });
      return;
    }

    final cubit = getIt<LocalPasscodeCubit>();
    final success = await cubit.setPasscode(pass);
    if (success && mounted) {
      Navigator.of(context).pop(true);
      CustomToast(
        context: context,
        header: 'local_passcode_title'.tr(),
        type: ToastificationType.success,
      ).showTopToast();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.35 : 0.1),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row with Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'create_local_passcode_title'.tr(),
                    style: CustomAppFontStyle.bold18.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cute Vault / Safe Avatar Banner
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock_person_rounded,
                      color: colors.primary,
                      size: 34,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description Text
              Text(
                'create_local_passcode_desc'.tr(),
                textAlign: TextAlign.center,
                style: CustomAppFontStyle.regular13.copyWith(
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Passcode Field
              CustomTextFormField(
                controller: _passcodeController,
                headerText: 'enter_passcode_label'.tr(),
                hintText: '••••',
                isObeseureText: true,
                prefixWidget: Icon(
                  Icons.lock_outline_rounded,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Passcode Field
              CustomTextFormField(
                controller: _confirmPasscodeController,
                headerText: 'reenter_passcode_label'.tr(),
                hintText: '••••',
                isObeseureText: true,
                prefixWidget: Icon(
                  Icons.lock_clock_outlined,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: CustomAppFontStyle.medium13.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Save Passcode Button
              CustomPushButton(
                height: 46,
                radius: 12,
                backgroundColor: colors.primary,
                onTap: _save,
                child: Center(
                  child: Text(
                    'save_passcode'.tr(),
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
    );
  }
}

/// ─── Manage Local Passcode Dialog (Matches Telegram Screenshots 4, 3, 8) ────
class ManageLocalPasscodeDialog extends StatefulWidget {
  const ManageLocalPasscodeDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const ManageLocalPasscodeDialog(),
    );
  }

  @override
  State<ManageLocalPasscodeDialog> createState() =>
      _ManageLocalPasscodeDialogState();
}

class _ManageLocalPasscodeDialogState extends State<ManageLocalPasscodeDialog> {
  final cubit = getIt<LocalPasscodeCubit>();

  void _showChangePasscodeDialog() {
    final colors = context.themeColors;
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? localError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'change_passcode'.tr(),
                    style: CustomAppFontStyle.bold16.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: oldController,
                    headerText: 'enter_current_passcode'.tr(),
                    hintText: '••••',
                    isObeseureText: true,
                  ),
                  const SizedBox(height: 12),
                  CustomTextFormField(
                    controller: newController,
                    headerText: 'enter_new_passcode'.tr(),
                    hintText: '••••',
                    isObeseureText: true,
                  ),
                  const SizedBox(height: 12),
                  CustomTextFormField(
                    controller: confirmController,
                    headerText: 'reenter_passcode_label'.tr(),
                    hintText: '••••',
                    isObeseureText: true,
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      localError!,
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  CustomPushButton(
                    height: 44,
                    radius: 12,
                    backgroundColor: colors.primary,
                    onTap: () async {
                      if (newController.text != confirmController.text) {
                        setDialogState(() {
                          localError = 'passcode_mismatch_error'.tr();
                        });
                        return;
                      }
                      final ok = await cubit.changePasscode(
                        oldPasscode: oldController.text,
                        newPasscode: newController.text,
                      );
                      if (ok && ctx.mounted) {
                        Navigator.of(ctx).pop();
                        CustomToast(
                          context: context,
                          header: 'change_passcode'.tr(),
                          type: ToastificationType.success,
                        ).showTopToast();
                      } else {
                        setDialogState(() {
                          localError = cubit.state.errorMessage?.tr() ??
                              'passcode_wrong_current'.tr();
                        });
                      }
                    },
                    child: Center(
                      child: Text(
                        'apply'.tr(),
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
      ),
    );
  }

  void _showAutoLockPicker() {
    final colors = context.themeColors;
    final durations = [
      {'label': 'auto_lock_1_min'.tr(), 'minutes': 1},
      {'label': 'auto_lock_5_min'.tr(), 'minutes': 5},
      {'label': 'auto_lock_1_hour'.tr(), 'minutes': 60},
      {'label': 'auto_lock_5_hours'.tr(), 'minutes': 300},
      {'label': 'auto_lock_never'.tr(), 'minutes': 0},
    ];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'auto_lock_label'.tr(),
                  style: CustomAppFontStyle.bold16.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...durations.map((d) {
                  final isSelected =
                      cubit.state.autoLockMinutes == (d['minutes'] as int);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      d['label'] as String,
                      style: CustomAppFontStyle.medium14.copyWith(
                        color: isSelected
                            ? colors.primary
                            : colors.textPrimary,
                      ),
                    ),
                    leading: Radio<int>(
                      value: d['minutes'] as int,
                      groupValue: cubit.state.autoLockMinutes,
                      activeColor: colors.primary,
                      onChanged: (val) {
                        if (val != null) {
                          cubit.setAutoLockDuration(val);
                          Navigator.of(ctx).pop();
                          setState(() {});
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDisablePasscode() {
    final colors = context.themeColors;
    final currentPassController = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'disable_passcode_confirm_title'.tr(),
                    style: CustomAppFontStyle.bold16.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'disable_passcode_confirm_desc'.tr(),
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: currentPassController,
                    headerText: 'enter_current_passcode'.tr(),
                    hintText: '••••',
                    isObeseureText: true,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'cancel'.tr(),
                          style: CustomAppFontStyle.medium14.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomPushButton(
                        height: 40,
                        width: 100,
                        radius: 10,
                        backgroundColor: AppColors.error,
                        onTap: () async {
                          final ok = await cubit.disablePasscode(
                            currentPassController.text,
                          );
                          if (ok && ctx.mounted) {
                            Navigator.of(ctx).pop();
                            if (mounted) Navigator.of(context).pop();
                          } else {
                            setDialogState(() {
                              error = 'passcode_wrong_current'.tr();
                            });
                          }
                        },
                        child: Center(
                          child: Text(
                            'disable'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: AppColors.white,
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
      ),
    );
  }

  String _getAutoLockDurationText(int minutes) {
    if (minutes == 1) return 'auto_lock_1_min'.tr();
    if (minutes == 5) return 'auto_lock_5_min'.tr();
    if (minutes == 60) return 'auto_lock_1_hour'.tr();
    if (minutes == 300) return 'auto_lock_5_hours'.tr();
    if (minutes == 0) return 'auto_lock_never'.tr();
    return '$minutes ${'minutes_short'.tr()}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final state = cubit.state;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.35 : 0.1),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'local_passcode_title'.tr(),
                    style: CustomAppFontStyle.bold18.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action 1: Change Passcode
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.lock_reset_rounded, color: colors.primary),
                title: Text(
                  'change_passcode'.tr(),
                  style: CustomAppFontStyle.medium14.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colors.textSecondary,
                ),
                onTap: _showChangePasscodeDialog,
              ),
              Divider(color: colors.borderSubtle),

              // Action 2: Auto-Lock Duration
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.timer_outlined, color: colors.secondary),
                title: Text(
                  'auto_lock_label'.tr(),
                  style: CustomAppFontStyle.medium14.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                trailing: Text(
                  _getAutoLockDurationText(state.autoLockMinutes),
                  style: CustomAppFontStyle.semiBold13.copyWith(
                    color: colors.primary,
                  ),
                ),
                onTap: _showAutoLockPicker,
              ),
              Divider(color: colors.borderSubtle),

              const SizedBox(height: 12),
              // Explanatory note matching Telegram Screenshot 4
              Text(
                'create_local_passcode_desc'.tr(),
                style: CustomAppFontStyle.regular12.copyWith(
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Action 3: Disable Passcode (Red)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _confirmDisablePasscode,
                  icon: const Icon(Icons.lock_open_rounded, color: AppColors.error, size: 20),
                  label: Text(
                    'disable_passcode'.tr(),
                    style: CustomAppFontStyle.semiBold14.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
