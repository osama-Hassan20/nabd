import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';

class PatientEmrTabBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int>? onTabSelected;
  final int consultationsCount;
  final int activeMedsCount;
  final int labsCount;
  final int surgeriesCount;
  final int specialtyCount;
  final int treatmentPlansCount;
  final int bookingsCount;

  const PatientEmrTabBar({
    super.key,
    this.activeIndex = 0,
    this.onTabSelected,
    this.consultationsCount = 0,
    this.activeMedsCount = 0,
    this.labsCount = 0,
    this.surgeriesCount = 0,
    this.specialtyCount = 0,
    this.treatmentPlansCount = 0,
    this.bookingsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    final tabs = [
      (
        title: 'الكشوفات والروشتات السابقة',
        icon: Icons.history_edu_rounded,
        count: consultationsCount,
      ),
      (
        title: 'الأدوية المستمرة والحساسيات',
        icon: Icons.medication_outlined,
        count: activeMedsCount,
      ),
      (
        title: 'التحاليل والأشعة والمرفقات',
        icon: Icons.biotech_outlined,
        count: labsCount,
      ),
      (
        title: 'العمليات والتاريخ الجراحي',
        icon: Icons.local_hospital_outlined,
        count: surgeriesCount,
      ),
      (
        title: 'تتبع التخصصات ومعرض الصور',
        icon: Icons.auto_awesome_motion_rounded,
        count: specialtyCount,
      ),
      (
        title: 'الخدمات والخطط العلاجية',
        icon: Icons.assignment_turned_in_outlined,
        count: treatmentPlansCount,
      ),
      (
        title: 'المواعيد والحجوزات',
        icon: Icons.calendar_month_outlined,
        count: bookingsCount,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isSelected = activeIndex == idx;

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () => onTabSelected?.call(idx),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : colors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.borderSubtle,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 16,
                      color: isSelected ? Colors.white : colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.title,
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: isSelected ? Colors.white : colors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (item.count > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : colors.surfaceLevel1,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? null
                              : Border.all(color: colors.borderSubtle),
                        ),
                        child: Text(
                          '${item.count}',
                          style: CustomAppFontStyle.bold11.copyWith(
                            color: isSelected ? Colors.white : colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
