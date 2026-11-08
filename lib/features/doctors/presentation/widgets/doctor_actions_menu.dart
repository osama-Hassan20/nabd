import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'dialogs/add_edit_doctor_dialog.dart';
import 'dialogs/add_doctor_leave_dialog.dart';
import 'dialogs/delete_doctor_dialog.dart';

class DoctorActionsMenu extends StatelessWidget {
  final DoctorModel doctor;

  const DoctorActionsMenu({super.key, required this.doctor});

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
        final cubit = context.read<DoctorsCubit>();
        switch (action) {
          case 'view':
            if (doctor.id != null) {
              context.go('${AppRouter.doctors}/${doctor.id}');
            }
            break;
          case 'edit':
            AddEditDoctorDialog.show(
              context: context,
              doctor: doctor,
              doctorsCubit: cubit,
            );
            break;
          case 'add_leave':
            if (doctor.id != null) {
              AddDoctorLeaveDialog.show(
                context: context,
                doctorId: doctor.id!,
                doctorsCubit: cubit,
              );
            }
            break;
          case 'delete':
            DeleteDoctorDialog.show(
              context: context,
              doctor: doctor,
              doctorsCubit: cubit,
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

