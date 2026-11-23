import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/presentation/cubit/staff_users_cubit.dart';

class DeleteStaffUserDialog extends StatefulWidget {
  final StaffUserModel user;

  const DeleteStaffUserDialog({
    super.key,
    required this.user,
  });

  @override
  State<DeleteStaffUserDialog> createState() => _DeleteStaffUserDialogState();
}

class _DeleteStaffUserDialogState extends State<DeleteStaffUserDialog> {
  int? _activeBookingsCount;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final currentUserId = getIt.isRegistered<SessionCubit>()
        ? getIt<SessionCubit>().currentUser?.id ?? 'USER-OWNER'
        : 'USER-OWNER';
    final cubit = context.read<StaffUsersCubit>();

    final isOwner = widget.user.isOwner == true;
    final isSelf = widget.user.id == currentUserId;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.35 : 0.08),
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
              // Icon Header
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.isDark
                        ? Colors.red.shade900.withValues(alpha: 0.3)
                        : const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.isDark
                          ? Colors.red.shade800
                          : const Color(0xFFFECDD3),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: colors.isDark ? Colors.red.shade300 : const Color(0xFFDC2626),
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'delete_user'.tr(),
                style: CustomAppFontStyle.bold18.copyWith(
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle & Message
              if (isOwner)
                Text(
                  'last_active_owner_cannot_be_deleted'.tr(),
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: colors.isDark ? Colors.red.shade300 : const Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                )
              else if (isSelf)
                Text(
                  'self_deletion_forbidden'.tr(),
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: colors.isDark ? Colors.red.shade300 : const Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                )
              else if (_activeBookingsCount != null &&
                  _activeBookingsCount! > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.isDark
                        ? const Color(0xFF78350F).withValues(alpha: 0.25)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.isDark
                          ? const Color(0xFFB45309)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: colors.isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'active_bookings_warning'.tr(
                            namedArgs: {
                              'count': _activeBookingsCount.toString(),
                            },
                          ),
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: colors.isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'delete_user_confirmation_prompt'.tr(
                    namedArgs: {'name': widget.user.fullName ?? ''},
                  ),
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 24),

              // Action Buttons
              if (isOwner || isSelf)
                CustomPushButton(
                  height: 44,
                  backgroundColor: colors.surfaceLevel1,
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.pop(),
                  child: Center(
                    child: Text(
                      'understood'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: colors.textPrimary,
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
                        backgroundColor: colors.surfaceLevel1,
                        boxBorder: Border.all(color: colors.borderSubtle),
                        borderRadius: BorderRadius.circular(10),
                        onTap: _isLoading ? null : () => context.pop(),
                        child: Center(
                          child: Text(
                            'cancel'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomPushButton(
                        height: 44,
                        backgroundColor: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(10),
                        isLoading: _isLoading,
                        onTap: _isLoading
                            ? null
                            : () async {
                                setState(() => _isLoading = true);
                                final result = await cubit.deleteUser(
                                  userId: widget.user.id ?? '',
                                  currentUserId: currentUserId,
                                  forceWithActiveBookings:
                                      _activeBookingsCount != null &&
                                          _activeBookingsCount! > 0,
                                );
                                if (!mounted) return;
                                setState(() => _isLoading = false);

                                result.fold(
                                  (failure) {
                                    if (failure
                                        is ActiveBookingsWarningFailure) {
                                      setState(() {
                                        _activeBookingsCount =
                                            failure.activeBookingsCount;
                                      });
                                    } else {
                                      CustomToast(
                                        context: context,
                                        header: failure.errMessage.tr(),
                                      ).showErrorToast();
                                      context.pop();
                                    }
                                  },
                                  (_) {
                                    CustomToast(
                                      context: context,
                                      header:
                                          'user_deleted_successfully'.tr(),
                                    ).showTopToast();
                                    context.pop();
                                  },
                                );
                              },
                        child: Center(
                          child: Text(
                            _activeBookingsCount != null &&
                                    _activeBookingsCount! > 0
                                ? 'force_delete'.tr()
                                : 'delete'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: Colors.white,
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
