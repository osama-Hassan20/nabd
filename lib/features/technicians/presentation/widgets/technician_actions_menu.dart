import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/technicians/data/models/technician_model.dart';
import 'package:eyadty/features/technicians/presentation/cubit/technicians_cubit.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'dialogs/add_edit_technician_dialog.dart';
import 'dialogs/add_technician_leave_dialog.dart';
import 'dialogs/delete_technician_dialog.dart';

class TechnicianActionsMenu extends StatelessWidget {
  final TechnicianModel technician;

  const TechnicianActionsMenu({super.key, required this.technician});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.grayf2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.more_vert,
          color: AppColors.gray71717A,
          size: 18,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.grayE2E8F0),
      ),
      color: AppColors.white,
      elevation: 0,
      offset: const Offset(0, 36),
      onSelected: (action) {
        final cubit = context.read<TechniciansCubit>();
        switch (action) {
          case 'view':
            if (technician.id != null) {
              context.go('${AppRouter.technicians}/${technician.id}');
            }
            break;
          case 'edit':
            AddEditTechnicianDialog.show(
              context: context,
              technician: technician,
              techniciansCubit: cubit,
            );
            break;
          case 'add_leave':
            if (technician.id != null) {
              AddTechnicianLeaveDialog.show(
                context: context,
                technicianId: technician.id!,
                techniciansCubit: cubit,
              );
            }
            break;
          case 'delete':
            DeleteTechnicianDialog.show(
              context: context,
              technician: technician,
              techniciansCubit: cubit,
            );
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              const CustomAssetImage(
                path: AppIcons.user,
                width: 16,
                height: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'view_details'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const CustomAssetImage(
                path: AppIcons.edit,
                width: 16,
                height: 16,
                color: AppColors.cyan,
              ),
              const SizedBox(width: 10),
              Text(
                'edit'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'add_leave',
          child: Row(
            children: [
              const CustomAssetImage(
                path: AppIcons.calendar,
                width: 16,
                height: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              Text(
                'add_leave'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
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
              const SizedBox(width: 10),
              Text(
                'delete'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
