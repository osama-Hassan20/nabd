import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../cashier/domain/helpers/money.dart';
import '../manager/analytics_cubit.dart';
import '../manager/analytics_state.dart';
import 'analytics_metric_card.dart' hide AppColors, SizedBox;
import 'shimmers/analytics_grid_shimmer.dart';

class AnalyticsMetricGrid extends StatelessWidget {
  const AnalyticsMetricGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      buildWhen: (prev, current) =>
          prev.summaryStatus != current.summaryStatus ||
          prev.summary != current.summary,
      builder: (context, state) {
        if (state.summaryStatus == RequestStatusEnum.loading && state.summary == null) {
          return const AnalyticsGridShimmer();
        }

        if (state.summaryStatus == RequestStatusEnum.failure && state.summary == null) {
          final colors = context.themeColors;
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.summaryError ?? 'analytics_load_error'.tr(),
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.read<AnalyticsCubit>().loadSummary(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text('retry'.tr()),
                ),
              ],
            ),
          );
        }

        final summary = state.summary;

        final revenueText = summary?.totalRevenuePiastres != null
            ? Money.fromPiastres(summary!.totalRevenuePiastres!).formatEgp()
            : '—';

        final netProfitText = summary?.netProfitPiastres != null
            ? Money.fromPiastres(summary!.netProfitPiastres!).formatEgp()
            : '—';

        final debtsText = summary?.outstandingDebtsPiastres != null
            ? Money.fromPiastres(summary!.outstandingDebtsPiastres!).formatEgp()
            : '—';

        final visitsText = summary?.totalVisitsCount != null
            ? '${summary!.totalVisitsCount}'
            : '0';

        final waitTimeText = summary?.averageWaitTimeMinutes != null
            ? '${summary!.averageWaitTimeMinutes} ${'minutes_short'.tr()}'
            : '—';

        final returnRateText = summary?.patientReturnRatePercent != null
            ? '${summary!.patientReturnRatePercent!.toStringAsFixed(1)}%'
            : '0%';

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1100
                ? 3
                : constraints.maxWidth > 650
                    ? 2
                    : 1;

            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisExtent: 165,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              children: [
                AnalyticsMetricCard(
                  key: const Key('card_total_revenue'),
                  title: 'analytics_total_revenue'.tr(),
                  value: revenueText,
                  subtitle: summary?.revenueGrowthRatePercent != null
                      ? '+${summary!.revenueGrowthRatePercent}% ${'analytics_vs_last_period'.tr()}'
                      : null,
                  isPositiveTrend: true,
                  icon: Icons.account_balance_wallet_outlined,
                  accentColor: AppColors.primary,
                ),
                AnalyticsMetricCard(
                  key: const Key('card_net_profit'),
                  title: 'analytics_net_profit'.tr(),
                  value: netProfitText,
                  subtitle: 'analytics_estimated_profit'.tr(),
                  isPositiveTrend: true,
                  icon: Icons.monetization_on_outlined,
                  accentColor: AppColors.secondary,
                ),
                AnalyticsMetricCard(
                  key: const Key('card_total_visits'),
                  title: 'analytics_total_visits'.tr(),
                  value: visitsText,
                  subtitle: '${summary?.completedVisitsCount ?? 0} ${'analytics_completed_visits'.tr()}',
                  isPositiveTrend: true,
                  icon: Icons.people_outline,
                  accentColor: const Color(0xFF0284C7),
                ),
                AnalyticsMetricCard(
                  key: const Key('card_avg_wait_time'),
                  title: 'analytics_avg_wait_time'.tr(),
                  value: waitTimeText,
                  subtitle: 'analytics_patient_punctuality'.tr(),
                  icon: Icons.timer_outlined,
                  accentColor: const Color(0xFFD97706),
                ),
                AnalyticsMetricCard(
                  key: const Key('card_return_rate'),
                  title: 'analytics_patient_return_rate'.tr(),
                  value: returnRateText,
                  subtitle: 'analytics_retention_rate'.tr(),
                  isPositiveTrend: true,
                  icon: Icons.autorenew_outlined,
                  accentColor: const Color(0xFF7C3AED),
                ),
                AnalyticsMetricCard(
                  key: const Key('card_outstanding_debts'),
                  title: 'analytics_outstanding_debts'.tr(),
                  value: debtsText,
                  subtitle: 'analytics_uncollected_balance'.tr(),
                  isPositiveTrend: false,
                  icon: Icons.assignment_late_outlined,
                  accentColor: AppColors.error,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
