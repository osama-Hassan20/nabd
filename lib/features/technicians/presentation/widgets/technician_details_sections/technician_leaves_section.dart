import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/extensions/date_time_extentision.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/technicians/data/models/technician_leave_model.dart';
import 'package:eyadty/features/technicians/presentation/cubit/technicians_cubit.dart';
import 'package:eyadty/features/technicians/presentation/cubit/technicians_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

import '../dialogs/add_technician_leave_dialog.dart';

class TechnicianLeavesSection extends StatelessWidget {
  final String technicianId;

  const TechnicianLeavesSection({super.key, required this.technicianId});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TechniciansCubit>();

    return BlocBuilder<TechniciansCubit, TechniciansState>(
      buildWhen: (prev, curr) => prev.technicianLeaves != curr.technicianLeaves,
      builder: (context, state) {
        final leaves = state.technicianLeaves;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grayE2E8F0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.yellowLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const CustomAssetImage(
                      path: AppIcons.cancelledBooking,
                      width: 18,
                      height: 18,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'leaves'.tr(),
                    style: CustomAppFontStyle.semiBold16.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const Spacer(),
                  CustomPushButton(
                    height: 36,
                    backgroundColor: AppColors.yellowLight,
                    borderRadius: BorderRadius.circular(8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    onTap: () => AddTechnicianLeaveDialog.show(
                      context: context,
                      technicianId: technicianId,
                      techniciansCubit: cubit,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CustomAssetImage(
                          path: AppIcons.add,
                          width: 14,
                          height: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'add_leave'.tr(),
                          style: CustomAppFontStyle.semiBold13.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 16),
              if (leaves.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'no_leaves_found'.tr(),
                      style: CustomAppFontStyle.regular14.copyWith(
                        color: AppColors.gray7A828E,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: leaves.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final leave = leaves[index];
                    return _buildLeaveCard(context, leave, cubit);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaveCard(
    BuildContext context,
    TechnicianLeaveModel leave,
    TechniciansCubit cubit,
  ) {
    final isActive = leave.isCurrentlyActive();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grayf6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.grayE2E8F0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.yellowLight : AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomAssetImage(
              path: AppIcons.calendar,
              width: 20,
              height: 20,
              color: isActive ? AppColors.warning : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${leave.startDate?.toCustomFormat() ?? '-'}  ←  ${leave.endDate?.toCustomFormat() ?? '-'}',
                        style: CustomAppFontStyle.semiBold14.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.warning.withValues(alpha: 0.15)
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive
                            ? 'tech_status_on_leave'.tr()
                            : '${leave.durationDays} ${'days_label'.tr()}',
                        style: CustomAppFontStyle.semiBold12.copyWith(
                          color: isActive
                              ? AppColors.warning
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (leave.reason != null && leave.reason!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    leave.reason!,
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: AppColors.gray7A828E,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDeleteLeave(context, leave, cubit),
            icon: const CustomAssetImage(
              path: AppIcons.delete,
              width: 16,
              height: 16,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLeave(
    BuildContext context,
    TechnicianLeaveModel leave,
    TechniciansCubit cubit,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(
          'delete_leave'.tr(),
          style: CustomAppFontStyle.semiBold16.copyWith(
            color: AppColors.darkText,
          ),
        ),
        content: Text(
          'confirm_delete_leave'.tr(),
          style: CustomAppFontStyle.regular14.copyWith(
            color: AppColors.gray7A828E,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (leave.id != null) {
                cubit.deleteLeave(leave.id!);
              }
            },
            child: Text(
              'delete'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
