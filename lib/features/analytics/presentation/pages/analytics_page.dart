import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/animation/fade_transition_animation.dart';
import '../../../../core/cubits/session_cubit.dart';
import '../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../data/models/enums/analytics_tab_enum.dart';
import '../manager/analytics_cubit.dart';
import '../manager/analytics_state.dart';
import '../widgets/analytics_filter_bar.dart';
import '../widgets/analytics_metric_grid.dart';
import '../widgets/branch_comparison_chart_card.dart';
import '../widgets/doctor_performance_table_card.dart';
import '../widgets/hourly_traffic_heatmap_card.dart';
import '../widgets/revenue_trend_chart_card.dart';

class AnalyticsPage extends StatelessWidget {
  final AnalyticsCubit? cubit;

  const AnalyticsPage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<AnalyticsCubit>.value(
        value: cubit!,
        child: const _AnalyticsPageView(),
      );
    }
    return BlocProvider<AnalyticsCubit>(
      create: (context) {
        String? branchId;
        try {
          branchId = context.read<SessionCubit>().state.activeBranchId;
        } catch (_) {}
        final newCubit = getIt<AnalyticsCubit>();
        if (branchId != null) {
          newCubit.setBranchId(branchId);
        } else {
          newCubit.loadAllAnalytics();
        }
        return newCubit;
      },
      child: const _AnalyticsPageView(),
    );
  }
}

class _AnalyticsPageView extends StatelessWidget {
  const _AnalyticsPageView();

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return FadeTransitionAnimation(
      duration: const Duration(milliseconds: 300),
      child: Scaffold(
        backgroundColor: colors.scaffoldBackground,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Header
              _buildHeader(context),
              const SizedBox(height: 18),

              // Filter & Navigation Tabs Bar
              const AnalyticsFilterBar(),
              const SizedBox(height: 20),

              // Dynamic Tab Body
              BlocBuilder<AnalyticsCubit, AnalyticsState>(
                buildWhen: (prev, curr) => prev.activeTab != curr.activeTab,
                builder: (context, state) {
                  return _buildTabContent(context, state.activeTab);
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.themeColors;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              Icons.analytics_rounded,
              color: colors.primary,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'analytics_title'.tr(),
                style: CustomAppFontStyle.bold20.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'analytics_subtitle'.tr(),
                style: CustomAppFontStyle.regular13.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context, AnalyticsTabEnum tab) {
    switch (tab) {
      case AnalyticsTabEnum.executive:
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1000;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AnalyticsMetricGrid(),
                const SizedBox(height: 20),
                if (isDesktop)
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: RevenueTrendChartCard()),
                      SizedBox(width: 20),
                      Expanded(flex: 2, child: BranchComparisonChartCard()),
                    ],
                  )
                else
                  const Column(
                    children: [
                      RevenueTrendChartCard(),
                      SizedBox(height: 20),
                      BranchComparisonChartCard(),
                    ],
                  ),
                const SizedBox(height: 20),
                const HourlyTrafficHeatmapCard(),
              ],
            );
          },
        );

      case AnalyticsTabEnum.financial:
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1000;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AnalyticsMetricGrid(),
                const SizedBox(height: 20),
                if (isDesktop)
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: RevenueTrendChartCard()),
                      SizedBox(width: 20),
                      Expanded(flex: 2, child: BranchComparisonChartCard()),
                    ],
                  )
                else
                  const Column(
                    children: [
                      RevenueTrendChartCard(),
                      SizedBox(height: 20),
                      BranchComparisonChartCard(),
                    ],
                  ),
              ],
            );
          },
        );

      case AnalyticsTabEnum.clinical:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnalyticsMetricGrid(),
            SizedBox(height: 20),
            HourlyTrafficHeatmapCard(),
          ],
        );

      case AnalyticsTabEnum.doctors:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DoctorPerformanceTableCard(),
          ],
        );
    }
  }
}
