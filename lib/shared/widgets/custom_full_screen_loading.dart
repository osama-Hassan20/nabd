import 'dart:async';
import 'dart:ui';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_gradient.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_center_loading_widget.dart';
import 'package:flutter/material.dart';

class CustomFullScreenLoading extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? typedText;
  const CustomFullScreenLoading({
    super.key,
    required this.isLoading,
    required this.child,
    this.typedText,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isLoading,
      child: Stack(
        children: [
          child,
          if (isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.gray334155.withValues(alpha: 0.1),
                    gradient: RadialGradient(
                      colors: [
                        AppColors.lightGreen35BEAA.withValues(alpha: 0.1),
                        AppColors.gray334155.withValues(alpha: 0.05),
                      ],
                      center: Alignment.center,
                      radius: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CustomCenterLoadingWidget(size: 120),
                        const SizedBox(height: 24),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppGradient.greenGradient.createShader(bounds),
                          child: TypingAnimatedText(
                            text:typedText ?? "جاري العمل علي طلبك",
                            style: CustomAppFontStyle.bold20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TypingAnimatedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const TypingAnimatedText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<TypingAnimatedText> createState() => _TypingAnimatedTextState();
}

class _TypingAnimatedTextState extends State<TypingAnimatedText> {
  String _displayedText = "";
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.duration, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style.copyWith(color: Colors.white),
    );
  }
}

class CustomFullScreenLoadingSliver extends StatelessWidget {
  final bool isLoading;
  final Widget child; // Sliver widget

  const CustomFullScreenLoadingSliver({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isLoading,
      child: Stack(
        children: [
          CustomScrollView(slivers: [child]),
          if (isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.gray334155.withValues(alpha: 0.1),
                    gradient: RadialGradient(
                      colors: [
                        AppColors.lightGreen35BEAA.withValues(alpha: 0.1),
                        AppColors.gray334155.withValues(alpha: 0.05),
                      ],
                      center: Alignment.center,
                      radius: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CustomCenterLoadingWidget(size: 120),
                        const SizedBox(height: 24),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppGradient.greenGradient.createShader(bounds),
                          child: const TypingAnimatedText(
                            text: "جاري العمل علي طلبك",
                            style: CustomAppFontStyle.bold20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
