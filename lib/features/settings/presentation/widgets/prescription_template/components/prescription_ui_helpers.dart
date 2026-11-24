import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../../../core/utils/theme/custom_app_font_styles.dart';

/// Reusable styled ChoiceChip for Prescription Studio
class PrescriptionChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const PrescriptionChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: colors.primary,
      backgroundColor: colors.surfaceLevel1,
      showCheckmark: false,
      labelStyle: CustomAppFontStyle.semiBold11.copyWith(
        color: selected ? Colors.white : colors.textPrimary,
      ),
      side: BorderSide(
        color: selected ? colors.primary : colors.borderSubtle,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

/// Compact Switch Item Container for Prescription Options
class PrescriptionSwitchItem extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const PrescriptionSwitchItem({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceLevel1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: CustomAppFontStyle.medium12.copyWith(
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              activeThumbColor: colors.primary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Memory image renderer from base64 string
class PrescriptionBase64Image extends StatelessWidget {
  final String? base64Str;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const PrescriptionBase64Image({
    super.key,
    required this.base64Str,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (base64Str == null || base64Str!.isEmpty) {
      return fallback ?? const SizedBox.shrink();
    }
    try {
      final bytes = base64Decode(base64Str!);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
      );
    } catch (_) {
      return fallback ?? const SizedBox.shrink();
    }
  }
}
