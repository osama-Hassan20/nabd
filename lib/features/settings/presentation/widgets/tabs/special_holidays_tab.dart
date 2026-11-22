import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/extensions/date_time_extentision.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/settings/data/models/special_holiday_model.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_state.dart';
import 'package:eyadty/features/settings/presentation/widgets/dialogs/add_special_holiday_dialog.dart';
import 'package:eyadty/features/settings/presentation/widgets/dialogs/delete_holiday_dialog.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class SpecialHolidaysTab extends StatelessWidget {
  final SettingsCubit settingsCubit;

  const SpecialHolidaysTab({super.key, required this.settingsCubit});

  @override
  Widget build(BuildContext context) {
    final isMobile = AdaptiveLayout.isMobile(context);
    final colors = context.themeColors;

    return BlocBuilder<SettingsCubit, SettingsState>(
      bloc: settingsCubit,
      builder: (context, state) {
        final holidays = state.settings?.specialHolidays ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: CustomContainer(
            padding: const EdgeInsets.all(24),
            backGroundColor: colors.cardBackground,
            border: Border.all(color: colors.borderSubtle),
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header & Add Button ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CustomAssetImage(
                                  path: AppIcons.calendar,
                                  width: 20,
                                  height: 20,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'special_holidays'.tr(),
                                style: CustomAppFontStyle.semiBold18.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'special_holidays_desc'.tr(),
                            style: CustomAppFontStyle.regular14.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: CustomPushButton(
                    height: 42,
                    backgroundColor: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      AddSpecialHolidayDialog.show(
                        context: context,
                        settingsCubit: settingsCubit,
                      );
                    },
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CustomAssetImage(
                            path: AppIcons.add,
                            width: 16,
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'add_holiday'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Divider(height: 1, color: colors.borderSubtle),

                // ─── Holidays List / Table ──────────────────────────────────
                if (holidays.isEmpty)
                  _buildEmptyState(context, colors)
                else if (isMobile)
                  _buildMobileCards(context, holidays, colors)
                else
                  _buildDesktopTable(context, holidays, colors),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceLevel1,
              shape: BoxShape.circle,
            ),
            child: CustomAssetImage(
              path: AppIcons.calendar,
              width: 32,
              height: 32,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'no_holidays_found'.tr(),
            style: CustomAppFontStyle.medium16.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    List<SpecialHolidayModel> holidays,
    dynamic colors,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Table Header
            Container(
              color: colors.tableHeaderBackground,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'holiday_name'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'start_date'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'end_date'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'duration_days'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 60), // Actions
                ],
              ),
            ),
            Divider(height: 1, color: colors.borderSubtle),

            // Table Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: holidays.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: colors.borderSubtle),
              itemBuilder: (context, index) {
                final holiday = holidays[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          holiday.name ?? '-',
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          holiday.startDate?.toCustomFormat() ?? '-',
                          style: CustomAppFontStyle.regular14.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          holiday.endDate?.toCustomFormat() ?? '-',
                          style: CustomAppFontStyle.regular14.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${holiday.durationDays} ${'days_label'.tr()}',
                              style: CustomAppFontStyle.semiBold12.copyWith(
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: IconButton(
                          onPressed: () {
                            DeleteHolidayDialog.show(
                              context: context,
                              holiday: holiday,
                              settingsCubit: settingsCubit,
                            );
                          },
                          icon: const CustomAssetImage(
                            path: AppIcons.delete,
                            width: 18,
                            height: 18,
                            color: AppColors.error,
                          ),
                          tooltip: 'delete_holiday'.tr(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCards(
    BuildContext context,
    List<SpecialHolidayModel> holidays,
    dynamic colors,
  ) {
    return Column(
      children: holidays.map((holiday) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      holiday.name ?? '-',
                      style: CustomAppFontStyle.semiBold16.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      DeleteHolidayDialog.show(
                        context: context,
                        holiday: holiday,
                        settingsCubit: settingsCubit,
                      );
                    },
                    icon: const CustomAssetImage(
                      path: AppIcons.delete,
                      width: 18,
                      height: 18,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CustomAssetImage(
                    path: AppIcons.calendar,
                    width: 16,
                    height: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${holiday.startDate?.toCustomFormat() ?? '-'}  ←  ${holiday.endDate?.toCustomFormat() ?? '-'}',
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${holiday.durationDays} ${'days_label'.tr()}',
                  style: CustomAppFontStyle.semiBold12.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
