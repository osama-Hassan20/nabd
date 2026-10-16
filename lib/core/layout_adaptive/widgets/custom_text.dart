import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A highly customizable text widget that supports all possible text styling options.
/// This widget provides easy access to all TextStyle properties and Text widget properties.
class CustomText extends StatelessWidget {
  // Text content
  final String text;

  // TextStyle properties
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final String? fontFamily;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final TextDecoration? decoration;
  final Color? decorationColor;
  final TextDecorationStyle? decorationStyle;
  final double? decorationThickness;
  final List<Shadow>? shadows;
  final Paint? foreground;
  final Paint? background;
  final TextBaseline? textBaseline;
  final Locale? locale;
  final TextStyle? style;

  // Text widget properties
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool? softWrap;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final SelectionRegistrar? selectionRegistrar;
  final Color? selectionColor;
  final ScrollPhysics? scrollPhysics;

  // Additional convenience properties
  final bool isSelectable;
  final VoidCallback? onTap;

  const CustomText(
    this.text, {
    super.key,
    // TextStyle properties
    this.color,
    this.style,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.fontFamily,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.decorationThickness,
    this.shadows,
    this.foreground,
    this.background,
    this.textBaseline,
    this.locale,
    // Text widget properties
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionRegistrar,
    this.selectionColor,
    this.scrollPhysics,
    // Additional properties
    this.isSelectable = true,
    this.onTap,
  });

  // Factory constructors for common text styles
  factory CustomText.heading(
    String text, {
    Color? color,
    FontWeight? fontWeight = FontWeight.bold,
    double? fontSize = 32,
    Key? key,
  }) {
    return CustomText(
      text,
      key: key,
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  factory CustomText.title(
    String text, {
    Color? color,
    FontWeight? fontWeight = FontWeight.w600,
    double? fontSize = 24,
    Key? key,
  }) {
    return CustomText(
      text,
      key: key,
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  factory CustomText.subtitle(
    String text, {
    Color? color,
    FontWeight? fontWeight = FontWeight.w500,
    double? fontSize = 18,
    Key? key,
  }) {
    return CustomText(
      text,
      key: key,
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  factory CustomText.body(
    String text, {
    Color? color,
    FontWeight? fontWeight = FontWeight.normal,
    double? fontSize = 16,
    Key? key,
  }) {
    return CustomText(
      text,
      key: key,
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  factory CustomText.caption(
    String text, {
    Color? color,
    FontWeight? fontWeight = FontWeight.normal,
    double? fontSize = 12,
    Key? key,
  }) {
    return CustomText(
      text,
      key: key,
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle =
        style ??
        TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          fontFamily: fontFamily,
          letterSpacing: letterSpacing,
          wordSpacing: wordSpacing,
          height: height,
          decoration: decoration,
          decorationColor: decorationColor,
          decorationStyle: decorationStyle,
          decorationThickness: decorationThickness,
          shadows: shadows,
          foreground: foreground,
          background: background,
          textBaseline: textBaseline,
          locale: locale,
        );

    Widget textWidget = Text(
      text,
      style: textStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: color?.withValues(alpha: 0.5),
    );

    if (onTap != null) {
      textWidget = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: textWidget,
      );
    }

    if (isSelectable) {
      return SelectionArea(child: textWidget);
    }

    return textWidget;
  }
}
