import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'package:eyadty/shared/widgets/shimmer/custom_shimmer_container.dart';

class BookingDetailsShimmer extends StatelessWidget {
  const BookingDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AdaptiveLayout.getResponsiveValue(
      context: context,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 24.0,
    );
    final isDesktop = AdaptiveLayout.isDesktop(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Bar Shimmer
          _buildTopBarShimmer(),
          const SizedBox(height: 20),

          // Main Content Shimmer
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column (60%)
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildCardShimmer(height: 150),
                      const SizedBox(height: 16),
                      _buildCardShimmer(height: 160),
                      const SizedBox(height: 16),
                      _buildCardShimmer(height: 130),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right Column (40%)
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildCardShimmer(height: 150),
                      const SizedBox(height: 16),
                      _buildCardShimmer(height: 140),
                      const SizedBox(height: 16),
                      _buildCardShimmer(height: 120),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildCardShimmer(height: 150),
                const SizedBox(height: 16),
                _buildCardShimmer(height: 160),
                const SizedBox(height: 16),
                _buildCardShimmer(height: 150),
                const SizedBox(height: 16),
                _buildCardShimmer(height: 140),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTopBarShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Row(
        children: [
          const CustomShimmerContainer(height: 38, width: 38, borderRadius: 8),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomShimmerContainer(height: 20, width: 140, borderRadius: 4),
              SizedBox(height: 6),
              CustomShimmerContainer(height: 14, width: 80, borderRadius: 4),
            ],
          ),
          const Spacer(),
          const CustomShimmerContainer(height: 32, width: 90, borderRadius: 6),
          const SizedBox(width: 10),
          const CustomShimmerContainer(height: 32, width: 90, borderRadius: 6),
        ],
      ),
    );
  }

  Widget _buildCardShimmer({required double height}) {
    return Container(
      height: height,
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
            children: [
              const CustomShimmerContainer(
                height: 24,
                width: 24,
                borderRadius: 6,
              ),
              const SizedBox(width: 10),
              const CustomShimmerContainer(
                height: 18,
                width: 120,
                borderRadius: 4,
              ),
              const Spacer(),
              const CustomShimmerContainer(
                height: 18,
                width: 60,
                borderRadius: 4,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const CustomShimmerContainer(
            height: 14,
            width: double.infinity,
            borderRadius: 4,
          ),
          const SizedBox(height: 10),
          const CustomShimmerContainer(
            height: 14,
            width: 200,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}
