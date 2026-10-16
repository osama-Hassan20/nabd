import 'package:flutter/material.dart';

class ScaleTransitionAnimation extends StatefulWidget {
  const ScaleTransitionAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.repeat = false,
    this.begin = 0.92,
    this.end = 1.0,
    this.curve = Curves.easeOutCubic,
    this.withFade = true,
    this.delay,
  });

  final Widget child;
  final Duration duration;
  final bool repeat;
  final double begin;
  final double end;
  final Curve curve;
  final bool withFade;
  final Duration? delay;

  @override
  State<ScaleTransitionAnimation> createState() =>
      _ScaleTransitionAnimationState();
}

class _ScaleTransitionAnimationState extends State<ScaleTransitionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _scaleAnimation = Tween<double>(begin: widget.begin, end: widget.end).animate(curved);
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
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      );
    }
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}
