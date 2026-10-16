import 'dart:math';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:flutter/material.dart';

class CustomCenterLoadingWidget extends StatefulWidget {
  const CustomCenterLoadingWidget({
    super.key,
    this.size = 100.0,
    this.animationPath,
  });
  final double size;
  final String? animationPath;

  @override
  State<CustomCenterLoadingWidget> createState() =>
      _CustomCenterLoadingWidgetState();
}

class _CustomCenterLoadingWidgetState extends State<CustomCenterLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double pulse = sin(_controller.value * pi);
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow
              Container(
                width: widget.size * 0.8,
                height: widget.size * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightGreen35BEAA.withValues(
                        alpha: 0.15 * pulse,
                      ),
                      blurRadius: 30,
                      spreadRadius: 10 * pulse,
                    ),
                  ],
                ),
              ),
              // Main Ring (Clockwise)
              Transform.rotate(
                angle: _controller.value * 2 * pi,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _RingPainter(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.lightGreen96C97C,
                        AppColors.lightGreen35BEAA,
                      ],
                    ),
                    strokeWidth: widget.size * 0.06,
                    arcLength: pi * 1.6,
                  ),
                ),
              ),
              // Secondary Ring (Counter-clockwise)
              Transform.rotate(
                angle: -_controller.value * 2 * pi * 1.5,
                child: CustomPaint(
                  size: Size(widget.size * 0.75, widget.size * 0.75),
                  painter: _RingPainter(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.lightGreen35BEAA.withValues(alpha: 0.2),
                        AppColors.lightGreen35BEAA.withValues(alpha: 0.6),
                      ],
                    ),
                    strokeWidth: widget.size * 0.04,
                    arcLength: pi * 0.8,
                  ),
                ),
              ),
              // Center Logo with Pulse
              Transform.scale(
                scale: 0.9 + (0.1 * pulse),
                child: Container(
                  width: widget.size * 0.45,
                  height: widget.size * 0.45,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightGreen35BEAA.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CustomAssetImage(
                    path: AppIcons.appLogo,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final LinearGradient gradient;
  final double strokeWidth;
  final double arcLength;

  _RingPainter({
    required this.gradient,
    required this.strokeWidth,
    required this.arcLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background track
    paint.color = gradient.colors.last.withValues(alpha: 0.05);
    canvas.drawCircle(center, radius, paint);

    // Gradient Arc
    paint.shader = SweepGradient(
      colors: [
        gradient.colors.first.withValues(alpha: 0.0),
        gradient.colors.first.withValues(alpha: 0.5),
        gradient.colors.last,
      ],
      stops: const [0.0, 0.4, 1.0],
    ).createShader(rect);

    // Rotate the sweep gradient to align with start angle
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-pi / 2);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawArc(rect, 0, arcLength, false, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
