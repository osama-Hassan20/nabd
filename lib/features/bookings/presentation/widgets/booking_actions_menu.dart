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
  final VoidCallback? onCallPatient;
  final VoidCallback? onStartConsultation;
  final String? consultationButtonKey;
  final Color iconColor;
  final double iconSize;

  const BookingActionsMenu({
    super.key,
    this.onViewDetails,
    this.onEdit,
    this.onChangeStatus,
    this.onReassignTechnician,
    this.onDelete,
    this.onCallPatient,
    this.onStartConsultation,
    this.consultationButtonKey,
    this.iconColor = AppColors.gray71717A,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      icon: Icon(Icons.more_vert, size: iconSize, color: iconColor),
      onSelected: (value) {
        switch (value) {
          case 'start_consultation':
            onStartConsultation?.call();
            break;
          case 'call_patient':
            onCallPatient?.call();
            break;
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
        if (onStartConsultation != null)
          PopupMenuItem(
            value: 'start_consultation',
            child: Row(
              children: [
                const Icon(
                  Icons.medical_services_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  (consultationButtonKey ?? 'visits_start_consultation').tr(),
                  style: CustomAppFontStyle.semiBold13.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        if (onCallPatient != null)
          PopupMenuItem(
            value: 'call_patient',
            child: Row(
              children: [
                const CustomAssetImage(
                  path: AppIcons.speaker,
                  width: 16,
                  height: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'call_patient'.tr(),
                  style: CustomAppFontStyle.semiBold13.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        if (onViewDetails != null)
          PopupMenuItem(
            value: 'view_details',
            child: Row(
              children: [
                const CustomAssetImage(
                  path: AppIcons.visibileOn,
                  width: 16,
                  height: 16,
                  color: AppColors.gray71717A,
                ),
                const SizedBox(width: 8),
                Text('view_details'.tr(), style: CustomAppFontStyle.regular13),
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
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Text('change_status'.tr(), style: CustomAppFontStyle.regular13),
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
                  color: AppColors.gray71717A,
                ),
                const SizedBox(width: 8),
                Text('edit_medical_appointment'.tr(), style: CustomAppFontStyle.regular13),
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
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'transfer_doctor'.tr(),
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
                  'cancel_appointment'.tr(),
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
