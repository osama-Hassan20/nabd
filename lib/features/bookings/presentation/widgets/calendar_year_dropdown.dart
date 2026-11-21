import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';

class CalendarYearDropdown extends StatelessWidget {
  final int selectedYear;
  final ValueChanged<int> onYearSelected;
  final int? startYear;
  final int? endYear;

  const CalendarYearDropdown({
    super.key,
    required this.selectedYear,
    required this.onYearSelected,
    this.startYear,
    this.endYear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final now = CairoTimeHelper.now();
    final effectiveStartYear = startYear ?? (now.year - 5);
    final effectiveEndYear = endYear ?? (now.year + 5);

    final years = List.generate(
      (effectiveEndYear - effectiveStartYear) + 1,
      (index) => effectiveStartYear + index,
    );

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: colors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.borderSubtle),
          ),
          elevation: 4,
        ),
      ),
      child: PopupMenuButton<int>(
        tooltip: 'select_year'.tr(),
        initialValue: selectedYear,
        onSelected: onYearSelected,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(maxHeight: 240, minWidth: 105),
        itemBuilder: (context) {
          return years.map((year) {
            final isCurrent = year == selectedYear;
            return PopupMenuItem<int>(
              value: year,
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      isCurrent ? colors.primaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      year.toString(),
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color:
                            isCurrent ? colors.primary : colors.textPrimary,
                      ),
                    ),
                    if (isCurrent)
                      Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: colors.primary,
                      ),
                  ],
                ),
              ),
            );
          }).toList();
        },
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colors.surfaceLevel1,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedYear.toString(),
                style: CustomAppFontStyle.semiBold13.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
