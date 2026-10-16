import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/core/network/mony_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_actions_menu.dart';

class BookingsTable extends StatelessWidget {
  final List<BookingModel> bookings;
  final void Function(BookingModel booking)? onViewDetails;
  final void Function(BookingModel booking) onEdit;
  final void Function(BookingModel booking) onChangeStatus;
  final void Function(BookingModel booking) onReassignTechnician;
  final void Function(BookingModel booking) onDelete;

  const BookingsTable({
    super.key,
    required this.bookings,
    this.onViewDetails,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onReassignTechnician,
    required this.onDelete,
  });

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(45), // index
    1: FixedColumnWidth(100), // customer
    2: FixedColumnWidth(120), // service
    3: FixedColumnWidth(120), // technician
    4: FixedColumnWidth(130), // date and time
    5: FixedColumnWidth(70), // price
    6: FixedColumnWidth(90), // status
    7: FixedColumnWidth(25),
  };

  @override
  Widget build(BuildContext context) {
    return CustomTable(
      minWidth: 900,
      columnWidths: columnWidths,
      headers: [
        '#',
        'customer_label'.tr(),
        'service_label'.tr(),
        'technician_label'.tr(),
        'date_and_time_label'.tr(),
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
            style: CustomAppFontStyle.semiBold14.copyWith(
              color: AppColors.darkText,
            ),
          ),
          if (item.customerPhone != null && item.customerPhone!.isNotEmpty) ...[
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
        ],
      ),
    );

    // 2: Service & Booking Type Badge
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
        if (item.bookingType != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: item.bookingType!.backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.bookingType!.label,
              style: CustomAppFontStyle.regular11.copyWith(
                color: item.bookingType!.color,
              ),
            ),
          ),
        ],
      ],
    );

    // 3: Technician
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

    // 4: Rich Date & Time (Line 1: Day & Date, Line 2: Localized 12-hr format)
    final dateStr = BookingTimeFormatter.formatDateWithDay(item.date, context);
    final timeStr = BookingTimeFormatter.formatTimeRange(
      item.startTime,
      item.endTime,
      context,
    );

    final cell4 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          dateStr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CustomAppFontStyle.medium13.copyWith(
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            const CustomAssetImage(
              path: AppIcons.calendar,
              width: 12,
              height: 12,
              color: AppColors.gray71717A,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                timeStr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CustomAppFontStyle.regular13.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    // 5: Price
    final cell5 = Center(
      child: Text(
        '${MonyHelper.formatMoney(item.totalPrice ?? 0)} ${'currency'.tr()}',
        style: CustomAppFontStyle.semiBold16.copyWith(color: AppColors.success),
      ),
    );

    // 6: Status Badge
    final status = item.status ?? BookingStatusEnum.scheduled;
    final cell6 = Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                status.label,
                style: CustomAppFontStyle.regular14.copyWith(
                  color: status.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // 7: Actions Popup Menu
    final cell7 = Center(
      child: BookingActionsMenu(
        onViewDetails: onViewDetails != null
            ? () => onViewDetails!(item)
            : null,
        onEdit: () => onEdit(item),
        onChangeStatus: () => onChangeStatus(item),
        onReassignTechnician: () => onReassignTechnician(item),
        onDelete: () => onDelete(item),
      ),
    );

    return [cell0, cell1, cell2, cell3, cell4, cell5, cell6, cell7];
  }
}
