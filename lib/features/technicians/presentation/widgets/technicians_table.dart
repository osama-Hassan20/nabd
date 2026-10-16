import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/technicians/data/models/enums/technician_gender_enum.dart';
import 'package:eyadty/features/technicians/data/models/enums/technician_status_enum.dart';
import 'package:eyadty/features/technicians/data/models/technician_model.dart';

import 'technician_actions_menu.dart';
import 'technician_status_badge.dart';

class TechniciansTable extends StatelessWidget {
  final List<TechnicianModel> technicians;

  const TechniciansTable({super.key, required this.technicians});

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(50), // Index
    1: FixedColumnWidth(120), // Name & Avatar
    2: FixedColumnWidth(150), // Phone
    3: FixedColumnWidth(100), // Gender
    4: FixedColumnWidth(130), // Status
    5: FixedColumnWidth(120), // Today's tasks
    6: FixedColumnWidth(80), // Upcoming Bookings
    7: FixedColumnWidth(60), // Actions
  };

  @override
  Widget build(BuildContext context) {
    return CustomTable(
      minWidth: 970,
      columnWidths: columnWidths,
      headers: [
        '#',
        'name'.tr(),
        'phone'.tr(),
        'gender'.tr(),
        'status'.tr(),
        'today_tasks'.tr(),
        'upcoming_bookings'.tr(),
        'actions'.tr(),
      ],
      rows: technicians
          .map(
            (tech) => _buildRow(context, tech, technicians.indexOf(tech) + 1),
          )
          .toList(),
    );
  }

  List<Widget> _buildRow(
    BuildContext context,
    TechnicianModel tech,
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

      // 1: Name & Avatar (Clickable)
      InkWell(
        onTap: () {
          if (tech.id != null) {
            context.go('${AppRouter.technicians}/${tech.id}');
          }
        },
        child: Center(
          child: Text(
            tech.name ?? '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CustomAppFontStyle.semiBold13.copyWith(
              color: AppColors.darkText,
            ),
          ),
        ),
      ),

      // 2: Phone
      Center(
        child: Text(
          tech.phone ?? '-',
          textDirection: TextDirection.ltr,
          style: CustomAppFontStyle.regular13.copyWith(
            color: AppColors.darkText,
          ),
        ),
      ),

      // 3: Gender Badge
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: tech.gender == TechnicianGenderEnum.female
                ? const Color(0xFFFDF2F8)
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tech.gender?.label ?? '-',
            style: CustomAppFontStyle.medium12.copyWith(
              color: tech.gender == TechnicianGenderEnum.female
                  ? const Color(0xFFDB2777)
                  : AppColors.primary,
            ),
          ),
        ),
      ),

      // 4: Status Badge
      Center(
        child: TechnicianStatusBadge(
          status: tech.status ?? TechnicianStatusEnum.available,
        ),
      ),

      // 5: Today's tasks
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.grayf2,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${tech.todayTasksCount ?? 0} ${'tasks'.tr()}',
            style: CustomAppFontStyle.semiBold12.copyWith(
              color: AppColors.darkText,
            ),
          ),
        ),
      ),

      // 6: Upcoming Bookings
      Center(
        child: Text(
          '${tech.upcomingBookingsCount ?? 0}',
          style: CustomAppFontStyle.semiBold13.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),

      // 7: Actions Menu
      Center(child: TechnicianActionsMenu(technician: tech)),
    ];
  }
}
