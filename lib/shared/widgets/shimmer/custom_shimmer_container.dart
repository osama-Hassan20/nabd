import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CustomShimmerContainer extends StatelessWidget {
  const CustomShimmerContainer({
    super.key,
    required this.height,
    required this.width,
    this.baseColor,
    this.highlightColor,
    this.borderRadius = 12,
  });

  final double height, width, borderRadius;
  final Color? baseColor, highlightColor;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    return Shimmer.fromColors(
      baseColor: baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[100]!),
      highlightColor:
          highlightColor ?? (isDark ? Colors.grey[700]! : Colors.grey[200]!),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

