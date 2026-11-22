import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';

class BookingFormHeader extends StatelessWidget {
  final bool isEdit;

  const BookingFormHeader({super.key, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEdit ? 'edit_booking'.tr() : 'add_new_booking'.tr(),
                style: CustomAppFontStyle.semiBold18.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              CloseButton(color: colors.textSecondary),
            ],
          ),
        ),
        Divider(height: 1, color: colors.borderSubtle),
      ],
    );
  }
}
