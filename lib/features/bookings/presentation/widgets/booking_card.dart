import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:purexo/core/network/mony_helper.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/bookings/data/models/booking_model.dart';
import 'package:purexo/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:purexo/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:purexo/features/bookings/presentation/widgets/booking_actions_menu.dart';
import 'package:purexo/shared/widgets/custom_container.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onChangeStatus;
  final VoidCallback onReassignTechnician;
  final VoidCallback onDelete;

  const BookingCard({
    super.key,
    required this.booking,
    this.onViewDetails,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onReassignTechnician,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = booking.status ?? BookingStatusEnum.scheduled;
    final dateStr = BookingTimeFormatter.formatDateWithDay(
      booking.date,
      context,
    );
    final timeStr = BookingTimeFormatter.formatTimeRange(
      booking.startTime,
      booking.endTime,
      context,
    );

    return InkWell(
      onTap: onViewDetails,
      borderRadius: BorderRadius.circular(12),
      child: CustomContainer(
        backGroundColor: AppColors.white,
        padding: const EdgeInsets.all(16),
        borderRaduis: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: ID + Status Badge + Actions Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grayf2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      booking.id ?? '#',
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: status.backgroundColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomAssetImage(
                          path: status.icon,
                          width: 12,
                          height: 12,
                          color: status.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status.label,
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              BookingActionsMenu(
                onViewDetails: onViewDetails,
                onEdit: onEdit,
                onChangeStatus: onChangeStatus,
                onReassignTechnician: onReassignTechnician,
                onDelete: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Customer Information
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.grayf2,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const CustomAssetImage(
                  path: AppIcons.user,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName ?? 'customer_unassigned'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                    if (booking.customerPhone != null)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          booking.customerPhone!,
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: AppColors.gray71717A,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${MonyHelper.formatMoney(booking.totalPrice ?? 0)} ${'currency'.tr()}',
                style: CustomAppFontStyle.bold16.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Service + Type Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.serviceName ?? 'service_default'.tr(),
                  style: CustomAppFontStyle.medium13.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
              ),
              if (booking.bookingType != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: booking.bookingType!.backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    booking.bookingType!.label,
                    style: CustomAppFontStyle.regular11.copyWith(
                      color: booking.bookingType!.color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Date & Time
          Row(
            children: [
              const CustomAssetImage(
                path: AppIcons.calendar,
                width: 14,
                height: 14,
                color: AppColors.gray71717A,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$dateStr • $timeStr',
                  style: CustomAppFontStyle.regular12.copyWith(
                    color: AppColors.gray71717A,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Technician(s)
          Row(
            children: [
              const CustomAssetImage(
                path: AppIcons.team,
                width: 14,
                height: 14,
                color: AppColors.gray71717A,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: booking.technicianNames.length > 1
                    ? Tooltip(
                        message: booking.technicianNames.join('، '),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                booking.technicianNames.first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CustomAppFontStyle.regular12.copyWith(
                                  color: AppColors.gray71717A,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '+${booking.technicianNames.length - 1}',
                                style: CustomAppFontStyle.semiBold11.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        booking.technicianName ?? 'technician_unassigned'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: AppColors.gray71717A,
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
