import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../manager/analytics_cubit.dart';
import '../manager/analytics_state.dart';
import 'shimmers/analytics_chart_shimmer.dart';

class RevenueTrendChartCard extends StatelessWidget {
  const RevenueTrendChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      buildWhen: (prev, current) =>
          prev.trendStatus != current.trendStatus ||
          prev.revenueTrend != current.revenueTrend,
      builder: (context, state) {
        if (state.trendStatus == RequestStatusEnum.loading && state.revenueTrend.isEmpty) {
          return const AnalyticsChartShimmer(height: 340);
        }

        if (state.trendStatus == RequestStatusEnum.failure && state.revenueTrend.isEmpty) {
          return Container(
            height: 200,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.grayE2E8F0),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    state.trendError ?? 'analytics_load_error'.tr(),
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.read<AnalyticsCubit>().loadRevenueTrend(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text('retry'.tr()),
                  ),
                ],
              ),
            ),
          );
        }

        final points = state.revenueTrend;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grayE2E8F0),
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
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 12,
                spacing: 16,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'analytics_revenue_trend_title'.tr(),
                        style: CustomAppFontStyle.bold16.copyWith(
                          color: AppColors.pitchBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'analytics_revenue_trend_subtitle'.tr(),
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _buildLegendIndicator('analytics_total_revenue'.tr(), AppColors.primary),
                      _buildLegendIndicator('analytics_net_profit'.tr(), AppColors.secondary),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 240,
                child: points.isEmpty
                    ? Center(
                        child: Text(
                          'no_data'.tr(),
                          style: CustomAppFontStyle.regular13.copyWith(color: AppColors.gray),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 500000,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: AppColors.grayE2E8F0,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 55,
                                getTitlesWidget: (value, meta) {
                                  if (value <= 0) return const SizedBox.shrink();
                                  final inThousands = (value / 100000).toStringAsFixed(0);
                                  return Text(
                                    '${inThousands}k',
                                    style: CustomAppFontStyle.regular11.copyWith(color: AppColors.gray),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < points.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        points[idx].label ?? '',
                                        style: CustomAppFontStyle.regular11.copyWith(color: AppColors.gray),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (int i = 0; i < points.length; i++)
                                  FlSpot(i.toDouble(), (points[i].revenuePiastres ?? 0).toDouble()),
                              ],
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primary.withValues(alpha: 0.08),
                              ),
                            ),
                            LineChartBarData(
                              spots: [
                                for (int i = 0; i < points.length; i++)
                                  FlSpot(i.toDouble(), (points[i].netProfitPiastres ?? 0).toDouble()),
                              ],
                              isCurved: true,
                              color: AppColors.secondary,
                              barWidth: 2.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.secondary.withValues(alpha: 0.06),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: CustomAppFontStyle.regular12.copyWith(color: AppColors.pitchBlack),
        ),
      ],
    );
  }
}
