import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/core/utils/helpers/app_formatter_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/features/settings/presentation/cubit/medical_services_cubit.dart';
import 'add_edit_medical_service_dialog.dart';
import 'delete_medical_service_dialog.dart';
import 'medical_service_status_badge.dart';

class MedicalServicesTable extends StatelessWidget {
  final List<MedicalServiceModel> services;
  final MedicalServicesCubit cubit;

  const MedicalServicesTable({
    super.key,
    required this.services,
    required this.cubit,
  });

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(50), // Index
    1: FixedColumnWidth(240), // Name & Description
    2: FixedColumnWidth(130), // Fee
    3: FixedColumnWidth(110), // Duration
    4: FixedColumnWidth(180), // Assigned Doctor
    5: FixedColumnWidth(110), // Status
    6: FixedColumnWidth(80), // Actions
  };

  @override
  Widget build(BuildContext context) {
    return CustomTable(
      minWidth: 900,
      columnWidths: columnWidths,
      headers: [
        '#',
        'service_name_label'.tr(),
        'service_fee_label'.tr(),
        'service_duration_label'.tr(),
        'assigned_doctor_label'.tr(),
        'status'.tr(),
        'actions'.tr(),
      ],
      rows: services
          .map(
            (srv) => _buildRow(context, srv, services.indexOf(srv) + 1),
          )
          .toList(),
    );
  }

  List<Widget> _buildRow(
    BuildContext context,
    MedicalServiceModel srv,
    int index,
  ) {
    final isAdmin = getIt<CurrentRoleProvider>().currentRole.canManageServices;
    final isActive = srv.isServiceActive;
    final fee = srv.consultationFee ?? 0;
    final duration = srv.durationMinutes ?? 0;
    final docName = (srv.assignedDoctorName != null &&
            srv.assignedDoctorName!.isNotEmpty)
        ? srv.assignedDoctorName!
        : 'all_doctors_general'.tr();

    return [
      // 0: Index
      Center(
        child: Text(
          index.toString(),
          style: CustomAppFontStyle.regular13.copyWith(
            color: AppColors.gray71717A,
          ),
        ),
      ),

      // 1: Name & Description
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              srv.name ?? '',
              style: CustomAppFontStyle.semiBold14.copyWith(
                color: AppColors.darkText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (srv.description != null && srv.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                srv.description!,
                style: CustomAppFontStyle.regular12.copyWith(
                  color: AppColors.gray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),

      // 2: Fee
      Center(
        child: Text(
          AppFormatterHelper.formatCurrency(fee),
          style: CustomAppFontStyle.semiBold14.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),

      // 3: Duration
      Center(
        child: Text(
          AppFormatterHelper.formatMinutes(duration, context: context),
          style: CustomAppFontStyle.regular13.copyWith(
            color: AppColors.darkSlate,
          ),
        ),
      ),

      // 4: Assigned Doctor
      Center(
        child: Text(
          docName,
          style: CustomAppFontStyle.regular13.copyWith(
            color: srv.assignedDoctorId != null
                ? AppColors.secondaryDark
                : AppColors.gray,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),

      // 5: Status
      Center(
        child: MedicalServiceStatusBadge(isActive: isActive),
      ),

      // 6: Actions Menu
      Center(
        child: isAdmin
            ? PopupMenuButton<String>(
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
                    if (srv.id != null) cubit.toggleStatus(srv.id!);
                  } else if (val == 'edit') {
                    AddEditMedicalServiceDialog.show(
                      context,
                      service: srv,
                      cubit: cubit,
                    );
                  } else if (val == 'delete') {
                    DeleteMedicalServiceDialog.show(
                      context,
                      service: srv,
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
                          color:
                              isActive ? AppColors.warning : AppColors.success,
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
              )
            : const SizedBox.shrink(),
      ),
    ];
  }
}
