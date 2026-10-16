import 'package:flutter/material.dart';

class SlideTransitionAnimation extends StatefulWidget {
  const SlideTransitionAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    required this.begin,
    this.end = Offset.zero,
    this.curve = Curves.easeOutCubic,
    this.withFade = true,
    this.repeat = false,
    this.delay,
  });

  final Widget child;
  final Duration duration;
  final Offset begin;
  final Offset end;
  final Curve curve;
  final bool withFade;
  final bool repeat;
  final Duration? delay;

  @override
  State<SlideTransitionAnimation> createState() =>
      _SlideTransitionAnimationState();
}

class _SlideTransitionAnimationState extends State<SlideTransitionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slideAnimation = Tween<Offset>(begin: widget.begin, end: widget.end).animate(curved);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

    if (widget.delay != null) {
      Future.delayed(widget.delay!, () {
        if (!mounted) return;
        if (widget.repeat) {
          _controller.repeat(reverse: true);
        } else {
          _controller.forward();
        }
      });
    } else {
      if (widget.repeat) {
        _controller.repeat(reverse: true);
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.withFade) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(position: _slideAnimation, child: widget.child),
      );
    }
    return SlideTransition(position: _slideAnimation, child: widget.child);
  }
}
