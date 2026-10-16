import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/extensions/date_time_extentision.dart';
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

    return BlocBuilder<SettingsCubit, SettingsState>(
      bloc: settingsCubit,
      builder: (context, state) {
        final holidays = state.settings?.specialHolidays ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: CustomContainer(
            padding: const EdgeInsets.all(24),
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
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const CustomAssetImage(
                                  path: AppIcons.calendar,
                                  width: 20,
                                  height: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'special_holidays'.tr(),
                                style: CustomAppFontStyle.semiBold18.copyWith(
                                  color: AppColors.darkText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'special_holidays_desc'.tr(),
                            style: CustomAppFontStyle.regular14.copyWith(
                              color: AppColors.gray7A828E,
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
                    backgroundColor: AppColors.primary,
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
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'add_holiday'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Divider(height: 1, color: AppColors.grayE2E8F0),

                // ─── Holidays List / Table ──────────────────────────────────
                if (holidays.isEmpty)
                  _buildEmptyState()
                else if (isMobile)
                  _buildMobileCards(context, holidays)
                else
                  _buildDesktopTable(context, holidays),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grayf6,
              shape: BoxShape.circle,
            ),
            child: const CustomAssetImage(
              path: AppIcons.calendar,
              width: 32,
              height: 32,
              color: AppColors.gray7A828E,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'no_holidays_found'.tr(),
            style: CustomAppFontStyle.medium16.copyWith(
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    List<SpecialHolidayModel> holidays,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Table Header
            Container(
              color: AppColors.grayf6,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'holiday_name'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: AppColors.gray7A828E,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'start_date'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: AppColors.gray7A828E,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'end_date'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: AppColors.gray7A828E,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'duration_days'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: AppColors.gray7A828E,
                      ),
                    ),
                  ),
                  const SizedBox(width: 60), // Actions
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.grayE2E8F0),

            // Table Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: holidays.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.grayE2E8F0),
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
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          holiday.startDate?.toCustomFormat() ?? '-',
                          style: CustomAppFontStyle.regular14.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          holiday.endDate?.toCustomFormat() ?? '-',
                          style: CustomAppFontStyle.regular14.copyWith(
                            color: AppColors.darkText,
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
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${holiday.durationDays} ${'days_label'.tr()}',
                              style: CustomAppFontStyle.semiBold12.copyWith(
                                color: AppColors.primary,
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
  ) {
    return Column(
      children: holidays.map((holiday) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grayE2E8F0),
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
                        color: AppColors.darkText,
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
                  const CustomAssetImage(
                    path: AppIcons.calendar,
                    width: 16,
                    height: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${holiday.startDate?.toCustomFormat() ?? '-'}  ←  ${holiday.endDate?.toCustomFormat() ?? '-'}',
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: AppColors.gray7A828E,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${holiday.durationDays} ${'days_label'.tr()}',
                  style: CustomAppFontStyle.semiBold12.copyWith(
                    color: AppColors.primary,
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
