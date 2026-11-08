import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/enums/user_role_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/core/utils/helpers/app_formatter_helper.dart';
import 'package:eyadty/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_state.dart';
import 'package:eyadty/features/doctors/presentation/widgets/dialogs/doctor_schedule_editor_dialog.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'doctor_upcoming_availability_widget.dart';

class DoctorScheduleCardSection extends StatelessWidget {
  final DoctorModel doctor;

  const DoctorScheduleCardSection({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DoctorsCubit>();
    final roleProvider = context.read<CurrentRoleProvider?>();
    final isAdmin = roleProvider?.currentRole == UserRoleEnum.admin;

    return BlocBuilder<DoctorsCubit, DoctorsState>(
      buildWhen: (prev, curr) =>
          prev.selectedDoctorSchedule != curr.selectedDoctorSchedule ||
          prev.doctorLeaves != curr.doctorLeaves,
      builder: (context, state) {
        final schedule = state.selectedDoctorSchedule;
        final hasSchedule = schedule != null &&
            schedule.workDays != null &&
            schedule.workDays!.any((w) => w.isWorking == true);

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
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const CustomAssetImage(
                      path: AppIcons.clock,
                      width: 18,
                      height: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'doctor_schedule'.tr(),
                    style: CustomAppFontStyle.semiBold16.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const Spacer(),
                  if (!hasSchedule)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'no_schedule_badge'.tr(),
                        style: CustomAppFontStyle.semiBold12.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  if (isAdmin) ...[
                    const SizedBox(width: 10),
                    CustomPushButton(
                      height: 34,
                      backgroundColor: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onTap: () => DoctorScheduleEditorDialog.show(
                        context: context,
                        doctorId: doctor.id ?? '',
                        doctorName: doctor.name ?? '',
                        doctorsCubit: cubit,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CustomAssetImage(
                            path: AppIcons.edit,
                            width: 13,
                            height: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hasSchedule
                                ? 'edit_schedule'.tr()
                                : 'set_schedule'.tr(),
                            style: CustomAppFontStyle.semiBold12.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 16),

              if (hasSchedule) ...[
                _buildScheduleOverview(context, schedule),
                const SizedBox(height: 16),
              ] else ...[
                _buildNoScheduleBanner(context, cubit, doctor, isAdmin),
                const SizedBox(height: 16),
              ],

              // 14-day availability strip
              DoctorUpcomingAvailabilityWidget(
                schedule: schedule,
                leaves: state.doctorLeaves,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleOverview(
    BuildContext context,
    dynamic schedule,
  ) {
    final workingDays = (schedule.workDays as List?)
            ?.where((w) => w.isWorking == true)
            .toList() ??
        [];

    final daysStr = workingDays
        .map((w) => w.dayOfWeek.translationKey.tr())
        .join('، ');

    final firstDay = workingDays.isNotEmpty ? workingDays.first : null;
    final hoursStr = firstDay != null
        ? BookingTimeFormatter.formatTimeRange(
            firstDay.startTime,
            firstDay.endTime,
            context,
          )
        : '-';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.grayf6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          _buildInfoItem(
            icon: AppIcons.calendar,
            label: 'work_days'.tr(),
            value: '${workingDays.length} ${'days_work_count'.tr()} ($daysStr)',
          ),
          _buildInfoItem(
            icon: AppIcons.clock,
            label: 'working_hours'.tr(),
            value: hoursStr,
          ),
          _buildInfoItem(
            icon: AppIcons.service,
            label: 'slot_duration'.tr(),
            value: AppFormatterHelper.formatMinutes(
              schedule.slotDurationMinutes ?? 20,
              context: context,
            ),
          ),
          _buildInfoItem(
            icon: AppIcons.status,
            label: 'buffer_duration'.tr(),
            value: AppFormatterHelper.formatMinutes(
              schedule.bufferDurationMinutes ?? 5,
              context: context,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomAssetImage(
          path: icon,
          width: 16,
          height: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: CustomAppFontStyle.regular12.copyWith(
                color: AppColors.gray71717A,
              ),
            ),
            Text(
              value,
              style: CustomAppFontStyle.semiBold13.copyWith(
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoScheduleBanner(
    BuildContext context,
    DoctorsCubit cubit,
    dynamic doctor,
    bool isAdmin,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const CustomAssetImage(
              path: AppIcons.clock,
              width: 24,
              height: 24,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'doctor_no_schedule_hint'.tr(),
            style: CustomAppFontStyle.semiBold14.copyWith(
              color: AppColors.darkText,
            ),
            textAlign: TextAlign.center,
          ),
          if (isAdmin) ...[
            const SizedBox(height: 16),
            CustomPushButton(
              height: 38,
              backgroundColor: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              onTap: () => DoctorScheduleEditorDialog.show(
                context: context,
                doctorId: doctor.id ?? '',
                doctorName: doctor.name ?? '',
                doctorsCubit: cubit,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomAssetImage(
                    path: AppIcons.edit,
                    width: 14,
                    height: 14,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'set_schedule'.tr(),
                    style: CustomAppFontStyle.semiBold13.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

