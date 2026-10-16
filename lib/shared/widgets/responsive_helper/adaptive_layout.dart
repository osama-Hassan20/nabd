import 'package:flutter/material.dart';

import 'screen_width_breakpoints.dart';

class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    super.key,
    required this.mobileLayout,
    required this.tabletLayout,
    required this.desktopLayout,
  });

  final WidgetBuilder mobileLayout, tabletLayout, desktopLayout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= ScreenWidthBreakpoints.tablet) {
          return mobileLayout(context);
        } else if (constraints.maxWidth < ScreenWidthBreakpoints.desktop) {
          return tabletLayout(context);
        } else {
          return desktopLayout(context);
        }
      },
    );
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width <= ScreenWidthBreakpoints.tablet;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width < ScreenWidthBreakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= ScreenWidthBreakpoints.desktop;
  }

  static double getResponsiveValue({
    required BuildContext context,
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= ScreenWidthBreakpoints.tablet) {
      return mobile;
    } else if (width < ScreenWidthBreakpoints.desktop) {
      return tablet;
    } else {
      return desktop;
    }
  }
}

class AdaptivePadding extends StatelessWidget {
  const AdaptivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.mobileEdgeInsets,
    this.tabletEdgeInsets,
    this.desktopEdgeInsets,
  });

  final Widget child;
  final double? mobilePadding;
  final double? tabletPadding;
  final double? desktopPadding;
  final EdgeInsets? mobileEdgeInsets;
  final EdgeInsets? tabletEdgeInsets;
  final EdgeInsets? desktopEdgeInsets;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= ScreenWidthBreakpoints.tablet) {
          return Padding(
            padding:
                mobileEdgeInsets ??
                EdgeInsets.symmetric(
                  horizontal: mobilePadding ?? 16,
                  vertical: 16,
                ),
            child: child,
          );
        } else if (constraints.maxWidth < ScreenWidthBreakpoints.desktop) {
          return Padding(
            padding:
                tabletEdgeInsets ??
                EdgeInsets.symmetric(
                  horizontal: tabletPadding ?? 16,
                  vertical: 16,
                ),
            child: child,
          );
        } else {
          return Padding(
            padding:
                desktopEdgeInsets ??
                EdgeInsets.symmetric(
                  horizontal: desktopPadding ?? 16,
                  vertical: 16,
                ),
            child: child,
          );
        }
      },
    );
  }
}
