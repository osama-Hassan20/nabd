import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../manager/analytics_cubit.dart';
import '../manager/analytics_state.dart';
import 'shimmers/analytics_chart_shimmer.dart';

class HourlyTrafficHeatmapCard extends StatelessWidget {
  const HourlyTrafficHeatmapCard({super.key});

  Color _getLevelColor(String? level, bool isDark) {
    switch (level) {
      case 'peak':
        return isDark ? const Color(0xFFF87171) : AppColors.error;
      case 'high':
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case 'medium':
        return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
      case 'low':
      default:
        return isDark ? const Color(0xFF34D399) : AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      buildWhen: (prev, current) =>
          prev.trafficStatus != current.trafficStatus ||
          prev.hourlyTraffic != current.hourlyTraffic,
      builder: (context, state) {
        final colors = context.themeColors;

        if (state.trafficStatus == RequestStatusEnum.loading && state.hourlyTraffic.isEmpty) {
          return const AnalyticsChartShimmer(height: 280);
        }

        if (state.trafficStatus == RequestStatusEnum.failure && state.hourlyTraffic.isEmpty) {
          return Container(
            height: 180,
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
                    state.trafficError ?? 'analytics_load_error'.tr(),
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.read<AnalyticsCubit>().loadHourlyTraffic(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text('retry'.tr()),
                  ),
                ],
              ),
            ),
          );
        }

        final traffic = state.hourlyTraffic;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'analytics_peak_hours_title'.tr(),
                          style: CustomAppFontStyle.bold16.copyWith(color: colors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'analytics_peak_hours_subtitle'.tr(),
                          style: CustomAppFontStyle.regular12.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (traffic.isEmpty)
                Center(
                  child: Text(
                    'no_data'.tr(),
                    style: CustomAppFontStyle.regular13.copyWith(color: colors.textSecondary),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    return Wrap(
                      spacing: isMobile ? 8 : 12,
                      runSpacing: 12,
                      children: [
                        for (final item in traffic)
                          Builder(
                            builder: (context) {
                              final levelColor = _getLevelColor(item.occupancyLevel, colors.isDark);
                              return Container(
                                width: isMobile ? 70 : 85,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: levelColor.withValues(alpha: colors.isDark ? 0.14 : 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: levelColor.withValues(alpha: colors.isDark ? 0.35 : 0.25),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${item.hour?.toString().padLeft(2, '0')}:00',
                                      style: CustomAppFontStyle.bold12.copyWith(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: levelColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${item.visitsCount ?? 0}',
                                        style: TextStyle(
                                          color: colors.isDark ? const Color(0xFF0F0F12) : Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

