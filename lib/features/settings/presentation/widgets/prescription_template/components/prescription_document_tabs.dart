import 'package:flutter/material.dart';

import '../../../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../../../core/utils/theme/custom_app_font_styles.dart';
class PrescriptionDocumentTabs extends StatelessWidget {
  final int activeTab;
  final ValueChanged<int> onTabChanged;

  const PrescriptionDocumentTabs({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    final tabs = [
      (0, 'قوالب الروشتة السريرية (Rx Prescription A4)', Icons.medical_services_outlined),
      (1, 'فواتير وإيصالات العيادة (Invoices & Receipts)', Icons.receipt_long_outlined),
      (2, 'إيصالات الصرف الحرارية (Thermal POS 80mm)', Icons.point_of_sale_outlined),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tabs.map((t) {
          final isSelected = activeTab == t.$1;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () => onTabChanged(t.$1),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : colors.surfaceLevel1,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.borderSubtle,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.$3,
                      size: 15,
                      color: isSelected ? Colors.white : colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.$2,
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: isSelected ? Colors.white : colors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
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
