import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/user_role_enum.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
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

class DoctorsScheduleTable extends StatelessWidget {
  final List<DoctorModel> doctors;
  final Map<String, DoctorScheduleModel?> schedules;
  final DoctorsCubit cubit;

  const DoctorsScheduleTable({
    super.key,
    required this.doctors,
    required this.schedules,
    required this.cubit,
  });

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(50),  // Index
    1: FixedColumnWidth(230), // Doctor Name & Specialty
    2: FixedColumnWidth(200), // Working Days / Badge
    3: FixedColumnWidth(160), // Working Hours
    4: FixedColumnWidth(130), // Slot & Buffer
    5: FixedColumnWidth(120), // Upcoming Leaves
    6: FixedColumnWidth(110), // Actions
  };

  @override
  Widget build(BuildContext context) {
    return CustomTable(
      minWidth: 1000,
      columnWidths: columnWidths,
      headers: [
        '#',
        'doctors'.tr(),
        'work_days'.tr(),
        'working_hours'.tr(),
        'slot_duration'.tr(),
        'upcoming_leaves_count'.tr(),
        'actions'.tr(),
      ],
      rows: doctors
          .map(
            (doc) => _buildRow(
              context,
              doc,
              schedules[doc.id],
              doctors.indexOf(doc) + 1,
            ),
          )
          .toList(),
    );
  }

  List<Widget> _buildRow(
    BuildContext context,
    DoctorModel doc,
    DoctorScheduleModel? schedule,
    int index,
  ) {
    final isAdmin =
        getIt<CurrentRoleProvider>().currentRole == UserRoleEnum.admin;
    final workingDays = schedule?.workDays
            ?.where((w) => w.isWorking == true)
            .toList() ??
        [];
    final hasSchedule = workingDays.isNotEmpty;

    // Working days summary
    final daysStr = workingDays
        .map((w) => w.dayOfWeek?.translationKey.tr() ?? '')
        .join('، ');

    final firstDay = workingDays.isNotEmpty ? workingDays.first : null;
    final hoursStr = firstDay != null
        ? BookingTimeFormatter.formatTimeRange(
            firstDay.startTime,
            firstDay.endTime,
            context,
          )
        : '-';

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

      // 1: Doctor Profile
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CustomAssetImage(
                  path: AppIcons.user,
                  width: 18,
                  height: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    doc.name ?? '',
                    style: CustomAppFontStyle.semiBold14.copyWith(
                      color: AppColors.darkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (doc.specialty != null)
                    Text(
                      doc.specialty!,
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: AppColors.gray71717A,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 2: Work Days Summary or No-Schedule Badge
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: hasSchedule
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${workingDays.length} ${'days_work_count'.tr()}',
                    style: CustomAppFontStyle.semiBold13.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    daysStr,
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: AppColors.gray71717A,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : Align(
                alignment: AlignmentDirectional.centerStart,
                child: isAdmin
                    ? InkWell(
                        onTap: () => DoctorScheduleEditorDialog.show(
                          context: context,
                          doctorId: doc.id ?? '',
                          doctorName: doc.name ?? '',
                          doctorsCubit: cubit,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
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
                              const SizedBox(width: 5),
                              Text(
                                'set_schedule'.tr(),
                                style: CustomAppFontStyle.medium12.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'no_schedule_badge'.tr(),
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
              ),
      ),

      // 3: Hours
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          hoursStr,
          style: CustomAppFontStyle.regular13.copyWith(
            color: hasSchedule ? AppColors.darkText : AppColors.gray71717A,
          ),
        ),
      ),

      // 4: Slot & Buffer
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: hasSchedule
            ? Text(
                AppFormatterHelper.formatSlotAndBuffer(
                  schedule?.slotDurationMinutes,
                  schedule?.bufferDurationMinutes,
                  context: context,
                ),
                style: CustomAppFontStyle.regular13.copyWith(
                  color: AppColors.darkText,
                ),
              )
            : Text(
                '-',
                style: CustomAppFontStyle.regular13.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
      ),

      // 5: Upcoming Leaves
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: InkWell(
            onTap: () => DoctorUpcomingLeavesDialog.show(
              context: context,
              doctor: doc,
            ),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_note,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'leaves_details'.tr(),
                    style: CustomAppFontStyle.medium11.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // 6: Actions
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Center(
          child: isAdmin
              ? CustomPushButton(
                  height: 32,
                  backgroundColor: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  onTap: () => DoctorScheduleEditorDialog.show(
                    context: context,
                    doctorId: doc.id ?? '',
                    doctorName: doc.name ?? '',
                    doctorsCubit: cubit,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CustomAssetImage(
                        path: AppIcons.edit,
                        width: 12,
                        height: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'edit_schedule'.tr(),
                        style: CustomAppFontStyle.semiBold12.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    ];
  }
}

