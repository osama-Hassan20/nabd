import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/custom_stack_selector.dart';
import '../../data/models/enums/analytics_tab_enum.dart';
import '../../data/models/enums/analytics_time_range_enum.dart';
import '../manager/analytics_cubit.dart';
import '../manager/analytics_state.dart';

class AnalyticsFilterBar extends StatefulWidget {
  const AnalyticsFilterBar({super.key});

  @override
  State<AnalyticsFilterBar> createState() => _AnalyticsFilterBarState();
}

class _AnalyticsFilterBarState extends State<AnalyticsFilterBar> {
  late final TextEditingController _timeRangeController;
  late final TextEditingController _branchController;

  static const List<(String?, String)> _branches = [
    (null, 'analytics_all_branches'),
    ('branch_1', 'branch_main'),
    ('branch_2', 'branch_second'),
    ('branch_3', 'branch_third'),
  ];

  @override
  void initState() {
    super.initState();
    _timeRangeController = TextEditingController();
    _branchController = TextEditingController();
  }

  @override
  void dispose() {
    _timeRangeController.dispose();
    _branchController.dispose();
    super.dispose();
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

  String _getBranchLabel(String? branchId) {
    final match = _branches.where((b) => b.$1 == branchId);
    if (match.isNotEmpty) return match.first.$2.tr();
    return 'analytics_all_branches'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      buildWhen: (prev, curr) =>
          prev.activeTab != curr.activeTab ||
          prev.selectedTimeRange != curr.selectedTimeRange ||
          prev.selectedBranchId != curr.selectedBranchId,
      builder: (context, state) {
        _timeRangeController.text = _getTimeRangeTitle(state.selectedTimeRange);
        final colors = context.themeColors;
        _branchController.text = _getBranchLabel(state.selectedBranchId);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderSubtle),
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
                                ? colors.primary
                                : colors.surfaceLevel1,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? colors.primary : colors.borderSubtle,
                            ),
                          ),
                          child: Text(
                            _getTabTitle(tab),
                            style: CustomAppFontStyle.medium14.copyWith(
                              color: isSelected ? colors.textInverse : colors.textPrimary,
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
              Divider(height: 1, color: colors.borderSubtle),
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
                      SizedBox(
                        width: 170,
                        child: CustomStackSelector<AnalyticsTimeRangeEnum>(
                          key: const Key('filter_time_range'),
                          controller: _timeRangeController,
                          hintText: _getTimeRangeTitle(state.selectedTimeRange),
                          list: AnalyticsTimeRangeEnum.values,
                          itemAsString: (range) => _getTimeRangeTitle(range),
                          changeValue: (newRange) async {
                            if (newRange == AnalyticsTimeRangeEnum.custom) {
                              final now = CairoTimeHelper.now();
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(now.year - 2),
                                lastDate: DateTime(now.year + 1),
                                initialDateRange: DateTimeRange(
                                  start: state.customStartDate ??
                                      now.subtract(const Duration(days: 7)),
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

                      // Branch Dropdown
                      SizedBox(
                        width: 170,
                        child: CustomStackSelector<(String?, String)>(
                          key: const Key('filter_branch'),
                          controller: _branchController,
                          hintText: 'analytics_all_branches'.tr(),
                          list: _branches,
                          itemAsString: (b) => b.$2.tr(),
                          changeValue: (newBranch) {
                            context.read<AnalyticsCubit>().setBranchId(newBranch.$1);
                          },
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
                        color: colors.surfaceLevel1,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 18, color: colors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'refresh'.tr(),
                            style: CustomAppFontStyle.medium13.copyWith(color: colors.primary),
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
}
