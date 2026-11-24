import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';

class AnalyticsGridShimmer extends StatelessWidget {
  const AnalyticsGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final isDark = colors.isDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1000
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 1;

        return Shimmer.fromColors(
          baseColor: isDark ? const Color(0xFF1F1F26) : AppColors.grayE2E8F0,
          highlightColor: isDark ? const Color(0xFF2A2A35) : AppColors.white,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: 140,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F1F26) : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.borderSubtle),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
