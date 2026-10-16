import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:purexo/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:purexo/core/network/mony_helper.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/bookings/data/models/booking_model.dart';
import 'package:purexo/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:purexo/features/bookings/data/models/recurrence_rule_model.dart';
import 'package:purexo/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:purexo/features/bookings/presentation/widgets/booking_actions_menu.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';

class RecurringBookingsTable extends StatelessWidget {
  final List<BookingModel> bookings;
  final void Function(BookingModel booking)? onViewDetails;
  final void Function(BookingModel booking) onEdit;
  final void Function(BookingModel booking) onChangeStatus;
  final void Function(BookingModel booking) onReassignTechnician;
  final void Function(BookingModel booking) onDelete;

  const RecurringBookingsTable({
    super.key,
    required this.bookings,
    this.onViewDetails,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onReassignTechnician,
    required this.onDelete,
  });

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(50), // ID / index
    1: FixedColumnWidth(110), // Customer
    2: FixedColumnWidth(120), // Service
    3: FixedColumnWidth(120), // Technicians
    4: FixedColumnWidth(190), // Recurring schedule & days
    5: FixedColumnWidth(140), // Subscription period
    6: FixedColumnWidth(80), // Price
    7: FixedColumnWidth(90), // Status
    8: FixedColumnWidth(30), // Actions
  };

  @override
  Widget build(BuildContext context) {
    return CustomTable(
      minWidth: 960,
      columnWidths: columnWidths,
      headers: [
        '#',
        'customer_label'.tr(),
        'service_label'.tr(),
        'technician_label'.tr(),
        'recurring_days_schedule'.tr(),
        'subscription_period'.tr(),
        'price_label'.tr(),
        'status_label'.tr(),
        'actions_label'.tr(),
      ],
      rows: bookings
          .map(
            (booking) =>
                _buildRow(context, booking, bookings.indexOf(booking) + 1),
          )
          .toList(),
    );
  }

  List<Widget> _buildRow(BuildContext context, BookingModel item, int index) {
    // 0: Index / ID
    final cell0 = Center(
      child: InkWell(
        onTap: () => onViewDetails?.call(item),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            item.id ?? '#$index',
            style: CustomAppFontStyle.medium12.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );

    // 1: Customer (Name + Phone)
    final cell1 = InkWell(
      onTap: () => onViewDetails?.call(item),
      borderRadius: BorderRadius.circular(4),
      child: Column(
        spacing: 2,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.customerName ?? 'customer_unassigned'.tr(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: CustomAppFontStyle.semiBold14.copyWith(
              color: AppColors.darkText,
            ),
          ),
          if (item.customerPhone != null && item.customerPhone!.isNotEmpty)
            Text(
              item.customerPhone!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: CustomAppFontStyle.regular12.copyWith(
                color: AppColors.gray71717A,
              ),
            ),
        ],
      ),
    );

    // 2: Service & Badge
    final cell2 = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          item.serviceName ?? 'service_default'.tr(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: CustomAppFontStyle.medium13.copyWith(
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'recurring_bookings_tab'.tr(),
            style: CustomAppFontStyle.regular11.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );

    // 3: Technicians
    final hasMultipleTechs = item.technicianNames.length > 1;
    final primaryTech = item.technicianNames.isNotEmpty
        ? item.technicianNames.first
        : (item.technicianName ?? 'technician_unassigned'.tr());
    final isUnassigned =
        item.technicianNames.isEmpty &&
        (item.technicianName == null || item.technicianName!.isEmpty);

    final cell3 = Center(
      child: isUnassigned
          ? Text(
              'technician_unassigned'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CustomAppFontStyle.regular13.copyWith(
                color: AppColors.gray71717A,
              ),
            )
          : Tooltip(
              message: item.technicianNames.isNotEmpty
                  ? item.technicianNames.join('، ')
                  : primaryTech,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      primaryTech,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CustomAppFontStyle.regular13.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  if (hasMultipleTechs) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+${item.technicianNames.length - 1}',
                        style: CustomAppFontStyle.semiBold11.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );

    // 4: Recurring Days & Schedule
    final schedules = item.recurrence?.daySchedules ?? const [];
    Widget cell4;
    if (schedules.isNotEmpty) {
      cell4 = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: schedules.map((s) {
            final dayName = DayOfWeekOption.fromKey(s.day).getName(context);
            final timeRange = BookingTimeFormatter.formatTimeRange(
              s.startTime,
              s.endTime,
              context,
            );
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.grayf2,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.grayE2E8F0, width: 0.8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayName,
                    style: CustomAppFontStyle.semiBold11.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    timeRange,
                    style: CustomAppFontStyle.regular11.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    } else {
      // Fallback if daySchedules is empty but single time exists
      final fallbackTime = BookingTimeFormatter.formatTimeRange(
        item.startTime,
        item.endTime,
        context,
      );
      cell4 = Center(
        child: Text(
          fallbackTime,
          style: CustomAppFontStyle.regular12.copyWith(
            color: AppColors.darkText,
          ),
        ),
      );
    }

    // 5: Subscription Period (Start date + Ongoing/End date)
    final recurrence = item.recurrence;
    final isOngoing = recurrence?.isOngoing ?? true;
    final startDateStr = recurrence?.startDate != null
        ? BookingTimeFormatter.formatCompactDate(
            recurrence!.startDate!,
            context,
          )
        : (item.date != null
            ? BookingTimeFormatter.formatCompactDate(item.date!, context)
            : '—');

    final cell5 = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${'recurring_start_date'.tr()}: $startDateStr',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CustomAppFontStyle.regular11.copyWith(
            color: AppColors.gray71717A,
          ),
        ),
        const SizedBox(height: 3),
        if (isOngoing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'ongoing_until_cancelled'.tr(),
              style: CustomAppFontStyle.medium11.copyWith(
                color: AppColors.success,
              ),
            ),
          )
        else if (recurrence?.endDate != null)
          Text(
            '${'recurrence_ends_on'.tr()} ${BookingTimeFormatter.formatCompactDate(recurrence!.endDate!, context)}',
            style: CustomAppFontStyle.regular11.copyWith(
              color: AppColors.red,
            ),
          ),
      ],
    );

    // 6: Price
    final cell6 = Center(
      child: Text(
        '${MonyHelper.formatMoney(item.totalPrice ?? 0)} ${'currency'.tr()}',
        style: CustomAppFontStyle.semiBold13.copyWith(
          color: AppColors.primary,
        ),
      ),
    );

    // 7: Status Badge
    final status = item.status ?? BookingStatusEnum.scheduled;
    final cell7 = Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );

    // 8: Actions Menu
    final cell8 = Center(
      child: BookingActionsMenu(
        onViewDetails:
            onViewDetails != null ? () => onViewDetails!(item) : null,
        onEdit: () => onEdit(item),
        onChangeStatus: () => onChangeStatus(item),
        onReassignTechnician: () => onReassignTechnician(item),
        onDelete: () => onDelete(item),
      ),
    );

    return [
      cell0,
      cell1,
      cell2,
      cell3,
      cell4,
      cell5,
      cell6,
      cell7,
      cell8,
    ];
  }
}
