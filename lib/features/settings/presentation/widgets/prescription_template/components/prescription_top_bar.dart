import 'package:flutter/material.dart';

import '../../../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../../shared/widgets/custom_push_container_button.dart';

class PrescriptionTopBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onOpenPresets;
  final VoidCallback onResetDefault;
  final VoidCallback onPrintTestPage;
  final VoidCallback onSaveTemplate;

  const PrescriptionTopBar({
    super.key,
    required this.isLoading,
    required this.onOpenPresets,
    required this.onResetDefault,
    required this.onPrintTestPage,
    required this.onSaveTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'استوديو تصميم قوالب الروشتة والمطبوعات الطبية',
                  style: CustomAppFontStyle.bold18.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.isDark
                        ? Colors.teal.shade900.withValues(alpha: 0.35)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.isDark
                          ? Colors.teal.shade700
                          : const Color(0xFF86EFAC),
                    ),
                  ),
                  child: Text(
                    'محرر متقدم ومرن',
                    style: CustomAppFontStyle.semiBold12.copyWith(
                      color: colors.isDark
                          ? Colors.teal.shade300
                          : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'صمم روشتتك الطبية بحرية تامة: رفع بانر مخصص كصورة، علامات مائية، QR Code، وتصميم ظهر الروشتة للتعليمات.',
              style: CustomAppFontStyle.regular12.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),

        // Action Buttons
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            CustomPushButton(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: colors.isDark
                  ? colors.surfaceLevel2
                  : const Color(0xFFEFF6FF),
              boxBorder: Border.all(
                color: colors.isDark
                    ? colors.borderSubtle
                    : const Color(0xFFBFDBFE),
              ),
              borderRadius: BorderRadius.circular(8),
              onTap: onOpenPresets,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 15, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text(
                    'قوالب عيادات جاهزة',
                    style: CustomAppFontStyle.semiBold12.copyWith(
                      color: colors.isDark
                          ? Colors.blue.shade300
                          : const Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            ),
            CustomPushButton(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: colors.surfaceLevel1,
              boxBorder: Border.all(color: colors.borderSubtle),
              borderRadius: BorderRadius.circular(8),
              onTap: onResetDefault,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restore_rounded,
                      size: 15, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'استعادة القياسي',
                    style: CustomAppFontStyle.medium12.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            CustomPushButton(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: colors.surfaceLevel1,
              boxBorder: Border.all(color: colors.borderSubtle),
              borderRadius: BorderRadius.circular(8),
              onTap: onPrintTestPage,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print_outlined, size: 15, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'طباعة تجريبية',
                    style: CustomAppFontStyle.medium12.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
            CustomPushButton(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              backgroundColor: colors.primary,
              isLoading: isLoading,
              borderRadius: BorderRadius.circular(8),
              onTap: onSaveTemplate,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'حفظ وتطبيق القالب',
                    style: CustomAppFontStyle.semiBold13.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
