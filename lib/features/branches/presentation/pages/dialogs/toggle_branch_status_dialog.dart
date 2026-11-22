import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/providers/active_bookings_count_provider.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/branches/data/models/branch_model.dart';
import 'package:eyadty/features/branches/presentation/cubit/branches_cubit.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

class ToggleBranchStatusDialog extends StatefulWidget {
  final BranchModel branch;

  const ToggleBranchStatusDialog({
    super.key,
    required this.branch,
  });

  @override
  State<ToggleBranchStatusDialog> createState() => _ToggleBranchStatusDialogState();
}

class _ToggleBranchStatusDialogState extends State<ToggleBranchStatusDialog> {
  bool _isLoading = false;
  int? _activeBookingsCount;
  bool _isCheckingBookings = true;

  @override
  void initState() {
    super.initState();
    _checkActiveBookings();
  }

  Future<void> _checkActiveBookings() async {
    if (widget.branch.isActive == false) {
      if (mounted) setState(() => _isCheckingBookings = false);
      return;
    }

    final branchId = widget.branch.id;
    if (branchId == null || branchId.isEmpty) {
      if (mounted) setState(() => _isCheckingBookings = false);
      return;
    }

    if (getIt.isRegistered<ActiveBookingsCountProvider>()) {
      final provider = getIt<ActiveBookingsCountProvider>();
      final count = await provider.countActiveFutureBookingsForBranch(branchId);
      if (mounted) {
        setState(() {
          _activeBookingsCount = count;
          _isCheckingBookings = false;
        });
      }
    } else {
      if (mounted) setState(() => _isCheckingBookings = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BranchesCubit>();
    final currentUserId = getIt.isRegistered<SessionCubit>()
        ? getIt<SessionCubit>().currentUser?.id ?? 'USER-OWNER'
        : 'USER-OWNER';
    final colors = context.themeColors;

    final isCurrentlyActive = widget.branch.isActive != false;
    final newStatus = !isCurrentlyActive;
    final isBlocked = isCurrentlyActive && widget.branch.isMain == true;

    final displayName = (widget.branch.nameKey != null && widget.branch.nameKey!.isNotEmpty)
        ? widget.branch.nameKey!.tr()
        : (widget.branch.name ?? '');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.35 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isBlocked || isCurrentlyActive
                        ? (colors.isDark ? Colors.red.shade900.withValues(alpha: 0.3) : const Color(0xFFFEF2F2))
                        : (colors.isDark ? Colors.teal.shade900.withValues(alpha: 0.3) : const Color(0xFFECFDF5)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBlocked
                        ? Icons.lock_outline_rounded
                        : (isCurrentlyActive
                            ? Icons.pause_circle_outline_rounded
                            : Icons.check_circle_outline_rounded),
                    color: isBlocked || isCurrentlyActive
                        ? AppColors.error
                        : const Color(0xFF10B981),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isCurrentlyActive
                    ? 'deactivate_branch_title'.tr()
                    : 'activate_branch_title'.tr(),
                style: CustomAppFontStyle.bold18.copyWith(
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Target Name
              Text(
                displayName,
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: colors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              // Blocked Main Branch Notice
              if (isBlocked) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.isDark ? Colors.red.shade900.withValues(alpha: 0.2) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.isDark ? Colors.red.shade800 : const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'cannot_deactivate_main_branch'.tr(),
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else if (_activeBookingsCount != null && _activeBookingsCount! > 0) ...[
                // Active Bookings Warning
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.isDark ? const Color(0xFF78350F).withValues(alpha: 0.2) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.isDark ? const Color(0xFFB45309) : const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFD97706), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'warning_active_bookings'.tr(),
                              style: CustomAppFontStyle.bold13.copyWith(
                                color: colors.isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'branch_has_future_bookings_warning'.tr(
                          namedArgs: {'count': _activeBookingsCount.toString()},
                        ),
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: colors.isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                Text(
                  isCurrentlyActive
                      ? 'deactivate_branch_prompt'.tr()
                      : 'activate_branch_prompt'.tr(),
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],

              // Actions
              if (isBlocked)
                CustomPushButton(
                  height: 42,
                  backgroundColor: colors.surfaceLevel1,
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).pop(),
                  child: Center(
                    child: Text(
                      'understood'.tr(),
                      style: CustomAppFontStyle.medium13.copyWith(
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
                        height: 42,
                        backgroundColor: colors.surfaceLevel1,
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.of(context).pop(),
                        child: Center(
                          child: Text(
                            'cancel'.tr(),
                            style: CustomAppFontStyle.medium13.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomPushButton(
                        height: 42,
                        backgroundColor: isCurrentlyActive
                            ? AppColors.error
                            : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                        isLoading: _isLoading || _isCheckingBookings,
                        onTap: () async {
                          setState(() => _isLoading = true);
                          final ok = await cubit.toggleBranchStatus(
                            branchId: widget.branch.id ?? '',
                            isActive: newStatus,
                            currentUserId: currentUserId,
                            forceWithActiveBookings: true,
                          );
                          if (!mounted) return;
                          setState(() => _isLoading = false);
                          if (ok && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Center(
                          child: Text(
                            isCurrentlyActive
                                ? 'deactivate'.tr()
                                : 'activate'.tr(),
                            style: CustomAppFontStyle.semiBold13.copyWith(
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
