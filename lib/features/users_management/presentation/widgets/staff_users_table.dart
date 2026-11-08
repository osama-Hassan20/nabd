import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import '../../../../core/layout_adaptive/widgets/cutom_table.dart';
import '../../../../core/utils/helpers/egyptian_phone_helper.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../data/models/role_definition_model.dart';
import '../../data/models/staff_user_model.dart';
import 'staff_role_badge.dart';
import 'staff_user_avatar.dart';

class StaffUsersTable extends StatelessWidget {
  final List<StaffUserModel> users;
  final List<RoleDefinitionModel> roles;
  final void Function(StaffUserModel user) onEdit;
  final void Function(StaffUserModel user) onToggleStatus;
  final void Function(StaffUserModel user) onResetPassword;
  final void Function(StaffUserModel user) onDelete;

  const StaffUsersTable({
    super.key,
    required this.users,
    required this.roles,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onResetPassword,
    required this.onDelete,
  });

  static const List<String> defaultHeaders = [
    '#',
    'table_user',
    'table_role',
    'table_branches',
    'table_contact',
    'status',
    'actions',
  ];

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(50), // Index
    1: FixedColumnWidth(240), // User Name & Job Title
    2: FixedColumnWidth(180), // Roles
    3: FixedColumnWidth(160), // Branches
    4: FixedColumnWidth(190), // Phone & Email
    5: FixedColumnWidth(110), // Status
    6: FixedColumnWidth(70), // Actions
  };

  @override
  Widget build(BuildContext context) {
    return CustomTable(
      minWidth: 1000,
      columnWidths: columnWidths,
      headers: [
        '#',
        'table_user'.tr(),
        'table_role'.tr(),
        'table_branches'.tr(),
        'table_contact'.tr(),
        'status'.tr(),
        'actions'.tr(),
      ],
      rows: users
          .map((user) => _buildRow(context, user, users.indexOf(user) + 1))
          .toList(),
    );
  }

  List<Widget> _buildRow(
    BuildContext context,
    StaffUserModel user,
    int index,
  ) {
    final isOwner = user.isOwner == true;
    final isActive = user.isActive == true;

    // Aggregate roles across all branches
    final roleIds = <String>{};
    for (final assignment in (user.branchAssignments ?? [])) {
      if (assignment.roleIds != null) {
        roleIds.addAll(assignment.roleIds!);
      }
    }

    // Branch names
    final branchNames = <String>[];
    if (isOwner) {
      branchNames.add('all_branches'.tr());
    } else {
      for (final assignment in (user.branchAssignments ?? [])) {
        final bId = assignment.branchId;
        if (bId == 'branch_1') {
          branchNames.add('branch_main'.tr());
        } else if (bId == 'branch_2') {
          branchNames.add('branch_second'.tr());
        } else if (bId == 'branch_3') {
          branchNames.add('branch_third'.tr());
        } else if (bId != null) {
          branchNames.add(bId);
        }
      }
    }

    final formattedPhone = EgyptianPhoneHelper.formatDisplay(user.phone);

    return [
      // 0: Index
      Center(
        child: Text(
          index.toString(),
          style: CustomAppFontStyle.regular13.copyWith(
            color: AppColors.gray71717A,
          ),
        ),
      ),

      // 1: User Profile & Title
      Row(
        children: [
          StaffUserAvatar(
            fullName: user.fullName,
            isOwner: isOwner,
            radius: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName ?? 'unnamed_user'.tr(),
                        style: CustomAppFontStyle.semiBold14.copyWith(
                          color: AppColors.darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 4),
                      const Tooltip(
                        message: 'مالك المنشأة',
                        child: Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ],
                ),
                if (user.jobTitle != null && user.jobTitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.jobTitle!,
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: AppColors.gray71717A,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),

      // 2: Roles Badges
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: isOwner
            ? [
                StaffRoleBadge(
                  roleId: RoleIds.branchManager,
                  roles: roles,
                  isOwner: true,
                ),
              ]
            : roleIds.isEmpty
                ? [
                    Text(
                      'no_roles_assigned'.tr(),
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: AppColors.gray71717A,
                      ),
                    ),
                  ]
                : roleIds
                    .map(
                      (rId) => StaffRoleBadge(
                        roleId: rId,
                        roles: roles,
                      ),
                    )
                    .toList(),
      ),

      // 3: Branch Badges
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: branchNames.isEmpty
            ? [
                Text(
                  'no_branches'.tr(),
                  style: CustomAppFontStyle.regular12.copyWith(
                    color: AppColors.gray71717A,
                  ),
                ),
              ]
            : branchNames.map((bName) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.grayE2E8F0),
                  ),
                  child: Text(
                    bName,
                    style: CustomAppFontStyle.regular11.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                );
              }).toList(),
      ),

      // 4: Phone & Email
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_rounded,
                  size: 13, color: AppColors.gray71717A),
              const SizedBox(width: 4),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  formattedPhone.isNotEmpty ? formattedPhone : '—',
                  style: CustomAppFontStyle.regular12.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
              ),
            ],
          ),
          if (user.email != null && user.email!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.email_outlined,
                    size: 13, color: AppColors.gray71717A),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    user.email!,
                    style: CustomAppFontStyle.regular11.copyWith(
                      color: AppColors.gray71717A,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),

      // 5: Status Badge
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFECFDF5)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? const Color(0xFFA7F3D0)
                  : const Color(0xFFE5E7EB),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF10B981)
                      : const Color(0xFF9CA3AF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  isActive ? 'status_active'.tr() : 'status_inactive'.tr(),
                  style: CustomAppFontStyle.medium12.copyWith(
                    color: isActive
                        ? const Color(0xFF047857)
                        : const Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),

      // 6: Actions Popup Menu
      Center(
        child: PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert_rounded,
            color: AppColors.gray71717A,
            size: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined,
                      size: 17, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('edit'.tr(), style: CustomAppFontStyle.regular13),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(
                    isActive
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    size: 17,
                    color: isActive
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive
                        ? 'deactivate_account'.tr()
                        : 'activate_account'.tr(),
                    style: CustomAppFontStyle.regular13,
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'reset_password',
              child: Row(
                children: [
                  const Icon(Icons.lock_reset_rounded,
                      size: 17, color: Color(0xFF6366F1)),
                  const SizedBox(width: 8),
                  Text('reset_password'.tr(),
                      style: CustomAppFontStyle.regular13),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline_rounded,
                      size: 17, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Text(
                    'delete'.tr(),
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (val) {
            switch (val) {
              case 'edit':
                onEdit(user);
                break;
              case 'toggle_status':
                onToggleStatus(user);
                break;
              case 'reset_password':
                onResetPassword(user);
                break;
              case 'delete':
                onDelete(user);
                break;
            }
          },
        ),
      ),
    ];
  }
}
