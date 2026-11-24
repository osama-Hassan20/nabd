import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../cashier/domain/helpers/money.dart';
import '../manager/analytics_cubit.dart';
import '../manager/analytics_state.dart';
import 'shimmers/analytics_chart_shimmer.dart';

class BranchComparisonChartCard extends StatelessWidget {
  const BranchComparisonChartCard({super.key});

  static const List<Color> _branchColorsLight = [
    AppColors.primary,
    Color(0xFF0284C7),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
  ];

  static const List<Color> _branchColorsDark = [
    Color(0xFFFF6B50),
    Color(0xFF38BDF8),
    Color(0xFFFBBF24),
    Color(0xFFA78BFA),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      buildWhen: (prev, current) =>
          prev.branchesStatus != current.branchesStatus ||
          prev.branchComparisons != current.branchComparisons,
      builder: (context, state) {
        final colors = context.themeColors;
        final branchColors = colors.isDark ? _branchColorsDark : _branchColorsLight;

        if (state.branchesStatus == RequestStatusEnum.loading && state.branchComparisons.isEmpty) {
          return const AnalyticsChartShimmer(height: 340);
        }

        if (state.branchesStatus == RequestStatusEnum.failure && state.branchComparisons.isEmpty) {
          return Container(
            height: 200,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    state.branchesError ?? 'analytics_load_error'.tr(),
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.read<AnalyticsCubit>().loadBranchComparison(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text('retry'.tr()),
                  ),
                ],
              ),
            ),
          );
        }

        final branches = state.branchComparisons;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'analytics_branch_comparison_title'.tr(),
                style: CustomAppFontStyle.bold16.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'analytics_branch_comparison_subtitle'.tr(),
                style: CustomAppFontStyle.regular12.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: branches.isEmpty
                    ? Center(
                        child: Text(
                          'no_data'.tr(),
                          style: CustomAppFontStyle.regular13.copyWith(color: colors.textSecondary),
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < branches.length) {
                                    final name = branches[idx].branchName ?? '';
                                    final short = name.contains('-') ? name.split('-').last.trim() : name;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Text(
                                        short,
                                        style: CustomAppFontStyle.bold11.copyWith(color: colors.textPrimary),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (int i = 0; i < branches.length; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: (branches[i].totalRevenuePiastres ?? 0).toDouble(),
                                    color: branchColors[i % branchColors.length],
                                    width: 32,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Divider(color: colors.borderSubtle, height: 1),
              const SizedBox(height: 16),
              // Branch breakdown legends
              for (int i = 0; i < branches.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: branchColors[i % branchColors.length],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            branches[i].branchName ?? '',
                            style: CustomAppFontStyle.medium13.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            '${branches[i].visitsCount ?? 0} ${'analytics_completed_visits'.tr()} • ',
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          Text(
                            Money.fromPiastres(branches[i].totalRevenuePiastres ?? 0).formatEgp(),
                            style: CustomAppFontStyle.bold13.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: colors.isDark ? colors.surfaceLevel2 : colors.surfaceLevel1,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Text(
                              '${branches[i].shareOfTotalRevenuePercent?.toStringAsFixed(0)}%',
                              style: CustomAppFontStyle.bold11.copyWith(
                                color: branchColors[i % branchColors.length],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
