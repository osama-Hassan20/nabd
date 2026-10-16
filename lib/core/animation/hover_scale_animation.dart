import 'package:flutter/material.dart';

class HoverScaleAnimation extends StatefulWidget {
  final Widget child;
  final double hoverScale;
  final double tapScale;
  final Duration duration;

  const HoverScaleAnimation({
    super.key,
    required this.child,
    this.hoverScale = 1.1,
    this.tapScale = 0.95,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<HoverScaleAnimation> createState() => _HoverScaleAnimationState();
}

class _HoverScaleAnimationState extends State<HoverScaleAnimation> {
  bool _isHovered = false;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isTapped
        ? widget.tapScale
        : (_isHovered ? widget.hoverScale : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _isTapped = true),
        onPointerUp: (_) => setState(() => _isTapped = false),
        onPointerCancel: (_) => setState(() => _isTapped = false),
        child: AnimatedScale(
          scale: scale,
          duration: widget.duration,
          curve: Curves.easeInOut,
          child: widget.child,
        ),
      ),
    );
  }
}
