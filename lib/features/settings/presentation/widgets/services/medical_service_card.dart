import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/helpers/app_formatter_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/features/settings/presentation/cubit/medical_services_cubit.dart';
import 'add_edit_medical_service_dialog.dart';
import 'delete_medical_service_dialog.dart';
import 'medical_service_status_badge.dart';

class MedicalServiceCard extends StatelessWidget {
  final MedicalServiceModel service;
  final MedicalServicesCubit cubit;

  const MedicalServiceCard({
    super.key,
    required this.service,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = getIt<CurrentRoleProvider>().currentRole.canManageServices;
    final isActive = service.isServiceActive;
    final fee = service.consultationFee ?? 0;
    final duration = service.durationMinutes ?? 0;
    final docName = (service.assignedDoctorName != null &&
            service.assignedDoctorName!.isNotEmpty)
        ? service.assignedDoctorName!
        : 'all_doctors_general'.tr();

    return CustomContainer(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderSubtle),
      backGroundColor: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Name, Status & Menu ────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name ?? '',
                      style: CustomAppFontStyle.semiBold16.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                    if (service.description != null &&
                        service.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        service.description!,
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: AppColors.gray,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              MedicalServiceStatusBadge(isActive: isActive),
              if (isAdmin) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: AppColors.grayMid,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (val) {
                    if (val == 'toggle') {
                      if (service.id != null) cubit.toggleStatus(service.id!);
                    } else if (val == 'edit') {
                      AddEditMedicalServiceDialog.show(
                        context,
                        service: service,
                        cubit: cubit,
                      );
                    } else if (val == 'delete') {
                      DeleteMedicalServiceDialog.show(
                        context,
                        service: service,
                        cubit: cubit,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          CustomAssetImage(
                            path: isActive
                                ? AppIcons.inActiveSwitcher
                                : AppIcons.activeSwitcher,
                            width: 16,
                            height: 16,
                            color: isActive
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isActive
                                ? 'service_deactivate'.tr()
                                : 'service_activate'.tr(),
                            style: CustomAppFontStyle.regular14,
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
                            color: AppColors.gray334155,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'edit'.tr(),
                            style: CustomAppFontStyle.regular14,
                          ),
                        ],
                      ),
                    ),
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
                            'delete'.tr(),
                            style: CustomAppFontStyle.regular14.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),

          // ─── Details Row ────────────────────────────────────────────────
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              // Price
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomAssetImage(
                    path: AppIcons.money,
                    width: 14,
                    height: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppFormatterHelper.formatCurrency(fee),
                    style: CustomAppFontStyle.semiBold14.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              // Duration
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomAssetImage(
                    path: AppIcons.clock,
                    width: 14,
                    height: 14,
                    color: AppColors.gray,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppFormatterHelper.formatMinutes(duration, context: context),
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: AppColors.darkSlate,
                    ),
                  ),
                ],
              ),

              // Doctor
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomAssetImage(
                    path: AppIcons.user,
                    width: 14,
                    height: 14,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    docName,
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
