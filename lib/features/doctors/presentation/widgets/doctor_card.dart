import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/doctors/data/models/enums/doctor_gender_enum.dart';
import 'package:eyadty/features/doctors/data/models/enums/doctor_status_enum.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';

import 'doctor_actions_menu.dart';
import 'doctor_status_badge.dart';

class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;

  const DoctorCard({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (doctor.id != null) {
          context.go('${AppRouter.doctors}/${doctor.id}');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grayE2E8F0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: Avatar + Name & Specialty & Phone + Action menu
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    doctor.name != null && doctor.name!.isNotEmpty
                        ? doctor.name!.trim().substring(0, 1).toUpperCase()
                        : 'D',
                    style: CustomAppFontStyle.semiBold16.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name ?? '-',
                        style: CustomAppFontStyle.semiBold14.copyWith(
                          color: AppColors.darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (doctor.specialty != null && doctor.specialty!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          doctor.specialty!,
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        doctor.phone ?? '-',
                        textDirection: TextDirection.ltr,
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: AppColors.gray7A828E,
                        ),
                      ),
                    ],
                  ),
                ),
                DoctorActionsMenu(doctor: doctor),
              ],
            ),
            const SizedBox(height: 12),

            // Middle row: Status badge + Gender badge
            Row(
              children: [
                DoctorStatusBadge(
                  status: doctor.status ?? DoctorStatusEnum.available,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: doctor.gender == DoctorGenderEnum.female
                        ? const Color(0xFFFDF2F8)
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    doctor.gender?.label ?? '-',
                    style: CustomAppFontStyle.medium12.copyWith(
                      color: doctor.gender == DoctorGenderEnum.female
                          ? const Color(0xFFDB2777)
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.grayE2E8F0),
            const SizedBox(height: 10),

            // Bottom row: Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${'today_tasks'.tr()}: ',
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: AppColors.gray7A828E,
                      ),
                    ),
                    Text(
                      '${doctor.todayTasksCount ?? 0}',
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${'upcoming_bookings'.tr()}: ',
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: AppColors.gray7A828E,
                      ),
                    ),
                    Text(
                      '${doctor.upcomingBookingsCount ?? 0}',
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

