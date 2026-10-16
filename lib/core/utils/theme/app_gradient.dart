import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGradient {
  static const LinearGradient yellowGradient = LinearGradient(
    colors: [AppColors.yellowF4CA01, AppColors.yellowFFAA00],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  // green gradient
  static const LinearGradient greenGradient = LinearGradient(
    colors: [AppColors.lightGreen96C97C, AppColors.lightGreen35BEAA],
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
  );
  static const LinearGradient greenGradientToWhite = LinearGradient(
    colors: [AppColors.lightGreen96C97C, AppColors.lightGreen35BEAA],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient blackLinearGradient = LinearGradient(
    colors: [AppColors.gray6C6C6C, AppColors.gray334155],
    stops: [0.0, 1.0],

    begin: AlignmentDirectional.topEnd,
    end: AlignmentDirectional.centerStart,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [AppColors.red, AppColors.pink],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
