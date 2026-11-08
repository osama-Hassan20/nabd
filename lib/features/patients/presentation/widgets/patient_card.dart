import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/network/mony_helper.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/helpers/egyptian_phone_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/enums/blood_group_enum.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';

import 'patient_actions_menu.dart';

class PatientCard extends StatelessWidget {
  final PatientModel patient;

  const PatientCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final age = patient.calculateAgeYears();
    final genderText = patient.gender == GenderEnum.female
        ? 'gender_female'.tr()
        : (patient.gender == GenderEnum.male ? 'gender_male'.tr() : '');
    final hasBlood = patient.bloodGroup != null &&
        patient.bloodGroup != BloodGroupEnum.unknown;

    return InkWell(
      onTap: () {
        if (patient.id != null) {
          context.go('${AppRouter.patients}/${patient.id}');
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
            // ─── Header: Avatar, Name & Badges, Actions ──────────────────
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              patient.name ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CustomAppFontStyle.semiBold15.copyWith(
                                color: AppColors.darkText,
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
                        children: [
                          if (age != null)
                            Text(
                              '$age ${'age_years'.tr()}${genderText.isNotEmpty ? ' • $genderText' : ''}',
                              style: CustomAppFontStyle.regular12.copyWith(
                                color: AppColors.gray71717A,
                              ),
                            ),
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
                PatientActionsMenu(patient: patient),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.grayE2E8F0),
            const SizedBox(height: 12),

            // ─── Phone & Address Chips ──────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.grayf2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const CustomAssetImage(
                    path: AppIcons.phone,
                    width: 12,
                    height: 12,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        EgyptianPhoneHelper.formatDisplay(patient.phone),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CustomAppFontStyle.regular13.copyWith(
                          color: AppColors.darkText,
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
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.grayf2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const CustomAssetImage(
                    path: AppIcons.location,
                    width: 12,
                    height: 12,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    patient.address ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Divider(height: 1, color: AppColors.grayE2E8F0),
            const SizedBox(height: 10),

            // ─── Stats Footer ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatPill(
                  label: 'total_bookings'.tr(),
                  value: '${patient.totalBookings ?? 0}',
                  color: AppColors.primary,
                ),
                _buildStatPill(
                  label: 'upcoming_bookings'.tr(),
                  value: '${patient.upcomingBookings ?? 0}',
                  color: AppColors.cyan,
                ),
                if ((patient.totalSpent ?? 0) > 0)
                  _buildStatPill(
                    label: 'total_spent'.tr(),
                    value:
                        "${MonyHelper.formatMoney(patient.totalSpent ?? 0)} ${'currency'.tr()}",
                    color: AppColors.secondary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CustomAppFontStyle.regular10.copyWith(
            color: AppColors.gray71717A,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: CustomAppFontStyle.semiBold12.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}
