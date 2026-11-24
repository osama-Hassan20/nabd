import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';

class AnalyticsChartShimmer extends StatelessWidget {
  final double height;

  const AnalyticsChartShimmer({super.key, this.height = 320});

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final isDark = colors.isDark;

    return Container(
      height: height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF1F1F26) : AppColors.grayE2E8F0,
        highlightColor: isDark ? const Color(0xFF2A2A35) : AppColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 180,
              height: 18,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A35) : AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 260,
              height: 14,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A35) : AppColors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A35) : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

