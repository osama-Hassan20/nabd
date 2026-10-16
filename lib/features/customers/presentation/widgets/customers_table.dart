import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purexo/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:purexo/core/routing/routes.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/bookings/data/models/recurrence_rule_model.dart';
import 'package:purexo/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:purexo/features/customers/data/models/customer_model.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';

import 'customer_actions_menu.dart';

class CustomersTable extends StatelessWidget {
  final List<CustomerModel> customers;

  const CustomersTable({super.key, required this.customers});

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(50), // Index
    1: FixedColumnWidth(170), // Name
    2: FixedColumnWidth(130), // Phone
    3: FixedColumnWidth(210), // Address
    4: FixedColumnWidth(230), // Repeated Schedule (Days & Time)
    5: FixedColumnWidth(100), // Total Bookings
    6: FixedColumnWidth(110), // Upcoming Bookings
    7: FixedColumnWidth(55), // Actions
  };

  @override
  Widget build(BuildContext context) {
    return CustomTable(
      minWidth: 1055,
      columnWidths: columnWidths,
      headers: [
        '#',
        'name'.tr(),
        'phone'.tr(),
        'address'.tr(),
        'recurring_schedule'.tr(),
        'total_bookings'.tr(),
        'upcoming_bookings'.tr(),
        'actions'.tr(),
      ],
      rows: customers
          .map(
            (customer) =>
                _buildRow(context, customer, customers.indexOf(customer) + 1),
          )
          .toList(),
    );
  }

  List<Widget> _buildRow(
    BuildContext context,
    CustomerModel customer,
    int index,
  ) {
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

      // 1: Name (Clickable to view details)
      InkWell(
        onTap: () {
          if (customer.id != null) {
            context.go('${AppRouter.customers}/${customer.id}');
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                customer.name ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CustomAppFontStyle.semiBold13.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ),
          ],
        ),
      ),

      // 2: Phone
      Center(
        child: Text(
          customer.phone ?? '-',
          textDirection: TextDirection.ltr,
          style: CustomAppFontStyle.regular13.copyWith(
            color: AppColors.darkText,
          ),
        ),
      ),

      // 3: Address
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CustomAssetImage(
            path: AppIcons.location,
            width: 14,
            height: 14,
            color: AppColors.gray71717A,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              customer.address ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CustomAppFontStyle.regular13.copyWith(
                color: AppColors.gray71717A,
              ),
            ),
          ),
        ],
      ),

      // 4: Repeated Schedule (Days & Times)
      Center(
        child:
            (customer.hasRepeatedBooking == true &&
                customer.recurrence?.daySchedules != null &&
                customer.recurrence!.daySchedules!.isNotEmpty)
            ? Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
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
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '$dayName: $timeRange',
                      style: CustomAppFontStyle.medium11.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }).toList(),
              )
            : (customer.hasRepeatedBooking == true)
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'recurring_booking'.tr(),
                  style: CustomAppFontStyle.medium12.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              )
            : Text(
                '-',
                style: CustomAppFontStyle.regular13.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
      ),

      // 5: Total Bookings Badge
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${customer.totalBookings ?? 0}',
            style: CustomAppFontStyle.semiBold12.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ),

      // 6: Upcoming Bookings Badge
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (customer.upcomingBookings ?? 0) > 0
                ? AppColors.secondaryLight
                : AppColors.grayf2,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${customer.upcomingBookings ?? 0}',
            style: CustomAppFontStyle.semiBold12.copyWith(
              color: (customer.upcomingBookings ?? 0) > 0
                  ? AppColors.success
                  : AppColors.gray71717A,
            ),
          ),
        ),
      ),

      // 7: Actions Menu
      Center(child: CustomerActionsMenu(customer: customer)),
    ];
  }
}
