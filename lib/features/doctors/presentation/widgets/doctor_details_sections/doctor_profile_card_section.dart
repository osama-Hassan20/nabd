import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/doctors/data/models/enums/doctor_gender_enum.dart';
import 'package:eyadty/features/doctors/data/models/enums/doctor_status_enum.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

import '../dialogs/add_edit_doctor_dialog.dart';
import '../dialogs/add_doctor_leave_dialog.dart';
import '../dialogs/delete_doctor_dialog.dart';
import '../doctor_status_badge.dart';

class DoctorProfileCardSection extends StatelessWidget {
  final DoctorModel doctor;

  const DoctorProfileCardSection({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DoctorsCubit>();
    final isMobile = AdaptiveLayout.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile)
            _buildMobileLayout(context, cubit)
          else
            _buildDesktopLayout(context, cubit),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, DoctorsCubit cubit) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: doctor.gender == DoctorGenderEnum.female
              ? const Color(0xFFFDF2F8)
              : AppColors.primaryLight,
          child: Text(
            doctor.name != null && doctor.name!.isNotEmpty
                ? doctor.name!.trim().substring(0, 1).toUpperCase()
                : 'D',
            style: CustomAppFontStyle.bold24.copyWith(
              color: doctor.gender == DoctorGenderEnum.female
                  ? const Color(0xFFDB2777)
                  : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    doctor.name ?? '-',
                    style: CustomAppFontStyle.bold20.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  DoctorStatusBadge(
                    status: doctor.status ?? DoctorStatusEnum.available,
                  ),
                ],
              ),
              if (doctor.specialty != null && doctor.specialty!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  doctor.specialty!,
                  style: CustomAppFontStyle.medium14.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  _buildInfoItem(
                    icon: AppIcons.phone,
                    label: doctor.phone ?? '-',
                    isLtr: true,
                  ),
                  if (doctor.createdAt != null)
                    _buildInfoItem(
                      icon: AppIcons.calendar,
                      label:
                          '${'doctor_since'.tr()} ${_formatDate(doctor.createdAt!)}',
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildActionButtons(context, cubit),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, DoctorsCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: doctor.gender == DoctorGenderEnum.female
                  ? const Color(0xFFFDF2F8)
                  : AppColors.primaryLight,
              child: Text(
                doctor.name != null && doctor.name!.isNotEmpty
                    ? doctor.name!.trim().substring(0, 1).toUpperCase()
                    : 'D',
                style: CustomAppFontStyle.bold20.copyWith(
                  color: doctor.gender == DoctorGenderEnum.female
                      ? const Color(0xFFDB2777)
                      : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name ?? '-',
                    style: CustomAppFontStyle.semiBold18.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  if (doctor.specialty != null && doctor.specialty!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty!,
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  DoctorStatusBadge(
                    status: doctor.status ?? DoctorStatusEnum.available,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppColors.grayE2E8F0),
        const SizedBox(height: 16),
        _buildInfoItem(
          icon: AppIcons.phone,
          label: doctor.phone ?? '-',
          isLtr: true,
        ),
        if (doctor.createdAt != null) ...[
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: AppIcons.calendar,
            label:
                '${'doctor_since'.tr()} ${_formatDate(doctor.createdAt!)}',
          ),
        ],
        const SizedBox(height: 20),
        _buildActionButtons(context, cubit),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoItem({
    required String icon,
    required String label,
    bool isLtr = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomAssetImage(
          path: icon,
          width: 16,
          height: 16,
          color: AppColors.gray7A828E,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          textDirection: isLtr ? TextDirection.ltr : null,
          style: CustomAppFontStyle.regular14.copyWith(
            color: AppColors.darkText,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, DoctorsCubit cubit) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        CustomPushButton(
          height: 40,
          backgroundColor: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onTap: () => AddEditDoctorDialog.show(
            context: context,
            doctor: doctor,
            doctorsCubit: cubit,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomAssetImage(
                path: AppIcons.edit,
                width: 16,
                height: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'edit'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        CustomPushButton(
          height: 40,
          backgroundColor: AppColors.yellowLight,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onTap: () {
            if (doctor.id != null) {
              AddDoctorLeaveDialog.show(
                context: context,
                doctorId: doctor.id!,
                doctorsCubit: cubit,
              );
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomAssetImage(
                path: AppIcons.calendar,
                width: 16,
                height: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'add_leave'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        CustomPushButton(
          height: 40,
          backgroundColor: AppColors.red1A,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onTap: () => DeleteDoctorDialog.show(
            context: context,
            doctor: doctor,
            doctorsCubit: cubit,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomAssetImage(
                path: AppIcons.delete,
                width: 16,
                height: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(
                'delete'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
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

