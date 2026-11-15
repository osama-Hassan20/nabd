import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../data/models/enums/analytics_tab_enum.dart';
import '../../data/models/enums/analytics_time_range_enum.dart';
import '../manager/analytics_cubit.dart';
import '../manager/analytics_state.dart';

class AnalyticsFilterBar extends StatelessWidget {
  const AnalyticsFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      buildWhen: (prev, curr) =>
          prev.activeTab != curr.activeTab ||
          prev.selectedTimeRange != curr.selectedTimeRange ||
          prev.selectedBranchId != curr.selectedBranchId,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grayE2E8F0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Navigation Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AnalyticsTabEnum.values.map((tab) {
                    final isSelected = state.activeTab == tab;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: InkWell(
                        key: Key('tab_${tab.name}'),
                        onTap: () => context.read<AnalyticsCubit>().setActiveTab(tab),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.grayE2E8F0,
                            ),
                          ),
                          child: Text(
                            _getTabTitle(tab),
                            style: CustomAppFontStyle.medium14.copyWith(
                              color: isSelected ? AppColors.white : AppColors.darkText,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 14),

              // 2. Control Row: Time Range, Branch Selector, and Refresh Button
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  // Time Range & Branch Controls
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Time Range Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.grayE2E8F0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<AnalyticsTimeRangeEnum>(
                            key: const Key('filter_time_range'),
                            value: state.selectedTimeRange,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.gray),
                            style: CustomAppFontStyle.regular13.copyWith(color: AppColors.darkText),
                            items: AnalyticsTimeRangeEnum.values.map((range) {
                              return DropdownMenuItem<AnalyticsTimeRangeEnum>(
                                value: range,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.gray),
                                    const SizedBox(width: 8),
                                    Text(_getTimeRangeTitle(range)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newRange) async {
                              if (newRange == null) return;
                              if (newRange == AnalyticsTimeRangeEnum.custom) {
                                final now = DateTime.now();
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(now.year - 2),
                                  lastDate: DateTime(now.year + 1),
                                  initialDateRange: DateTimeRange(
                                    start: state.customStartDate ?? now.subtract(const Duration(days: 7)),
                                    end: state.customEndDate ?? now,
                                  ),
                                );
                                if (picked != null && context.mounted) {
                                  context.read<AnalyticsCubit>().setTimeRange(
                                        newRange,
                                        customStart: picked.start,
                                        customEnd: picked.end,
                                      );
                                }
                              } else {
                                context.read<AnalyticsCubit>().setTimeRange(newRange);
                              }
                            },
                          ),
                        ),
                      ),

                      // Branch Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.grayE2E8F0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            key: const Key('filter_branch'),
                            value: state.selectedBranchId,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.gray),
                            style: CustomAppFontStyle.regular13.copyWith(color: AppColors.darkText),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.apartment_rounded, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text('analytics_all_branches'.tr()),
                                  ],
                                ),
                              ),
                              DropdownMenuItem<String?>(
                                value: 'branch_1',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.gray),
                                    const SizedBox(width: 8),
                                    Text('branch_main'.tr()),
                                  ],
                                ),
                              ),
                              DropdownMenuItem<String?>(
                                value: 'branch_2',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.gray),
                                    const SizedBox(width: 8),
                                    Text('branch_second'.tr()),
                                  ],
                                ),
                              ),
                              DropdownMenuItem<String?>(
                                value: 'branch_3',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.gray),
                                    const SizedBox(width: 8),
                                    Text('branch_third'.tr()),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (newBranch) {
                              context.read<AnalyticsCubit>().setBranchId(newBranch);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Refresh Button
                  InkWell(
                    key: const Key('btn_refresh_analytics'),
                    onTap: () => context.read<AnalyticsCubit>().loadAllAnalytics(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.grayE2E8F0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'refresh'.tr(),
                            style: CustomAppFontStyle.medium13.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTabTitle(AnalyticsTabEnum tab) {
    switch (tab) {
      case AnalyticsTabEnum.executive:
        return 'analytics_tab_executive'.tr();
      case AnalyticsTabEnum.financial:
        return 'analytics_tab_financial'.tr();
      case AnalyticsTabEnum.clinical:
        return 'analytics_tab_clinical'.tr();
      case AnalyticsTabEnum.doctors:
        return 'analytics_tab_doctors'.tr();
    }
  }

  String _getTimeRangeTitle(AnalyticsTimeRangeEnum range) {
    switch (range) {
      case AnalyticsTimeRangeEnum.today:
        return 'analytics_time_today'.tr();
      case AnalyticsTimeRangeEnum.thisWeek:
        return 'analytics_time_this_week'.tr();
      case AnalyticsTimeRangeEnum.thisMonth:
        return 'analytics_time_this_month'.tr();
      case AnalyticsTimeRangeEnum.lastMonth:
        return 'analytics_time_last_month'.tr();
      case AnalyticsTimeRangeEnum.custom:
        return 'analytics_time_custom'.tr();
    }
  }
}
