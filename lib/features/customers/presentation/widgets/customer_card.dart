import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purexo/core/routing/routes.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/bookings/data/models/recurrence_rule_model.dart';
import 'package:purexo/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:purexo/features/customers/data/models/customer_model.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:purexo/shared/widgets/custom_container.dart';

import 'customer_actions_menu.dart';

class CustomerCard extends StatelessWidget {
  final CustomerModel customer;

  const CustomerCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (customer.id != null) {
          context.go('${AppRouter.customers}/${customer.id}');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: CustomContainer(
        backGroundColor: AppColors.white,
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayE2E8F0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: Avatar, Name, & Actions ─────────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          customer.name ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CustomAppFontStyle.semiBold15.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      if (customer.hasRepeatedBooking == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'recurring_booking'.tr(),
                            style: CustomAppFontStyle.medium10.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                CustomerActionsMenu(customer: customer),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.grayE2E8F0),
            const SizedBox(height: 12),

            // ─── Contact & Location Info ─────────────────────────────────
            Row(
              children: [
                const CustomAssetImage(
                  path: AppIcons.phone,
                  width: 14,
                  height: 14,
                  color: AppColors.gray71717A,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer.phone ?? '-',
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.end,
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const CustomAssetImage(
                  path: AppIcons.location,
                  width: 14,
                  height: 14,
                  color: AppColors.gray71717A,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer.address ?? '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ),
              ],
            ),

            if (customer.hasRepeatedBooking == true &&
                customer.recurrence?.daySchedules != null &&
                customer.recurrence!.daySchedules!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: customer.recurrence!.daySchedules!.map((sched) {
                    final dayName = DayOfWeekOption.fromKey(sched.day)
                        .getName(context);
                    final timeRange = BookingTimeFormatter.formatTimeRange(
                      sched.startTime,
                      sched.endTime,
                      context,
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.grayE2E8F0),
                      ),
                      child: Text(
                        '$dayName: $timeRange',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // ─── Booking Counts Badges ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'total_bookings'.tr(),
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${customer.totalBookings ?? 0}',
                          style: CustomAppFontStyle.bold13.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (customer.upcomingBookings ?? 0) > 0
                          ? AppColors.secondaryLight
                          : AppColors.grayf2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'upcoming_bookings'.tr(),
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: (customer.upcomingBookings ?? 0) > 0
                                  ? AppColors.success
                                  : AppColors.gray71717A,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${customer.upcomingBookings ?? 0}',
                          style: CustomAppFontStyle.bold13.copyWith(
                            color: (customer.upcomingBookings ?? 0) > 0
                                ? AppColors.success
                                : AppColors.gray71717A,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
