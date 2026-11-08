import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/routing/app_router.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo.dart';
import 'package:eyadty/shared/services/app_branch_service.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class HeaderRoleSwitcher extends StatefulWidget {
  const HeaderRoleSwitcher({super.key});

  @override
  State<HeaderRoleSwitcher> createState() => _HeaderRoleSwitcherState();
}

class _HeaderRoleSwitcherState extends State<HeaderRoleSwitcher> {
  List<StaffUserModel> _mockUsers = [];

  static const List<String> _targetUserIds = [
    'USER-OWNER',
    'USER-MGR',
    'USER-MED-DIR',
    'USER-DOC-01',
    'USER-NURSE',
    'USER-REC',
    'USER-ACC',
    'USER-HR',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (getIt.isRegistered<StaffUsersRepo>()) {
      final res = await getIt<StaffUsersRepo>().getStaffUsers();
      res.fold((_) {}, (users) {
        if (mounted) {
          final sorted = <StaffUserModel>[];
          for (final id in _targetUserIds) {
            final match = users.where((u) => u.id == id).firstOrNull;
            if (match != null) sorted.add(match);
          }
          setState(() {
            _mockUsers = sorted.isNotEmpty ? sorted : users;
          });
        }
      });
    }
  }

  IconData _getIconForUser(StaffUserModel user) {
    if (user.isOwner == true) return Icons.workspace_premium_rounded;
    final id = user.id ?? '';
    if (id.contains('MED-DIR')) return Icons.health_and_safety_rounded;
    if (id.contains('MGR')) return Icons.business_center_rounded;
    if (id.contains('DOC')) return Icons.medical_services_rounded;
    if (id.contains('NURSE')) return Icons.favorite_rounded;
    if (id.contains('REC')) return Icons.support_agent_rounded;
    if (id.contains('ACC')) return Icons.account_balance_wallet_rounded;
    if (id.contains('HR')) return Icons.badge_rounded;
    return Icons.person_rounded;
  }

  Color _getColorForUser(StaffUserModel user) {
    if (user.isOwner == true) return AppColors.primary;
    final id = user.id ?? '';
    if (id.contains('MED-DIR')) return const Color(0xFF0284C7);
    if (id.contains('MGR')) return AppColors.secondary;
    if (id.contains('DOC')) return const Color(0xFF059669);
    if (id.contains('NURSE')) return const Color(0xFFEC4899);
    if (id.contains('REC')) return AppColors.warning;
    if (id.contains('ACC')) return const Color(0xFF10B981);
    if (id.contains('HR')) return const Color(0xFF8B5CF6);
    return AppColors.gray;
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final sessionCubit = getIt<SessionCubit>();

    return BlocBuilder<SessionCubit, SessionState>(
      bloc: sessionCubit,
      builder: (context, state) {
        final currentUser = state.currentUser;
        final displayTitle = currentUser != null
            ? (currentUser.isOwner == true
                ? 'dev_user_owner'.tr()
                : (currentUser.jobTitle ?? currentUser.fullName ?? ''))
            : (state.currentRole?.name ?? 'dev_user_owner'.tr());

        return PopupMenuButton<StaffUserModel>(
          tooltip: 'dev_switch_user'.tr(),
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.grayE2E8F0),
          ),
          onSelected: (user) {
            sessionCubit.switchMockUser(user);
            final activeBranch = sessionCubit.state.activeBranchId ?? 'branch_1';
            AppBranchService.instance.selectBranch(activeBranch);
            appRouter.refresh();
            CustomToast(
              context: context,
              header: 'switched_to_user'.tr(args: [user.fullName ?? '']),
            ).showTopToast();
          },
          itemBuilder: (context) {
            return _mockUsers.map((user) {
              final isSelected = user.id == currentUser?.id;
              final iconColor = _getColorForUser(user);
              return PopupMenuItem<StaffUserModel>(
                value: user,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForUser(user),
                        size: 18,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.fullName ?? '',
                            style: CustomAppFontStyle.semiBold13.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.darkText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.isOwner == true
                                ? 'dev_user_owner'.tr()
                                : (user.jobTitle ?? ''),
                            style: CustomAppFontStyle.regular11.copyWith(
                              color: AppColors.gray,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                  ],
                ),
              );
            }).toList();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bug_report_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    '${'dev_mode_label'.tr()}: $displayTitle',
                    style: CustomAppFontStyle.semiBold12.copyWith(
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
