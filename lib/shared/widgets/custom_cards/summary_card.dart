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
    this.gradient,
    this.onTap,
    this.isSelected = false,
    this.activeBorderColor,
  });

  final String? title;
  final String? subTitle;
  final String? iconPath;
  final double borderRadius;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? activeBorderColor;

  @override
  Widget build(BuildContext context) {
    final border = isSelected
        ? Border.all(
            color: activeBorderColor ?? AppColors.white,
            width: 2.5,
          )
        : Border.all(color: Colors.white.withValues(alpha: 0.12));

    final effectiveGradient = gradient ?? AppGradient.primaryGradient;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: effectiveGradient,
            border: border,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (activeBorderColor ?? AppColors.primary)
                          .withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // ─── Ambient Bubble 1 (Top-Right: Translucent Glow) ─────────
              Positioned(
                top: -24,
                right: -24,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),

              // ─── Ambient Bubble 2 (Bottom-Left) ──────────────────────────
              Positioned(
                bottom: -36,
                left: -18,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
              ),

              // ─── Selected Check Indicator Badge ─────────────────────────
              if (isSelected)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.darkText,
                    ),
                  ),
                ),

              // ─── Card Foreground Content ─────────────────────────────────
              Center(
                child: CustomListTile(
                  backgroundColor: Colors.transparent,
                  border: Border.all(color: Colors.transparent),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  horizontalSpacing: 10,
                  spacing: 2,
                  leadingIconInstead: CircleAvatar(
                    backgroundColor: AppColors.white.withValues(alpha: 0.2),
                    radius: 23,
                    child: iconPath != null
                        ? CustomAssetImage(
                            width: 24,
                            height: 24,
                            path: iconPath!,
                            color: AppColors.white,
                          )
                        : null,
                  ),
                  title: title,
                  titleTextStyle: CustomAppFontStyle.bold18.copyWith(
                    color: AppColors.white,
                  ),
                  subtitle: subTitle,
                  subTitleStyle: CustomAppFontStyle.regular12.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        horizontalSpacing: 10,
        leadingIconInstead: const CustomShimmerContainer(
          width: 46,
          height: 46,
          borderRadius: 23,
        ),
        titleInstead: const CustomShimmerContainer(width: 80, height: 20),
        subTitleInstead: const CustomShimmerContainer(width: 60, height: 16),
      ),
    );
  }
}
