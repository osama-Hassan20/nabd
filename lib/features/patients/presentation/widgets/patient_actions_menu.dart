import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/shared/function/launch_phone_whats_app.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';

import 'add_edit_patient_dialog.dart';
import 'delete_patient_dialog.dart';

class PatientActionsMenu extends StatelessWidget {
  final PatientModel patient;

  const PatientActionsMenu({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final isArchived = patient.isArchived ?? false;

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
        switch (action) {
          case 'view':
            if (patient.id != null) {
              context.go('${AppRouter.patients}/${patient.id}');
            }
            break;
          case 'whatsapp':
            if (patient.phone != null && patient.phone!.isNotEmpty) {
              launchWhatsAppCall(
                context: context,
                phoneNumber: patient.phone!,
              );
            }
            break;
          case 'edit':
            AddEditPatientDialog.show(
              context: context,
              patient: patient,
              patientsCubit: context.read<PatientsCubit>(),
            );
            break;
          case 'archive':
            DeletePatientDialog.show(context: context, patient: patient);
            break;
          case 'unarchive':
            if (patient.id != null) {
              context.read<PatientsCubit>().unarchivePatient(patient.id!);
            }
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
        if (patient.phoneHasWhatsapp == true)
          PopupMenuItem(
            value: 'whatsapp',
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                Text(
                  'whatsapp'.tr(),
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
        if (!isArchived)
          PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                const Icon(
                  Icons.archive_outlined,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 10),
                Text(
                  'archive_patient'.tr(),
                  style: CustomAppFontStyle.medium14.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          )
        else
          PopupMenuItem(
            value: 'unarchive',
            child: Row(
              children: [
                const Icon(
                  Icons.unarchive_outlined,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                Text(
                  'unarchive_patient'.tr(),
                  style: CustomAppFontStyle.medium14.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
