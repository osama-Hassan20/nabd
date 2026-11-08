import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/providers/active_bookings_count_provider.dart';
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
  int? _activeBookingsCount;
  bool _isLoading = false;
  bool _isCheckingBookings = false;

  @override
  void initState() {
    super.initState();
    if (widget.branch.isBranchActive) {
      _checkFutureBookings();
    }
  }

  Future<void> _checkFutureBookings() async {
    if (!getIt.isRegistered<ActiveBookingsCountProvider>()) return;
    setState(() => _isCheckingBookings = true);
    final count = await getIt<ActiveBookingsCountProvider>()
        .countActiveFutureBookingsForBranch(widget.branch.id ?? '');
    if (mounted) {
      setState(() {
        _activeBookingsCount = count;
        _isCheckingBookings = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BranchesCubit>();
    final currentUserId = getIt.isRegistered<SessionCubit>()
        ? getIt<SessionCubit>().currentUser?.id ?? 'USER-OWNER'
        : 'USER-OWNER';

    final isCurrentlyActive = widget.branch.isBranchActive;
    final isMain = widget.branch.isMain == true;
    final newStatus = !isCurrentlyActive;

    final displayName = (widget.branch.nameKey != null && widget.branch.nameKey!.isNotEmpty)
        ? widget.branch.nameKey!.tr()
        : (widget.branch.name ?? '');

    // Rule: Cannot deactivate main branch
    final isBlocked = isCurrentlyActive && isMain;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
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
                    color: isBlocked
                        ? const Color(0xFFFEF2F2)
                        : (isCurrentlyActive
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFECFDF5)),
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
                  color: AppColors.darkText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Target Name
              Text(
                displayName,
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              // Blocked Main Branch Notice
              if (isBlocked) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
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
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
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
                                color: const Color(0xFF92400E),
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
                          color: const Color(0xFFB45309),
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
                    color: AppColors.gray71717A,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],

              // Actions
              if (isBlocked)
                CustomPushButton(
                  height: 42,
                  backgroundColor: AppColors.fillDisableColor,
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).pop(),
                  child: Center(
                    child: Text(
                      'understood'.tr(),
                      style: CustomAppFontStyle.medium13.copyWith(
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
                        height: 42,
                        backgroundColor: AppColors.fillDisableColor,
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.of(context).pop(),
                        child: Center(
                          child: Text(
                            'cancel'.tr(),
                            style: CustomAppFontStyle.medium13.copyWith(
                              color: AppColors.darkText,
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
