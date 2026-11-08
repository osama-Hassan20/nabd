import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/enums/user_role_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/domain/helpers/doctor_availability_helper.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

import '../dialogs/add_doctor_leave_dialog.dart';

class DoctorLeavesSection extends StatelessWidget {
  final String doctorId;

  const DoctorLeavesSection({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DoctorsCubit>();
    final roleProvider = context.read<CurrentRoleProvider?>();
    final isAdmin = roleProvider?.currentRole == UserRoleEnum.admin;

    return BlocBuilder<DoctorsCubit, DoctorsState>(
      buildWhen: (prev, curr) => prev.doctorLeaves != curr.doctorLeaves,
      builder: (context, state) {
        final leaves = state.doctorLeaves;

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
                  if (isAdmin)
                    CustomPushButton(
                      height: 36,
                      backgroundColor: AppColors.yellowLight,
                      borderRadius: BorderRadius.circular(8),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      onTap: () => AddDoctorLeaveDialog.show(
                        context: context,
                        doctorId: doctorId,
                        doctorsCubit: cubit,
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
                    return _buildLeaveCard(context, leave, cubit, isAdmin);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildLeaveCard(
    BuildContext context,
    DoctorLeaveModel leave,
    DoctorsCubit cubit,
    bool isAdmin,
  ) {
    final today = DoctorAvailabilityHelper.getTodayCairo();
    final start = leave.startDate != null
        ? DoctorAvailabilityHelper.dateOnly(leave.startDate!)
        : today;
    final end = leave.endDate != null
        ? DoctorAvailabilityHelper.dateOnly(leave.endDate!)
        : today;

    final isPast = end.isBefore(today);
    final isOngoing = !today.isBefore(start) && !today.isAfter(end);
    final isUpcoming = start.isAfter(today);

    String statusText;
    Color statusBg;
    Color statusTextColor;

    if (isOngoing) {
      statusText = 'leave_status_ongoing'.tr();
      statusBg = AppColors.warning.withValues(alpha: 0.15);
      statusTextColor = AppColors.warning;
    } else if (isUpcoming) {
      statusText = 'leave_status_upcoming'.tr();
      statusBg = AppColors.primaryLight;
      statusTextColor = AppColors.primary;
    } else {
      statusText = 'leave_status_past'.tr();
      statusBg = AppColors.grayE2E8F0;
      statusTextColor = AppColors.gray71717A;
    }

    return Opacity(
      opacity: isPast ? 0.65 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grayf6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOngoing
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
                color: isOngoing
                    ? AppColors.yellowLight
                    : (isUpcoming ? AppColors.primaryLight : AppColors.white),
                borderRadius: BorderRadius.circular(10),
              ),
              child: CustomAssetImage(
                path: AppIcons.calendar,
                width: 20,
                height: 20,
                color: isOngoing
                    ? AppColors.warning
                    : (isUpcoming ? AppColors.primary : AppColors.gray71717A),
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
                          '${_formatDate(leave.startDate)}  ←  ${_formatDate(leave.endDate)}',
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
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: CustomAppFontStyle.semiBold12.copyWith(
                            color: statusTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${leave.durationDays} ${'days_label'.tr()})',
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: AppColors.gray71717A,
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
            if (isAdmin)
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
      ),
    );
  }

  void _confirmDeleteLeave(
    BuildContext context,
    DoctorLeaveModel leave,
    DoctorsCubit cubit,
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
