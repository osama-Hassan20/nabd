import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';

class BookingActionsMenu extends StatelessWidget {
  final VoidCallback? onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onChangeStatus;
  final VoidCallback? onReassignTechnician;
  final VoidCallback? onDelete;
  final Color iconColor;
  final double iconSize;

  const BookingActionsMenu({
    super.key,
    this.onViewDetails,
    this.onEdit,
    this.onChangeStatus,
    this.onReassignTechnician,
    this.onDelete,
    this.iconColor = AppColors.gray71717A,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      icon: Icon(Icons.more_vert, size: iconSize, color: iconColor),
      onSelected: (value) {
        switch (value) {
          case 'view_details':
            onViewDetails?.call();
            break;
          case 'edit':
            onEdit?.call();
            break;
          case 'change_status':
            onChangeStatus?.call();
            break;
          case 'reassign':
            onReassignTechnician?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        if (onViewDetails != null)
          PopupMenuItem(
            value: 'view_details',
            child: Row(
              children: [
                const CustomAssetImage(
                  path: AppIcons.visibileOn,
                  width: 16,
                  height: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text('view_details'.tr(), style: CustomAppFontStyle.regular13),
              ],
            ),
          ),
        if (onEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const CustomAssetImage(
                  path: AppIcons.edit,
                  width: 16,
                  height: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text('edit_booking'.tr(), style: CustomAppFontStyle.regular13),
              ],
            ),
          ),
        if (onChangeStatus != null)
          PopupMenuItem(
            value: 'change_status',
            child: Row(
              children: [
                const CustomAssetImage(
                  path: AppIcons.change,
                  width: 16,
                  height: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Text('change_status'.tr(), style: CustomAppFontStyle.regular13),
              ],
            ),
          ),
        if (onReassignTechnician != null)
          PopupMenuItem(
            value: 'reassign',
            child: Row(
              children: [
                const CustomAssetImage(
                  path: AppIcons.team,
                  width: 16,
                  height: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'reassign_technician'.tr(),
                  style: CustomAppFontStyle.regular13,
                ),
              ],
            ),
          ),
        if (onDelete != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const CustomAssetImage(
                  path: AppIcons.delete,
                  width: 16,
                  height: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'delete_booking'.tr(),
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
