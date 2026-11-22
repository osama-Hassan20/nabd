import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/user_role_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/helpers/app_formatter_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/doctors/presentation/widgets/dialogs/doctor_schedule_editor_dialog.dart';
import 'package:eyadty/features/doctors/presentation/widgets/dialogs/doctor_upcoming_leaves_dialog.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

class DoctorsScheduleCard extends StatelessWidget {
  final DoctorModel doctor;
  final DoctorScheduleModel? schedule;
  final DoctorsCubit cubit;

  const DoctorsScheduleCard({
    super.key,
    required this.doctor,
    this.schedule,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final isAdmin =
        getIt<CurrentRoleProvider>().currentRole == UserRoleEnum.admin;
    final workingDays = schedule?.workDays
            ?.where((w) => w.isWorking == true)
            .toList() ??
        [];
    final hasSchedule = workingDays.isNotEmpty;

    final firstDay = workingDays.isNotEmpty ? workingDays.first : null;
    final hoursStr = firstDay != null
        ? BookingTimeFormatter.formatTimeRange(
            firstDay.startTime,
            firstDay.endTime,
            context,
          )
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomAssetImage(
                    path: AppIcons.user,
                    width: 20,
                    height: 20,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name ?? '',
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    if (doctor.specialty != null)
                      Text(
                        doctor.specialty!,
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (!hasSchedule)
                isAdmin
                    ? InkWell(
                        onTap: () => DoctorScheduleEditorDialog.show(
                          context: context,
                          doctorId: doctor.id ?? '',
                          doctorName: doctor.name ?? '',
                          doctorsCubit: cubit,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomAssetImage(
                                path: AppIcons.edit,
                                width: 12,
                                height: 12,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'set_schedule'.tr(),
                                style: CustomAppFontStyle.medium11.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'no_schedule_badge'.tr(),
                          style: CustomAppFontStyle.medium11.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 12),
          if (hasSchedule) ...[
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context: context,
                    label: 'work_days'.tr(),
                    value: '${workingDays.length} ${'days_work_count'.tr()}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context: context,
                    label: 'working_hours'.tr(),
                    value: hoursStr,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context: context,
                    label: 'slot_duration'.tr(),
                    value: AppFormatterHelper.formatMinutes(
                      schedule?.slotDurationMinutes ?? 20,
                      context: context,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context: context,
                    label: 'buffer_duration'.tr(),
                    value: AppFormatterHelper.formatMinutes(
                      schedule?.bufferDurationMinutes ?? 5,
                      context: context,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => DoctorUpcomingLeavesDialog.show(
                    context: context,
                    doctor: doctor,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: colors.surfaceLevel1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 15,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'upcoming_leaves'.tr(),
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: CustomPushButton(
                    height: 36,
                    backgroundColor: colors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => DoctorScheduleEditorDialog.show(
                      context: context,
                      doctorId: doctor.id ?? '',
                      doctorName: doctor.name ?? '',
                      doctorsCubit: cubit,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomAssetImage(
                          path: AppIcons.edit,
                          width: 14,
                          height: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'edit_schedule'.tr(),
                          style: CustomAppFontStyle.semiBold13.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final colors = context.themeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CustomAppFontStyle.regular12.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: CustomAppFontStyle.semiBold13.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
