import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/app_images.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/technicians/data/models/enums/technician_gender_enum.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';

import 'package:eyadty/features/technicians/data/models/technician_model.dart';

class BookingDetailsTechniciansSection extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onReassign;

  const BookingDetailsTechniciansSection({
    super.key,
    required this.booking,
    required this.onReassign,
  });

  @override
  Widget build(BuildContext context) {
    final technicians = booking.technicians.isNotEmpty
        ? booking.technicians
        : (booking.technicianName != null &&
                  booking.technicianName!.trim().isNotEmpty
              ? [
                  TechnicianModel(
                    id: booking.technicianId,
                    name: booking.technicianName,
                  ),
                ]
              : <TechnicianModel>[]);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayE2E8F0),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header + Quick Action
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const CustomAssetImage(
                  path: AppIcons.team,
                  width: 18,
                  height: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'assigned_technicians'.tr(),
                  style: CustomAppFontStyle.semiBold16.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
              ),
              InkWell(
                onTap: onReassign,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
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
                      const SizedBox(width: 4),
                      Text(
                        'reassign_technician'.tr(),
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.grayE2E8F0),
          const SizedBox(height: 16),

          if (technicians.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: technicians.map((tech) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grayf6,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grayE2E8F0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            tech.gender == TechnicianGenderEnum.male
                            ? AppColors.primaryLight
                            : AppColors.pink.withValues(alpha: 0.1),
                        child: CustomAssetImage(
                          path: tech.gender == TechnicianGenderEnum.male
                              ? AppImages.cleanerMan
                              : AppImages.cleanerWomen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tech.name?.trim() ?? '',
                        style: CustomAppFontStyle.medium13.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grayf6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 18,
                    color: AppColors.gray71717A,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'technician_unassigned'.tr(),
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
