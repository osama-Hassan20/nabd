import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_gradient.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_list_tile.dart';
import 'package:eyadty/shared/widgets/custom_shimmer_container.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    this.title,
    this.subTitle,
    this.iconPath,
    this.borderRadius = 16,
  });

  final String? title;
  final String? subTitle;
  final String? iconPath;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: AppGradient.blackLinearGradient,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Stack(
        children: [
          // ─── Ambient Bubble 1 (Top-Right: Translucent White Glow) ────────
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // ─── Ambient Bubble 2 (Bottom-Left: Terracotta Ambient Glow) ──────
          Positioned(
            bottom: -36,
            left: -18,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
            ),
          ),

          // ─── Ambient Bubble 3 (Soft Floating Accent) ─────────────────────
          Positioned(
            top: 14,
            right: 50,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.02),
              ),
            ),
          ),

          // ─── Card Foreground Content ──────────────────────────────────────
          Center(
            child: CustomListTile(
              backgroundColor: Colors.transparent,
              border: Border.all(color: Colors.transparent),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              horizontalSpacing: 10,
              leadingIconInstead: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                radius: 30,
                child: iconPath != null
                    ? CustomAssetImage(
                        width: 30,
                        height: 30,
                        path: iconPath!,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              title: title,
              titleTextStyle: CustomAppFontStyle.bold18.copyWith(
                color: AppColors.primaryLight,
              ),
              subtitle: subTitle,
              subTitleStyle: CustomAppFontStyle.regular14.copyWith(
                color: AppColors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCardShimmer extends StatelessWidget {
  const SummaryCardShimmer({super.key, this.borderRadius = 16});

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: AppColors.fillDisableColor,
      ),
      child: CustomListTile(
        backgroundColor: Colors.transparent,
        border: Border.all(color: Colors.transparent),
        padding: EdgeInsets.all(12),
        horizontalSpacing: 8,
        leadingIconInstead: CustomShimmerContainer(
          width: 60,
          height: 60,
          borderRadius: 30,
        ),
        titleInstead: CustomShimmerContainer(width: 100, height: 20),
        subTitleInstead: CustomShimmerContainer(width: 60, height: 16),
      ),
    );
  }
}
