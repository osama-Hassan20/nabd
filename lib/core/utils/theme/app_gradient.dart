import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGradient {
  // ─── Hero Primary Gradients (Terracotta Coral) ──────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE0583E), Color(0xFFE86B52)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primarySoftGradient = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Secondary Gradients (Eucalyptus Sage) ──────────────────────────────
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [AppColors.secondary, Color(0xFF388062)],
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
  );

  static const LinearGradient secondarySoftGradient = LinearGradient(
    colors: [AppColors.secondaryLight, AppColors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Preserved & Mapped UI Gradients ─────────────────────────────────────
  /// Active UI elements, tabs, switchers & sidebar highlights
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFFE0583E), Color(0xFFE86B52)],
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
  );

  /// Soft card gradient
  static const LinearGradient greenGradientToWhite = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Obsidian / Charcoal Linear Gradient ─────────────────────────────────
  static const LinearGradient blackLinearGradient = LinearGradient(
    colors: [Color(0xFF1E1E22), Color(0xFF111111)],
    stops: [0.0, 1.0],
    begin: AlignmentDirectional.topEnd,
    end: AlignmentDirectional.centerStart,
  );

  // ─── Active Checkboxes & Vibrant Accent Gradient ─────────────────────────
  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFE0583E), Color(0xFFE55338)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Warning & Waiting Queue Gradient (Warm Amber) ────────────────────────
  static const LinearGradient yellowGradient = LinearGradient(
    colors: [Color(0xFFE89A24), Color(0xFFF2AA3D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
