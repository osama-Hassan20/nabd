import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/extensions/date_time_extentision.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/app_images.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/technicians/data/models/enums/technician_gender_enum.dart';
import 'package:eyadty/features/technicians/data/models/enums/technician_status_enum.dart';
import 'package:eyadty/features/technicians/data/models/technician_model.dart';
import 'package:eyadty/features/technicians/presentation/cubit/technicians_cubit.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

import '../dialogs/add_edit_technician_dialog.dart';
import '../dialogs/add_technician_leave_dialog.dart';
import '../dialogs/delete_technician_dialog.dart';
import '../technician_status_badge.dart';

class TechnicianProfileCardSection extends StatelessWidget {
  final TechnicianModel technician;

  const TechnicianProfileCardSection({super.key, required this.technician});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TechniciansCubit>();
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

  Widget _buildDesktopLayout(BuildContext context, TechniciansCubit cubit) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: technician.gender == TechnicianGenderEnum.male
              ? AppColors.primaryLight
              : Color(0xFFDB2777).withValues(alpha: 0.1),
          child: CustomAssetImage(
            path: technician.gender == TechnicianGenderEnum.male
                ? AppImages.cleanerMan
                : AppImages.cleanerWomen,
            width: 64,
            fit: BoxFit.cover,
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
                    technician.name ?? '-',
                    style: CustomAppFontStyle.bold20.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TechnicianStatusBadge(
                    status: technician.status ?? TechnicianStatusEnum.available,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  _buildInfoItem(
                    icon: AppIcons.phone,
                    label: technician.phone ?? '-',
                    isLtr: true,
                  ),
                  if (technician.createdAt != null)
                    _buildInfoItem(
                      icon: AppIcons.calendar,
                      label:
                          '${'technician_since'.tr()} ${technician.createdAt!.toCustomFormat()}',
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

  Widget _buildMobileLayout(BuildContext context, TechniciansCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: technician.gender == TechnicianGenderEnum.male
                  ? AppColors.primaryLight
                  : AppColors.pink.withValues(alpha: 0.07),
              child: CustomAssetImage(
                path: technician.gender == TechnicianGenderEnum.male
                    ? AppImages.cleanerMan
                    : AppImages.cleanerWomen,
                width: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    technician.name ?? '-',
                    style: CustomAppFontStyle.semiBold18.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TechnicianStatusBadge(
                    status: technician.status ?? TechnicianStatusEnum.available,
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
          label: technician.phone ?? '-',
          isLtr: true,
        ),
        if (technician.createdAt != null) ...[
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: AppIcons.calendar,
            label:
                '${'technician_since'.tr()} ${technician.createdAt!.toCustomFormat()}',
          ),
        ],
        const SizedBox(height: 20),
        _buildActionButtons(context, cubit),
      ],
    );
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

  Widget _buildActionButtons(BuildContext context, TechniciansCubit cubit) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        CustomPushButton(
          height: 40,
          backgroundColor: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onTap: () => AddEditTechnicianDialog.show(
            context: context,
            technician: technician,
            techniciansCubit: cubit,
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
            if (technician.id != null) {
              AddTechnicianLeaveDialog.show(
                context: context,
                technicianId: technician.id!,
                techniciansCubit: cubit,
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
          onTap: () => DeleteTechnicianDialog.show(
            context: context,
            technician: technician,
            techniciansCubit: cubit,
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
