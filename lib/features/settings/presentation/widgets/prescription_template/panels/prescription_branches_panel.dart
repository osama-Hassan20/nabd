import 'package:flutter/material.dart';
import '../../../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../../../core/utils/theme/app_colors.dart';
import '../../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../../shared/widgets/custom_container.dart';
import '../../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../data/models/prescription_template_model.dart';
import '../components/prescription_ui_helpers.dart';

class PrescriptionBranchesPanel extends StatelessWidget {
  final PrescriptionTemplateModel template;
  final List<TextEditingController> addressCtrls;
  final List<TextEditingController> phoneCtrls;
  final TextEditingController footerHeightCtrl;
  final TextEditingController footerMarginTopCtrl;
  final TextEditingController footerMarginBottomCtrl;
  final TextEditingController footerMarginRightCtrl;
  final TextEditingController footerMarginLeftCtrl;
  final void Function(PrescriptionTemplateModel Function()) updateTemplate;
  final Future<void> Function(void Function(String base64)) onPickImage;
  final VoidCallback onAddAddress;
  final void Function(int) onRemoveAddress;
  final VoidCallback onAddPhone;
  final void Function(int) onRemovePhone;
  final VoidCallback onStateChanged;

  const PrescriptionBranchesPanel({
    super.key,
    required this.template,
    required this.addressCtrls,
    required this.phoneCtrls,
    required this.footerHeightCtrl,
    required this.footerMarginTopCtrl,
    required this.footerMarginBottomCtrl,
    required this.footerMarginRightCtrl,
    required this.footerMarginLeftCtrl,
    required this.updateTemplate,
    required this.onPickImage,
    required this.onAddAddress,
    required this.onRemoveAddress,
    required this.onAddPhone,
    required this.onRemovePhone,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return CustomContainer(
      backGroundColor: colors.cardBackground,
      border: Border.all(color: colors.borderSubtle),
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.view_compact_alt_outlined,
                  size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'استوديو تصميم التذييل والفروع (Footer Studio)',
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Footer Mode Selection (Just like Header Studio)
          Text(
            'طريقة إعداد تذييل الروشتة (Footer Mode):',
            style: CustomAppFontStyle.medium12.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              PrescriptionChoiceChip(
                label: 'تصميم تذييل ديناميكي ذكي',
                selected: template.footerMode == 'dynamicComposed',
                onSelected: () => updateTemplate(
                  () => template.copyWith(footerMode: 'dynamicComposed'),
                ),
              ),
              PrescriptionChoiceChip(
                label: 'رفع بانر تذييل جاهز (فوتوشوب)',
                selected: template.footerMode == 'customBannerImage',
                onSelected: () => updateTemplate(
                  () => template.copyWith(footerMode: 'customBannerImage'),
                ),
              ),
              PrescriptionChoiceChip(
                label: 'ورق مطبوع مسبقاً (فارغ)',
                selected: template.footerMode == 'preprinted',
                onSelected: () => updateTemplate(
                  () => template.copyWith(footerMode: 'preprinted'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Option A: Upload Custom Footer Banner Image ─────────────
          if (template.footerMode == 'customBannerImage') ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceLevel1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.image_outlined,
                          size: 16, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'صورة بانر التذييل المخصصة (Footer Banner Image):',
                        style: CustomAppFontStyle.semiBold12.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (template.footerBannerBase64 != null) ...[
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: PrescriptionBase64Image(
                            base64Str: template.footerBannerBase64,
                            width: 140,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        CustomPushButton(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          backgroundColor: colors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => onPickImage((b64) {
                            updateTemplate(
                              () => template.copyWith(footerBannerBase64: b64),
                            );
                          }),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sync_rounded,
                                  size: 14, color: colors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'تغيير البانر',
                                style: CustomAppFontStyle.medium11.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                          tooltip: 'حذف صورة التذييل',
                          onPressed: () => updateTemplate(
                            () => template.copyWith(footerBannerBase64: null),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    InkWell(
                      onTap: () => onPickImage((b64) {
                        updateTemplate(
                          () => template.copyWith(footerBannerBase64: b64),
                        );
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: colors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.5),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_upload_outlined,
                                  size: 24, color: colors.primary),
                              const SizedBox(height: 4),
                              Text(
                                'انقر لاختيار ورفع صورة بانر التذييل من جهازك (PNG / JPG)',
                                style: CustomAppFontStyle.semiBold12.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── Option B: Dynamic Composed Footer Styling ───────────────
          if (template.footerMode == 'dynamicComposed') ...[
            // Background Theme & Border Styling
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ثيم وألوان التذييل:',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: [
                          PrescriptionChoiceChip(
                            label: 'أبيض هادئ',
                            selected: template.footerBackgroundStyle == 'white',
                            onSelected: () => updateTemplate(
                              () => template.copyWith(
                                  footerBackgroundStyle: 'white'),
                            ),
                          ),
                          PrescriptionChoiceChip(
                            label: 'أزرق ملكي',
                            selected: template.footerBackgroundStyle ==
                                'gradientBlue',
                            onSelected: () => updateTemplate(
                              () => template.copyWith(
                                  footerBackgroundStyle: 'gradientBlue'),
                            ),
                          ),
                          PrescriptionChoiceChip(
                            label: 'تركواز',
                            selected: template.footerBackgroundStyle ==
                                'gradientTeal',
                            onSelected: () => updateTemplate(
                              () => template.copyWith(
                                  footerBackgroundStyle: 'gradientTeal'),
                            ),
                          ),
                          PrescriptionChoiceChip(
                            label: 'بطاقة ناعمة',
                            selected:
                                template.footerBackgroundStyle == 'softCard',
                            onSelected: () => updateTemplate(
                              () => template.copyWith(
                                  footerBackgroundStyle: 'softCard'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'شكل وتصميم الإطار:',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: [
                          PrescriptionChoiceChip(
                            label: 'خط فاصل',
                            selected: template.footerShapeStyle == 'flat',
                            onSelected: () => updateTemplate(
                              () =>
                                  template.copyWith(footerShapeStyle: 'flat'),
                            ),
                          ),
                          PrescriptionChoiceChip(
                            label: 'بطاقة مدورة',
                            selected:
                                template.footerShapeStyle == 'roundedCard',
                            onSelected: () => updateTemplate(
                              () => template.copyWith(
                                  footerShapeStyle: 'roundedCard'),
                            ),
                          ),
                          PrescriptionChoiceChip(
                            label: 'موجة انسيابية',
                            selected:
                                template.footerShapeStyle == 'curvedWave',
                            onSelected: () => updateTemplate(
                              () => template.copyWith(
                                  footerShapeStyle: 'curvedWave'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Branches Addresses Editor
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'عناوين الفروع المطبوعة أسفل الروشتة:',
                      style: CustomAppFontStyle.semiBold12.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                CustomPushButton(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: colors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                  onTap: onAddAddress,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'إضافة فرع',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ..._buildPairedAddressInputs(colors),

            const SizedBox(height: 10),

            // Hotlines and Phone Numbers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.phone_in_talk_outlined,
                        size: 16, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'أرقام الهواتف والخط الساخن المطبوعة:',
                      style: CustomAppFontStyle.semiBold12.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                CustomPushButton(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: colors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                  onTap: onAddPhone,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'إضافة هاتف',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ..._buildPairedPhoneInputs(colors),
          ],

          const SizedBox(height: 12),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 10),

          // Footer Height Direct Number Input & Stepper
          Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                  controller: footerHeightCtrl,
                  headerText: 'ارتفاع التذييل السفلي (px - كتابة رقم مباشر)',
                  hintText: '85',
                  textInputType: TextInputType.number,
                  onChanged: (v) {
                    final n = double.tryParse(v ?? '') ?? 85.0;
                    updateTemplate(
                      () => template.copyWith(footerHeight: n),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      tooltip: 'تقليل 5px',
                      onPressed: () {
                        final current =
                            double.tryParse(footerHeightCtrl.text) ??
                                template.footerHeight;
                        final next = (current - 5).clamp(30.0, 200.0);
                        footerHeightCtrl.text = next.toInt().toString();
                        updateTemplate(
                          () => template.copyWith(footerHeight: next),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      tooltip: 'زيادة 5px',
                      onPressed: () {
                        final current =
                            double.tryParse(footerHeightCtrl.text) ??
                                template.footerHeight;
                        final next = (current + 5).clamp(30.0, 200.0);
                        footerHeightCtrl.text = next.toInt().toString();
                        updateTemplate(
                          () => template.copyWith(footerHeight: next),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Footer 4-Way Margins
          Row(
            children: [
              Text(
                'هوامش التذييل (mm):',
                style: CustomAppFontStyle.medium11.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: footerMarginTopCtrl,
                        headerText: 'أعلى',
                        hintText: '8',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 8.0;
                          updateTemplate(
                            () => template.copyWith(footerMarginTop: n),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: CustomTextFormField(
                        controller: footerMarginBottomCtrl,
                        headerText: 'أسفل',
                        hintText: '12',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 12.0;
                          updateTemplate(
                            () => template.copyWith(footerMarginBottom: n),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: CustomTextFormField(
                        controller: footerMarginRightCtrl,
                        headerText: 'يمين',
                        hintText: '15',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 15.0;
                          updateTemplate(
                            () => template.copyWith(footerMarginRight: n),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: CustomTextFormField(
                        controller: footerMarginLeftCtrl,
                        headerText: 'يسار',
                        hintText: '15',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 15.0;
                          updateTemplate(
                            () => template.copyWith(footerMarginLeft: n),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPairedAddressInputs(AppThemeColors colors) {
    final widgets = <Widget>[];
    for (int i = 0; i < addressCtrls.length; i += 2) {
      final ctrl1 = addressCtrls[i];
      final idx1 = i;
      final hasSecond = (i + 1) < addressCtrls.length;
      final ctrl2 = hasSecond ? addressCtrls[i + 1] : null;
      final idx2 = i + 1;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: ctrl1,
                        hintText: 'عنوان الفرع رقم ${idx1 + 1}',
                        onChanged: (_) => onStateChanged(),
                      ),
                    ),
                    if (addressCtrls.length > 1) ...[
                      const SizedBox(width: 2),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 26, minHeight: 26),
                        icon: const Icon(Icons.delete_outline,
                            size: 15, color: AppColors.error),
                        onPressed: () => onRemoveAddress(idx1),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasSecond && ctrl2 != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          controller: ctrl2,
                          hintText: 'عنوان الفرع رقم ${idx2 + 1}',
                          onChanged: (_) => onStateChanged(),
                        ),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 26, minHeight: 26),
                        icon: const Icon(Icons.delete_outline,
                            size: 15, color: AppColors.error),
                        onPressed: () => onRemoveAddress(idx2),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildPairedPhoneInputs(AppThemeColors colors) {
    final widgets = <Widget>[];
    for (int i = 0; i < phoneCtrls.length; i += 2) {
      final ctrl1 = phoneCtrls[i];
      final idx1 = i;
      final hasSecond = (i + 1) < phoneCtrls.length;
      final ctrl2 = hasSecond ? phoneCtrls[i + 1] : null;
      final idx2 = i + 1;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: ctrl1,
                        hintText: 'رقم هاتف / واتساب ${idx1 + 1}',
                        onChanged: (_) => onStateChanged(),
                      ),
                    ),
                    if (phoneCtrls.length > 1) ...[
                      const SizedBox(width: 2),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 26, minHeight: 26),
                        icon: const Icon(Icons.delete_outline,
                            size: 15, color: AppColors.error),
                        onPressed: () => onRemovePhone(idx1),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasSecond && ctrl2 != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          controller: ctrl2,
                          hintText: 'رقم هاتف / واتساب ${idx2 + 1}',
                          onChanged: (_) => onStateChanged(),
                        ),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 26, minHeight: 26),
                        icon: const Icon(Icons.delete_outline,
                            size: 15, color: AppColors.error),
                        onPressed: () => onRemovePhone(idx2),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return widgets;
  }
}
