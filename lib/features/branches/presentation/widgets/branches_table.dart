import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import '../../../../core/layout_adaptive/widgets/cutom_table.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../data/models/branch_model.dart';
import 'branch_status_badge.dart';

class BranchesTable extends StatelessWidget {
  final List<BranchModel> branches;
  final ValueChanged<BranchModel> onEdit;
  final ValueChanged<BranchModel> onToggleStatus;
  final ValueChanged<BranchModel> onSetMain;
  final ValueChanged<BranchModel> onCopySettings;

  const BranchesTable({
    super.key,
    required this.branches,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onSetMain,
    required this.onCopySettings,
  });

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(50),  // #
    1: FlexColumnWidth(3),    // Name & Code
    2: FlexColumnWidth(3),    // Address & Phone
    3: FlexColumnWidth(2),    // Working Hours
    4: FlexColumnWidth(2),    // Rooms & Staff
    5: FlexColumnWidth(2),    // Status
    6: FixedColumnWidth(60),  // Actions
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final headers = [
      '#',
      'branch_name'.tr(),
      'address_and_contact'.tr(),
      'working_hours'.tr(),
      'rooms_and_staff'.tr(),
      'status'.tr(),
      'actions'.tr(),
    ];

    final rows = <List<Widget>>[];

    for (var i = 0; i < branches.length; i++) {
      final branch = branches[i];
      final isMain = branch.isMain == true;
      final isActive = branch.isActive != false;

      final displayName = (branch.nameKey != null && branch.nameKey!.isNotEmpty)
          ? branch.nameKey!.tr()
          : (branch.name ?? '-');

      final hoursText = (branch.openingTime != null && branch.closingTime != null)
          ? '${branch.openingTime} - ${branch.closingTime}'
          : '-';

      final rooms = branch.activeRoomsCount ?? 0;
      final staff = branch.staffMembersCount ?? 0;

      rows.add([
        // 1. Index
        Text(
          '${i + 1}',
          style: CustomAppFontStyle.medium13.copyWith(
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        // 2. Branch Name & Main Badge
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    style: CustomAppFontStyle.semiBold14.copyWith(
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isMain) ...[
                  const SizedBox(width: 8),
                  const MainBranchBadge(),
                ],
              ],
            ),
            if (branch.id != null) ...[
              const SizedBox(height: 2),
              Text(
                branch.id!,
                style: CustomAppFontStyle.regular11.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),

        // 3. Address & Contact
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (branch.address != null && branch.address!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined, size: 13, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      branch.address!,
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (branch.phone != null && branch.phone!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_outlined, size: 12, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    branch.phone!,
                    style: CustomAppFontStyle.regular11.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),

        // 4. Working Hours
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_rounded, size: 14, color: colors.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hoursText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CustomAppFontStyle.medium12.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),

        // 5. Rooms & Staff
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: colors.surfaceLevel1,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Text(
            '$rooms ${'rooms_short'.tr()} • $staff ${'staff_short'.tr()}',
            style: CustomAppFontStyle.medium12.copyWith(
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // 6. Status Badge
        BranchStatusBadge(isActive: isActive),

        // 7. Actions Menu
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: colors.textSecondary,
            size: 20,
          ),
          tooltip: 'actions'.tr(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: colors.cardBackground,
          onSelected: (val) {
            switch (val) {
              case 'edit':
                onEdit(branch);
                break;
              case 'copy_settings':
                onCopySettings(branch);
                break;
              case 'set_main':
                onSetMain(branch);
                break;
              case 'toggle_status':
                onToggleStatus(branch);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: colors.textPrimary),
                  const SizedBox(width: 10),
                  Text(
                    'edit'.tr(),
                    style: CustomAppFontStyle.medium13.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'copy_settings',
              child: Row(
                children: [
                  const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF6366F1)),
                  const SizedBox(width: 10),
                  Text(
                    'copy_settings'.tr(),
                    style: CustomAppFontStyle.medium13.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMain && isActive)
              PopupMenuItem(
                value: 'set_main',
                child: Row(
                  children: [
                    const Icon(Icons.star_outline_rounded, size: 18, color: Color(0xFFD97706)),
                    const SizedBox(width: 10),
                    Text(
                      'set_as_main'.tr(),
                      style: CustomAppFontStyle.medium13.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: isActive ? AppColors.error : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isActive ? 'deactivate'.tr() : 'activate'.tr(),
                    style: CustomAppFontStyle.medium13.copyWith(
                      color: isActive ? AppColors.error : const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ]);
    }

    return CustomTable(
      headers: headers,
      rows: rows,
      columnWidths: columnWidths,
    );
  }
}
