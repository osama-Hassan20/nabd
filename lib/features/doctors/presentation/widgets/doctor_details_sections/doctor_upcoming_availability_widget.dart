import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/doctors/data/models/enums/doctor_availability_enum.dart';
import 'package:eyadty/features/doctors/domain/helpers/doctor_availability_helper.dart';
import 'package:eyadty/features/settings/data/models/special_holiday_model.dart';

class DoctorUpcomingAvailabilityWidget extends StatelessWidget {
  final DoctorScheduleModel? schedule;
  final List<DoctorLeaveModel>? leaves;
  final List<SpecialHolidayModel>? holidays;
  final DateTime? customNow;

  const DoctorUpcomingAvailabilityWidget({
    super.key,
    this.schedule,
    this.leaves,
    this.holidays,
    this.customNow,
  });

  @override
  Widget build(BuildContext context) {
    final today = DoctorAvailabilityHelper.getTodayCairo(customNow);
    final next14Days = List.generate(14, (i) => today.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                'upcoming_14_days_availability'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: next14Days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final date = next14Days[index];
                final availability = DoctorAvailabilityHelper.getDayAvailability(
                  schedule: schedule,
                  leaves: leaves,
                  holidays: holidays,
                  date: date,
                  customNow: customNow,
                );

                return _buildDayCard(context, date, availability);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    DateTime date,
    DoctorAvailabilityEnum availability,
  ) {
    Color bg;
    Color text;
    String labelKey;

    switch (availability) {
      case DoctorAvailabilityEnum.available:
        bg = AppColors.success.withValues(alpha: 0.12);
        text = AppColors.success;
        labelKey = 'available';
        break;
      case DoctorAvailabilityEnum.onLeave:
        bg = AppColors.warning.withValues(alpha: 0.15);
        text = AppColors.warning;
        labelKey = 'on_leave';
        break;
      case DoctorAvailabilityEnum.facilityHoliday:
        bg = AppColors.lightBlue;
        text = AppColors.blue;
        labelKey = 'facility_holiday';
        break;
      case DoctorAvailabilityEnum.notWorkingDay:
        bg = AppColors.grayE2E8F0;
        text = AppColors.gray71717A;
        labelKey = 'not_working_day';
        break;
      case DoctorAvailabilityEnum.noSchedule:
        bg = AppColors.warning.withValues(alpha: 0.1);
        text = AppColors.warning;
        labelKey = 'no_schedule';
        break;
    }

    final dayName = BookingTimeFormatter.formatDayName(date, context);
    final dayNum = '${date.day}';

    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grayf6,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CustomAppFontStyle.medium11.copyWith(
              color: AppColors.gray71717A,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dayNum,
            style: CustomAppFontStyle.bold14.copyWith(
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              labelKey.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CustomAppFontStyle.semiBold10.copyWith(
                color: text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
