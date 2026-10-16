import 'package:cached_network_image/cached_network_image.dart';
import 'package:purexo/core/utils/extensions/theme_mode_extensions.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:flutter/material.dart';

import '../../core/api/end_points.dart';
import '../../core/utils/theme/app_colors.dart';
import '../../core/utils/theme/app_images.dart';

class CustomCachedImage extends StatelessWidget {
  const CustomCachedImage({
    super.key,
    this.width,
    this.height,
    required this.imagePath,
    this.fit,
    this.fromApi = true,
    this.colorTint,
    this.blendMode,
    this.isFromSlider = false,
  });

  final double? width, height;
  final String imagePath;
  final BoxFit? fit;
  final Color? colorTint;
  final BlendMode? blendMode;
  final bool fromApi;
  final bool isFromSlider;

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.black.withValues(alpha: 0.1),
        ),
        child: Center(
          child: CustomAssetImage(
            fit: BoxFit.fill,
            width: width,
            height: height,
            path: AppImages.errorImage,
          ),
        ),
      );
    }

    final String cleanPath = imagePath.startsWith('/')
        ? imagePath.substring(1)
        : imagePath;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        colorTint ?? Colors.transparent,
        blendMode ?? BlendMode.dst,
      ),
      child: CachedNetworkImage(
        width: width,
        height: height,

        fit: fit ?? BoxFit.cover,
        imageUrl: fromApi ? '${EndPoints.baseImageUrl}/$cleanPath' : cleanPath,
        fadeInDuration: const Duration(milliseconds: 300),
        errorListener: (value) {},
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.gray334155.withValues(alpha: 0.25),
          ),
          child: Center(
            child: CustomAssetImage(
              fit: BoxFit.cover,
              width: width,
              height: height,
              path: AppImages.emptyImage,
            ),
          ),
        ),
        progressIndicatorBuilder: (context, url, progress) {
          bool isDark = context.isDarkMode;
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.black.withValues(alpha: 0.1),
            ),
            child: SizedBox(
              width: 30,
              height: 30,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: CircularProgressIndicator(
                  value: progress.progress,
                  strokeWidth: 1.25,
                  color: isDark ? AppColors.white : AppColors.black,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
