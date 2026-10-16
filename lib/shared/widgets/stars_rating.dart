import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/utils/theme/app_icons.dart';

class StarRating extends StatelessWidget {
  final num rating;
  final double iconSize;
  final int starCount;

  final MainAxisAlignment alignment;

  const StarRating({
    super.key,
    required this.rating,
    this.iconSize = 16,
    this.starCount = 5,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar =
        (rating - fullStars) >= 0.25 && (rating - fullStars) < 0.75;
    int emptyStars = starCount - fullStars - (hasHalfStar ? 1 : 0);

    for (int i = 0; i < fullStars; i++) {
      stars.add(
        CustomAssetImage(
          path: AppIcons.fullStar,
          width: iconSize,
          height: iconSize,
          color: AppColors.yellowFFAA00,
        ),
      );
    }
    if (hasHalfStar) {
      stars.add(
        CustomAssetImage(
          path: AppIcons.halfStar,
          width: iconSize,
          height: iconSize,
          color: AppColors.yellowFFAA00,
        ),
      );
    }
    for (int i = 0; i < emptyStars; i++) {
      stars.add(
        HugeIcon(
          icon: HugeIcons.strokeRoundedStar,
          size: iconSize,
          color: AppColors.grayBorder,
        ),
      );
    }

    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: stars,
    );
  }
}
