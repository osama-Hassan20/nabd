import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/doctors/data/models/enums/doctor_gender_enum.dart';
import 'package:eyadty/features/doctors/data/models/enums/doctor_status_enum.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';

import 'doctor_actions_menu.dart';
import 'doctor_status_badge.dart';

class DoctorsTable extends StatelessWidget {
  final List<DoctorModel> doctors;

  const DoctorsTable({super.key, required this.doctors});

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(50), // Index
    1: FixedColumnWidth(150), // Name & Specialty
    2: FixedColumnWidth(140), // Phone
    3: FixedColumnWidth(90), // Gender
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
        'doctor_name'.tr(),
        'phone'.tr(),
        'gender'.tr(),
        'status'.tr(),
        'today_tasks'.tr(),
        'upcoming_bookings'.tr(),
        'actions'.tr(),
      ],
      rows: doctors
          .map(
            (doc) => _buildRow(context, doc, doctors.indexOf(doc) + 1),
          )
          .toList(),
    );
  }

  List<Widget> _buildRow(
    BuildContext context,
    DoctorModel doc,
    int index,
  ) {
    final colors = context.themeColors;

    return [
      // 0: Index
      Center(
        child: Text(
          index.toString(),
          style: CustomAppFontStyle.regular13.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ),

      // 1: Name & Specialty (Clickable)
      InkWell(
        onTap: () {
          if (doc.id != null) {
            context.go('${AppRouter.doctors}/${doc.id}');
          }
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                doc.name ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CustomAppFontStyle.semiBold13.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              if (doc.specialty != null && doc.specialty!.isNotEmpty)
                Text(
                  doc.specialty!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CustomAppFontStyle.regular12.copyWith(
                    color: colors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),

      // 2: Phone
      Center(
        child: Text(
          doc.phone ?? '-',
          textDirection: TextDirection.ltr,
          style: CustomAppFontStyle.regular13.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ),

      // 3: Gender Badge
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: doc.gender == DoctorGenderEnum.female
                ? const Color(0xFFFDF2F8)
                : colors.primaryLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            doc.gender?.label ?? '-',
            style: CustomAppFontStyle.medium12.copyWith(
              color: doc.gender == DoctorGenderEnum.female
                  ? const Color(0xFFDB2777)
                  : colors.primary,
            ),
          ),
        ),
      ),

      // 4: Status Badge
      Center(
        child: DoctorStatusBadge(
          status: doc.status ?? DoctorStatusEnum.available,
        ),
      ),

      // 5: Today's tasks
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surfaceLevel1,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${doc.todayTasksCount ?? 0} ${'tasks'.tr()}',
            style: CustomAppFontStyle.semiBold12.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
      ),

      // 6: Upcoming Bookings
      Center(
        child: Text(
          '${doc.upcomingBookingsCount ?? 0}',
          style: CustomAppFontStyle.semiBold13.copyWith(
            color: colors.primary,
          ),
        ),
      ),

      // 7: Actions Menu
      Center(child: DoctorActionsMenu(doctor: doc)),
    ];
  }
}

