import 'package:flutter/cupertino.dart';

class PageSlideTransition extends PageRouteBuilder {
  final Widget page;
  final AxisDirection direction;
  final Duration duration;
  final Curve curve;

  PageSlideTransition({
    required this.page,
    required this.direction,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (context, animation, secondaryAnimation) => page,
        );

  @override
  Widget buildTransitions(context, animation, secondaryAnimation, child) {
    return SlideTransition(
      position: Tween<Offset>(begin: getBeginOffset(), end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: curve),
      ),
      child: child,
    );
  }

  Offset getBeginOffset() {
    switch (direction) {
      case AxisDirection.up:
        return const Offset(0, 1);
      case AxisDirection.down:
        return const Offset(0, -1);
      case AxisDirection.right:
        return const Offset(-1, 0);
      case AxisDirection.left:
        return const Offset(1, 0);
    }
  }
}
