import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/core/network/mony_helper.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/helpers/egyptian_phone_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/enums/blood_group_enum.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';

import 'patient_actions_menu.dart';

class PatientsTable extends StatelessWidget {
  final List<PatientModel> patients;

  const PatientsTable({super.key, required this.patients});

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(50), // Index
    1: FixedColumnWidth(220), // Name & Info
    2: FixedColumnWidth(140), // Phone
    3: FixedColumnWidth(210), // Address
    4: FixedColumnWidth(110), // Total Bookings
    5: FixedColumnWidth(110), // Upcoming Bookings
    6: FixedColumnWidth(120), // Total Spent
    7: FixedColumnWidth(55), // Actions
  };

  @override
  Widget build(BuildContext context) {
    return CustomTable(
      minWidth: 1015,
      columnWidths: columnWidths,
      headers: [
        '#',
        'name'.tr(),
        'phone'.tr(),
        'address'.tr(),
        'total_bookings'.tr(),
        'upcoming_bookings'.tr(),
        'total_spent'.tr(),
        'actions'.tr(),
      ],
      rows: patients
          .map(
            (patient) =>
                _buildRow(context, patient, patients.indexOf(patient) + 1),
          )
          .toList(),
    );
  }

  List<Widget> _buildRow(
    BuildContext context,
    PatientModel patient,
    int index,
  ) {
    final colors = context.themeColors;
    final age = patient.calculateAgeYears();
    final genderText = patient.gender == GenderEnum.female
        ? 'gender_female'.tr()
        : (patient.gender == GenderEnum.male ? 'gender_male'.tr() : '');
    final hasBlood = patient.bloodGroup != null &&
        patient.bloodGroup != BloodGroupEnum.unknown;

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

      // 1: Name (Clickable to view details) with age/gender and badges
      InkWell(
        onTap: () {
          if (patient.id != null) {
            context.go('${AppRouter.patients}/${patient.id}');
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CustomAssetImage(
                  path: AppIcons.user,
                  width: 16,
                  height: 16,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          patient.name ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ),
                      if (hasBlood) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.red1A,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              patient.bloodGroup!.value,
                              style: CustomAppFontStyle.semiBold10.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (age != null) ...[
                        Text(
                          '$age ${'age_years'.tr()}',
                          style: CustomAppFontStyle.regular11.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        if (genderText.isNotEmpty)
                          Text(
                            ' • $genderText',
                            style: CustomAppFontStyle.regular11.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                      if (patient.hasIncompleteProfile) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'incomplete_profile_badge'.tr(),
                            style: CustomAppFontStyle.medium10.copyWith(
                              color: AppColors.amber,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 2: Phone
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              EgyptianPhoneHelper.formatDisplay(patient.phone),
              textDirection: TextDirection.ltr,
              style: CustomAppFontStyle.regular13.copyWith(
                color: colors.textPrimary,
              ),
            ),
            if (patient.phoneHasWhatsapp == true) ...[
              const SizedBox(width: 4),
              const Tooltip(
                message: 'واتساب متوفر',
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
              ),
            ],
          ],
        ),
      ),

      // 3: Address
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomAssetImage(
              path: AppIcons.location,
              width: 14,
              height: 14,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                patient.address ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CustomAppFontStyle.regular13.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),

      // 4: Total Bookings
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${patient.totalBookings ?? 0}',
            style: CustomAppFontStyle.medium12.copyWith(
              color: colors.primary,
            ),
          ),
        ),
      ),

      // 5: Upcoming Bookings
      Center(
        child: (patient.upcomingBookings ?? 0) > 0
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${patient.upcomingBookings}',
                  style: CustomAppFontStyle.medium12.copyWith(
                    color: AppColors.cyan,
                  ),
                ),
              )
            : Text(
                '-',
                style: CustomAppFontStyle.regular13.copyWith(
                  color: colors.textSecondary,
                ),
              ),
      ),

      // 6: Total Spent
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Text(
          "${MonyHelper.formatMoney(patient.totalSpent ?? 0)} ${'currency'.tr()}",
          style: CustomAppFontStyle.semiBold13.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ),

      // 7: Actions Menu
      Center(child: PatientActionsMenu(patient: patient)),
    ];
  }
}
