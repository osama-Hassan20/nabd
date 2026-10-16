import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_gradient.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/shared/widgets/custom_shimmer_container.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, this.title, this.subTitle, this.iconPath});
  final String? title;
  final String? subTitle;
  final String? iconPath;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppGradient.greenGradientToWhite,
      ),
      child: CustomListTile(
        backgroundColor: Colors.transparent,
        border: Border.all(color: Colors.transparent),
        padding: const EdgeInsets.all(12),
        horizontalSpacing: 8,
        leadingIconInstead: CircleAvatar(
          backgroundColor: AppColors.white.withValues(alpha: 0.2),
          radius: 32,
          child: CustomAssetImage(
            width: 32,
            height: 32,
            path: iconPath!,
            color: AppColors.white,
          ),
        ),
        title: title,
        titleTextStyle: CustomAppFontStyle.bold18.copyWith(
          color: AppColors.white,
        ),
        subtitle: subTitle,
        subTitleStyle: CustomAppFontStyle.regular14.copyWith(
          color: AppColors.white,
        ),
      ),
    );
  }
}

class SummaryCardShimmer extends StatelessWidget {
  const SummaryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.fillDisableColor,
      ),
      child: CustomListTile(
        backgroundColor: Colors.transparent,
        border: Border.all(color: Colors.transparent),
        padding: EdgeInsets.all(12),
        horizontalSpacing: 8,
        leadingIconInstead: CustomShimmerContainer(
          width: 64,
          height: 64,
          borderRadius: 32,
        ),
        titleInstead: CustomShimmerContainer(width: 100, height: 20),
        subTitleInstead: CustomShimmerContainer(width: 60, height: 16),
      ),
    );
  }
}
