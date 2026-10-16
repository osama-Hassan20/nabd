import 'package:flutter/cupertino.dart';

class PageFadeTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;
  final Curve curve;

  PageFadeTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (context, animation, secondaryAnimation) => page,
        );

  @override
  Widget buildTransitions(context, animation, secondaryAnimation, child) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: curve),
      child: child,
    );
  }
}
