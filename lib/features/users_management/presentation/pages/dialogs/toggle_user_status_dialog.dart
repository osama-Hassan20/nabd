import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/presentation/cubit/staff_users_cubit.dart';

class ToggleUserStatusDialog extends StatefulWidget {
  final StaffUserModel user;

  const ToggleUserStatusDialog({
    super.key,
    required this.user,
  });

  @override
  State<ToggleUserStatusDialog> createState() => _ToggleUserStatusDialogState();
}

class _ToggleUserStatusDialogState extends State<ToggleUserStatusDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUserId = getIt.isRegistered<SessionCubit>()
        ? getIt<SessionCubit>().currentUser?.id ?? 'USER-OWNER'
        : 'USER-OWNER';
    final cubit = context.read<StaffUsersCubit>();

    final isOwner = widget.user.isOwner == true;
    final isSelf = widget.user.id == currentUserId;
    final isCurrentlyActive = widget.user.isActive == true;
    final newStatus = !isCurrentlyActive;

    final isBlocked =
        (isOwner && !newStatus) || (isSelf && !newStatus);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: newStatus
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: newStatus
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      newStatus
                          ? Icons.play_circle_outline_rounded
                          : Icons.pause_circle_outline_rounded,
                      color: newStatus
                          ? const Color(0xFF047857)
                          : const Color(0xFFD97706),
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                newStatus ? 'activate_account'.tr() : 'deactivate_account'.tr(),
                style: CustomAppFontStyle.bold18.copyWith(
                  color: AppColors.darkText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              if (isOwner && !newStatus)
                Text(
                  'last_active_owner_cannot_be_deactivated'.tr(),
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: const Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                )
              else if (isSelf && !newStatus)
                Text(
                  'self_deactivation_forbidden'.tr(),
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: const Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                Text(
                  newStatus
                      ? 'activate_user_prompt'.tr(
                          namedArgs: {'name': widget.user.fullName ?? ''},
                        )
                      : 'deactivate_user_prompt'.tr(
                          namedArgs: {'name': widget.user.fullName ?? ''},
                        ),
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: AppColors.gray71717A,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 24),

              if (isBlocked)
                CustomPushButton(
                  height: 44,
                  backgroundColor: AppColors.grayE2E8F0,
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.pop(),
                  child: Center(
                    child: Text(
                      'understood'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                )
              else
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
                        backgroundColor: newStatus
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(10),
                        isLoading: _isLoading,
                        onTap: _isLoading
                            ? null
                            : () async {
                                setState(() => _isLoading = true);
                                final ok = await cubit.toggleUserStatus(
                                  userId: widget.user.id ?? '',
                                  isActive: newStatus,
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
                            'confirm'.tr(),
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
    );
  }
}
