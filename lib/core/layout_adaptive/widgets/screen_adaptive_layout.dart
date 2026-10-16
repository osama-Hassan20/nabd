import 'package:purexo/shared/widgets/responsive_helper/screen_width_breakpoints.dart';
import 'package:flutter/material.dart';

/// Adaptive layout that uses MediaQuery (screen width) instead of LayoutBuilder (constraint width).
/// Use this widget when placed inside Row, ListView, or other unbounded widgets where
/// LayoutBuilder would receive incorrect constraints (e.g., double.infinity).
///
/// For widget-based constraints, use [AdaptiveLayout] instead.
class ScreenAdaptiveLayout extends StatelessWidget {
  const ScreenAdaptiveLayout({
    super.key,
    required this.mobileLayout,
    required this.tabletLayout,
    required this.desktopLayout,
  });

  final WidgetBuilder mobileLayout, tabletLayout, desktopLayout;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (screenWidth <= ScreenWidthBreakpoints.tablet) {
      return mobileLayout(context);
    } else if (screenWidth < ScreenWidthBreakpoints.desktop) {
      return tabletLayout(context);
    } else {
      return desktopLayout(context);
    }
  }
}

