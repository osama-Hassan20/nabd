import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/enums/blood_group_enum.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class BloodGroupSelector extends StatelessWidget {
  final BloodGroupEnum? selectedGroup;
  final ValueChanged<BloodGroupEnum?> onSelected;
  final String? header;
  final bool? isCompact;

  const BloodGroupSelector({
    super.key,
    BloodGroupEnum? selectedGroup,
    BloodGroupEnum? selected,
    required this.onSelected,
    this.header,
    this.isCompact,
  }) : selectedGroup = selectedGroup ?? selected;

  static const List<BloodGroupEnum> _availableGroups = [
    BloodGroupEnum.aPositive,
    BloodGroupEnum.aNegative,
    BloodGroupEnum.bPositive,
    BloodGroupEnum.bNegative,
    BloodGroupEnum.abPositive,
    BloodGroupEnum.abNegative,
    BloodGroupEnum.oPositive,
    BloodGroupEnum.oNegative,
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = AdaptiveLayout.isMobile(context);
    final colors = context.themeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null) ...[
          Text(
            header ?? 'blood_group'.tr(),
            style: CustomAppFontStyle.medium14.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = isCompact ?? (isMobile || constraints.maxWidth < 620);

            if (isNarrow) {
              // 2 rows inside a single unified horizontal scroll
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: _availableGroups.take(4).map((g) => _buildChip(context, g)).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _availableGroups.skip(4).take(4).map((g) => _buildChip(context, g)).toList(),
                    ),
                  ],
                ),
              );
            }

            // Desktop: single row with all 8 groups
            return Row(
              children: _availableGroups.map((g) => Expanded(child: _buildChip(context, g))).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, BloodGroupEnum group) {
    final colors = context.themeColors;
    final isSelected = selectedGroup == group;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: InkWell(
        onTap: () {
          if (isSelected) {
            onSelected(null); // Unselect if already selected
          } else {
            onSelected(group);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38,
          constraints: const BoxConstraints(minWidth: 54),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.surfaceLevel1,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colors.primary : colors.borderSubtle,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                group.value,
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: isSelected ? Colors.white : colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

