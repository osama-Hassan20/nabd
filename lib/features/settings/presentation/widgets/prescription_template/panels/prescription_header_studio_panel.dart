import 'package:flutter/material.dart';
import '../../../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../../../core/utils/theme/app_colors.dart';
import '../../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../../shared/widgets/custom_container.dart';
import '../../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../data/models/prescription_template_model.dart';
import '../components/prescription_ui_helpers.dart';

class PrescriptionHeaderStudioPanel extends StatelessWidget {
  final PrescriptionTemplateModel template;
  final TextEditingController doctorNameCtrl;
  final TextEditingController englishDoctorNameCtrl;
  final TextEditingController doctorTitleCtrl;
  final TextEditingController englishDoctorTitleCtrl;
  final TextEditingController clinicNameCtrl;
  final TextEditingController medicalLicenseCtrl;
  final TextEditingController ministryLicenseCtrl;
  final TextEditingController headerHeightCtrl;
  final void Function(PrescriptionTemplateModel Function()) updateTemplate;
  final Future<void> Function(void Function(String base64)) onPickImage;
  final VoidCallback onStateChanged;

  const PrescriptionHeaderStudioPanel({
    super.key,
    required this.template,
    required this.doctorNameCtrl,
    required this.englishDoctorNameCtrl,
    required this.doctorTitleCtrl,
    required this.englishDoctorTitleCtrl,
    required this.clinicNameCtrl,
    required this.medicalLicenseCtrl,
    required this.ministryLicenseCtrl,
    required this.headerHeightCtrl,
    required this.updateTemplate,
    required this.onPickImage,
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
              Icon(Icons.brush_outlined, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'استوديو تصميم الترويسة العلوية (Header Studio)',
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Header Mode Selection
          Text(
            'طريقة إعداد ترويسة الروشتة:',
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
                label: 'رفع بانر جاهز كصورة (فوتوشوب)',
                selected: template.headerMode == 'customBannerImage',
                onSelected: () => updateTemplate(
                  () => template.copyWith(headerMode: 'customBannerImage'),
                ),
              ),
              PrescriptionChoiceChip(
                label: 'تصميم ترويسة ديناميكية ذكية',
                selected: template.headerMode == 'dynamicComposed',
                onSelected: () => updateTemplate(
                  () => template.copyWith(headerMode: 'dynamicComposed'),
                ),
              ),
              PrescriptionChoiceChip(
                label: 'ورق مطبوع مسبقاً (فارغ)',
                selected: template.headerMode == 'preprinted',
                onSelected: () => updateTemplate(
                  () => template.copyWith(headerMode: 'preprinted'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Option A: Upload Custom Banner Image ────────────────────
          if (template.headerMode == 'customBannerImage') ...[
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
                        'صورة بانر الهيدر المصممة (Header Banner Image):',
                        style: CustomAppFontStyle.semiBold12.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (template.headerBannerBase64 != null) ...[
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: PrescriptionBase64Image(
                            base64Str: template.headerBannerBase64,
                            width: 140,
                            height: 50,
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
                              () => template.copyWith(headerBannerBase64: b64),
                            );
                          }),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sync_rounded,
                                  size: 14, color: colors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'تغيير الصورة',
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
                          tooltip: 'حذف الصورة',
                          onPressed: () => updateTemplate(
                            () => template.copyWith(headerBannerBase64: null),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    InkWell(
                      onTap: () => onPickImage((b64) {
                        updateTemplate(
                          () => template.copyWith(headerBannerBase64: b64),
                        );
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  size: 26, color: colors.primary),
                              const SizedBox(height: 4),
                              Text(
                                'انقر لاختيار ورفع صورة بانر الهيدر من جهازك (PNG / JPG)',
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

                  const SizedBox(height: 8),

                  // Header Height Direct Number Input & Stepper
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          controller: headerHeightCtrl,
                          headerText:
                              'ارتفاع بانر الهيدر (px - كتابة رقم مباشر)',
                          hintText: '110',
                          textInputType: TextInputType.number,
                          onChanged: (v) {
                            final n = double.tryParse(v ?? '') ?? 110.0;
                            updateTemplate(
                              () => template.copyWith(headerHeight: n),
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
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 20),
                              tooltip: 'تقليل 5px',
                              onPressed: () {
                                final current =
                                    double.tryParse(headerHeightCtrl.text) ??
                                        template.headerHeight;
                                final next = (current - 5).clamp(30.0, 300.0);
                                headerHeightCtrl.text =
                                    next.toInt().toString();
                                updateTemplate(
                                  () => template.copyWith(headerHeight: next),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  size: 20),
                              tooltip: 'زيادة 5px',
                              onPressed: () {
                                final current =
                                    double.tryParse(headerHeightCtrl.text) ??
                                        template.headerHeight;
                                final next = (current + 5).clamp(30.0, 300.0);
                                headerHeightCtrl.text =
                                    next.toInt().toString();
                                updateTemplate(
                                  () => template.copyWith(headerHeight: next),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // ── Option B: Dynamic Composed Studio ───────────────────────
          if (template.headerMode == 'dynamicComposed') ...[
            // Logo Image Upload
            Row(
              children: [
                Expanded(
                  child: Text(
                    'شعار المركز / لوجو الطبيب:',
                    style: CustomAppFontStyle.medium12.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (template.logoImageBase64 != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: PrescriptionBase64Image(
                      base64Str: template.logoImageBase64,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: AppColors.error),
                    onPressed: () => updateTemplate(
                      () => template.copyWith(logoImageBase64: null),
                    ),
                  ),
                ],
                CustomPushButton(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: colors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => onPickImage((b64) {
                    updateTemplate(
                      () => template.copyWith(logoImageBase64: b64),
                    );
                  }),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_file_rounded,
                          size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        template.logoImageBase64 != null
                            ? 'تغيير اللوجو'
                            : 'رفع لوجو',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Style & Alignment
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ثيم الخلفية:',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: [
                          PrescriptionChoiceChip(
                            label: 'أزرق ملكي',
                            selected: template.headerBackgroundStyle ==
                                'gradientBlue',
                            onSelected: () => updateTemplate(
                              () => template.copyWith(
                                  headerBackgroundStyle: 'gradientBlue'),
                            ),
                          ),
                          PrescriptionChoiceChip(
                            label: 'تركواز',
                            selected: template.headerBackgroundStyle ==
                                'gradientTeal',
                            onSelected: () => updateTemplate(
                              () => template.copyWith(
                                  headerBackgroundStyle: 'gradientTeal'),
                            ),
                          ),
                          PrescriptionChoiceChip(
                            label: 'بنفسجي',
                            selected: template.headerBackgroundStyle ==
                                'gradientPurple',
                            onSelected: () => updateTemplate(
                              () => template.copyWith(
                                  headerBackgroundStyle: 'gradientPurple'),
                            ),
                          ),
                          PrescriptionChoiceChip(
                            label: 'أبيض',
                            selected:
                                template.headerBackgroundStyle == 'white',
                            onSelected: () => updateTemplate(
                              () => template.copyWith(
                                  headerBackgroundStyle: 'white'),
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
                        'توزيع وتنسيق العناصر:',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: [
                          PrescriptionChoiceChip(
                            label: 'عربي/إنجليزي (متناظر)',
                            selected:
                                template.headerAlignment == 'bilingual',
                            onSelected: () => updateTemplate(
                              () => template.copyWith(
                                  headerAlignment: 'bilingual'),
                            ),
                          ),
                          PrescriptionChoiceChip(
                            label: 'ترويسة ثنائية',
                            selected: template.headerAlignment == 'dual',
                            onSelected: () => updateTemplate(
                              () => template.copyWith(
                                  headerAlignment: 'dual'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Doctor names in Arabic & English
            Row(
              children: [
                Expanded(
                  child: CustomTextFormField(
                    controller: doctorNameCtrl,
                    headerText: 'اسم الطبيب (بالعربية)',
                    hintText: 'مثال: أ.د. حسام الدين عزمي',
                    onChanged: (_) => onStateChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextFormField(
                    controller: englishDoctorNameCtrl,
                    headerText: 'Doctor Name (English)',
                    hintText: 'Prof. Dr. Hossam El-Din',
                    onChanged: (_) => onStateChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Titles
            Row(
              children: [
                Expanded(
                  child: CustomTextFormField(
                    controller: doctorTitleCtrl,
                    headerText: 'الدرجة العلمية والتخصص (عربي)',
                    hintText: 'استشاري الأمراض الباطنة والقلب',
                    onChanged: (_) => onStateChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextFormField(
                    controller: englishDoctorTitleCtrl,
                    headerText: 'Title & Specialty (English)',
                    hintText: 'Consultant of Cardiology',
                    onChanged: (_) => onStateChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Clinic name & licenses
            Row(
              children: [
                Expanded(
                  child: CustomTextFormField(
                    controller: clinicNameCtrl,
                    headerText: 'اسم المركز / العيادة',
                    hintText: 'مجمع المهندسين التخصصي',
                    onChanged: (_) => onStateChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextFormField(
                    controller: medicalLicenseCtrl,
                    headerText: 'ترخيص النقابة',
                    hintText: '441092',
                    onChanged: (_) => onStateChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextFormField(
                    controller: ministryLicenseCtrl,
                    headerText: 'ترخيص وزارة الصحة',
                    hintText: '8849/2021',
                    onChanged: (_) => onStateChanged(),
                  ),
                ),
              ],
            ),
          ],

          // ── Option C: Preprinted Stationery Studio ─────────────────
          if (template.headerMode == 'preprinted') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.isDark
                    ? Colors.orange.shade900.withValues(alpha: 0.15)
                    : Colors.orange.shade50.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.isDark
                      ? Colors.orange.shade700
                      : Colors.orange.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.print_outlined,
                          size: 17, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'إعدادات الورق المروّس الجاهز من المطبعة (Pre-printed Paper):',
                          style: CustomAppFontStyle.semiBold12.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          headerText: 'ارتفاع ترويسة المطبعة الفارغة (mm)',
                          hintText: '45',
                          initialValue: template.preprintedHeaderHeight
                              .toInt()
                              .toString(),
                          textInputType: TextInputType.number,
                          onChanged: (v) {
                            final n = double.tryParse(v ?? '') ?? 45.0;
                            updateTemplate(
                              () =>
                                  template.copyWith(preprintedHeaderHeight: n),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextFormField(
                          headerText: 'ارتفاع تذييل المطبعة الفارغ (mm)',
                          hintText: '30',
                          initialValue: template.preprintedFooterHeight
                              .toInt()
                              .toString(),
                          textInputType: TextInputType.number,
                          onChanged: (v) {
                            final n = double.tryParse(v ?? '') ?? 30.0;
                            updateTemplate(
                              () =>
                                  template.copyWith(preprintedFooterHeight: n),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Quick presets chips: 35mm, 45mm, 50mm, 60mm
                  Row(
                    children: [
                      Text(
                        'مقاسات هيدر شائعة:',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ...[35.0, 45.0, 50.0, 60.0].map((h) {
                        final isSel = template.preprintedHeaderHeight == h;
                        return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: InkWell(
                            onTap: () => updateTemplate(
                              () =>
                                  template.copyWith(preprintedHeaderHeight: h),
                            ),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? colors.primary
                                    : colors.cardBackground,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSel
                                      ? colors.primary
                                      : colors.borderSubtle,
                                ),
                              ),
                              child: Text(
                                '${h.toInt()}mm',
                                style: CustomAppFontStyle.medium10.copyWith(
                                  color:
                                      isSel ? Colors.white : colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Switch to hide printed clinic addresses if already on pre-printed paper
                  PrescriptionSwitchItem(
                    label:
                        'إخفاء طباعة العناوين والهواتف (لأنها مطبوعة في أسفل الورقة مسبقاً)',
                    value: template.hideFooterOnPreprinted,
                    onChanged: (val) => updateTemplate(
                      () => template.copyWith(hideFooterOnPreprinted: val),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
