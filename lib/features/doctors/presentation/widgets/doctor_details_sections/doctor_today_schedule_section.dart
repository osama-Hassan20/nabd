import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';

class DoctorTodayScheduleSection extends StatelessWidget {
  const DoctorTodayScheduleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DoctorsCubit, DoctorsState>(
      buildWhen: (prev, curr) =>
          prev.doctorBookings != curr.doctorBookings,
      builder: (context, state) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

        final todayBookings =
            state.doctorBookings.where((b) {
              final bDate = b.date;
              if (bDate == null) return false;
              return bDate.isAfter(
                    todayStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  bDate.isBefore(todayEnd.add(const Duration(seconds: 1)));
            }).toList()..sort(
              (a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''),
            );

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
                      path: AppIcons.calendar,
                      width: 18,
                      height: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'today_schedule'.tr(),
                    style: CustomAppFontStyle.semiBold16.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grayf2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${todayBookings.length} ${'tasks'.tr()}',
                      style: CustomAppFontStyle.semiBold12.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 16),
              if (todayBookings.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const CustomAssetImage(
                          path: AppIcons.calendar,
                          width: 32,
                          height: 32,
                          color: AppColors.gray7A828E,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'no_today_tasks'.tr(),
                          style: CustomAppFontStyle.medium14.copyWith(
                            color: AppColors.gray7A828E,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayBookings.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = todayBookings[index];
                    return _buildScheduleCard(context, booking);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleCard(BuildContext context, BookingModel booking) {
    final status = booking.status ?? BookingStatusEnum.scheduled;

    return InkWell(
      onTap: () {
        if (booking.id != null) {
          context.go('${AppRouter.bookings}/${booking.id}');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grayf6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grayE2E8F0),
        ),
        child: Row(
          children: [
            // Time range badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.grayE2E8F0),
              ),
              child: Text(
                '${booking.startTime ?? '00:00'} - ${booking.endTime ?? '00:00'}',
                style: CustomAppFontStyle.semiBold13.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Service & Patient
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.serviceName ?? 'Service',
                    style: CustomAppFontStyle.semiBold14.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const CustomAssetImage(
                        path: AppIcons.user,
                        width: 14,
                        height: 14,
                        color: AppColors.gray7A828E,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          booking.patientName ?? booking.customerName ?? '-',
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: AppColors.gray7A828E,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: status.backgroundColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status.label,
                style: CustomAppFontStyle.medium12.copyWith(
                  color: status.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

