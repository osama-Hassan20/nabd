import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../data/models/branch_model.dart';
import 'branch_status_badge.dart';

class BranchCard extends StatelessWidget {
  final BranchModel branch;
  final ValueChanged<BranchModel> onEdit;
  final ValueChanged<BranchModel> onToggleStatus;
  final ValueChanged<BranchModel> onSetMain;
  final ValueChanged<BranchModel> onCopySettings;

  const BranchCard({
    super.key,
    required this.branch,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onSetMain,
    required this.onCopySettings,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.35 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Name, Main Badge & Menu
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: CustomAppFontStyle.bold16.copyWith(
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
              ),
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
            ],
          ),
          const SizedBox(height: 10),

          // Address
          if (branch.address != null && branch.address!.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: colors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    branch.address!,
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // Phone
          if (branch.phone != null && branch.phone!.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 14, color: colors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  branch.phone!,
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // Working Hours
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                hoursText,
                style: CustomAppFontStyle.medium13.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 10),

          // Bottom Bar: Rooms/Staff + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$rooms ${'rooms_short'.tr()} • $staff ${'staff_short'.tr()}',
                style: CustomAppFontStyle.medium12.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              BranchStatusBadge(isActive: isActive),
            ],
          ),
        ],
      ),
    );
  }
}
