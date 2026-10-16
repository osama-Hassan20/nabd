import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/technicians/data/models/enums/technician_gender_enum.dart';
import 'package:eyadty/features/technicians/data/models/enums/technician_status_enum.dart';
import 'package:eyadty/features/technicians/data/models/technician_model.dart';

import 'technician_actions_menu.dart';
import 'technician_status_badge.dart';

class TechnicianCard extends StatelessWidget {
  final TechnicianModel technician;

  const TechnicianCard({super.key, required this.technician});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (technician.id != null) {
          context.go('${AppRouter.technicians}/${technician.id}');
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
            // Top row: Avatar + Name & Phone + Action menu
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    technician.avatarPath,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        technician.name != null && technician.name!.isNotEmpty
                            ? technician.name!
                                  .trim()
                                  .substring(0, 1)
                                  .toUpperCase()
                            : 'T',
                        style: CustomAppFontStyle.semiBold16.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        technician.name ?? '-',
                        style: CustomAppFontStyle.semiBold14.copyWith(
                          color: AppColors.darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        technician.phone ?? '-',
                        textDirection: TextDirection.ltr,
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: AppColors.gray7A828E,
                        ),
                      ),
                    ],
                  ),
                ),
                TechnicianActionsMenu(technician: technician),
              ],
            ),
            const SizedBox(height: 12),

            // Middle row: Status badge + Gender badge
            Row(
              children: [
                TechnicianStatusBadge(
                  status: technician.status ?? TechnicianStatusEnum.available,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: technician.gender == TechnicianGenderEnum.female
                        ? const Color(0xFFFDF2F8)
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    technician.gender?.label ?? '-',
                    style: CustomAppFontStyle.medium12.copyWith(
                      color: technician.gender == TechnicianGenderEnum.female
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
                      '${technician.todayTasksCount ?? 0}',
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
                      '${technician.upcomingBookingsCount ?? 0}',
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
