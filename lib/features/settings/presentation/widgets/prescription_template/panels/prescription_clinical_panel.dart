import 'package:flutter/material.dart';
import '../../../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../../shared/widgets/custom_container.dart';
import '../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../data/models/prescription_template_model.dart';
import '../components/prescription_ui_helpers.dart';

class PrescriptionClinicalPanel extends StatelessWidget {
  final PrescriptionTemplateModel template;
  final TextEditingController disclaimerCtrl;
  final TextEditingController followUpTextCtrl;
  final TextEditingController headerHeightCtrl;
  final TextEditingController headerMarginTopCtrl;
  final TextEditingController headerMarginBottomCtrl;
  final TextEditingController headerMarginRightCtrl;
  final TextEditingController headerMarginLeftCtrl;
  final TextEditingController bodyMarginTopCtrl;
  final TextEditingController bodyMarginBottomCtrl;
  final TextEditingController bodyMarginRightCtrl;
  final TextEditingController bodyMarginLeftCtrl;
  final void Function(PrescriptionTemplateModel Function()) updateTemplate;
  final VoidCallback onStateChanged;

  const PrescriptionClinicalPanel({
    super.key,
    required this.template,
    required this.disclaimerCtrl,
    required this.followUpTextCtrl,
    required this.headerHeightCtrl,
    required this.headerMarginTopCtrl,
    required this.headerMarginBottomCtrl,
    required this.headerMarginRightCtrl,
    required this.headerMarginLeftCtrl,
    required this.bodyMarginTopCtrl,
    required this.bodyMarginBottomCtrl,
    required this.bodyMarginRightCtrl,
    required this.bodyMarginLeftCtrl,
    required this.updateTemplate,
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
              Icon(Icons.tune_rounded, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'الخيارات السريرية وهوامش الصفحة (Clinical Options & Margins)',
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2x2 switches
          Row(
            children: [
              Expanded(
                child: PrescriptionSwitchItem(
                  label: 'الأمراض المزمنة والحساسية',
                  value: template.showChronicDiseasesAndAllergies,
                  onChanged: (val) => updateTemplate(
                    () => template.copyWith(
                        showChronicDiseasesAndAllergies: val),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrescriptionSwitchItem(
                  label: 'القياسات الحيوية (الضغط والوزن)',
                  value: template.showVitalSigns,
                  onChanged: (val) => updateTemplate(
                    () => template.copyWith(showVitalSigns: val),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: PrescriptionSwitchItem(
                  label: 'التشخيص الطبي السريري',
                  value: template.showClinicalDiagnosis,
                  onChanged: (val) => updateTemplate(
                    () => template.copyWith(showClinicalDiagnosis: val),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrescriptionSwitchItem(
                  label: 'رمز الاستجابة QR Code',
                  value: template.showQrCode,
                  onChanged: (val) => updateTemplate(
                    () => template.copyWith(showQrCode: val),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          CustomTextFormField(
            controller: disclaimerCtrl,
            headerText: 'التنبيه القانوني وإخلاء المسؤولية المطبوع أسفل الروشتة',
            hintText: 'صالح للصرف خلال 7 أيام من تاريخ التحرير...',
            onChanged: (_) => onStateChanged(),
          ),
          const SizedBox(height: 8),

          // ─── Clinical Rx Layout & Follow-up Box ───────────────────
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 16, color: colors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'تخطيط جدول الأدوية (Rx Layout):',
                          style: CustomAppFontStyle.semiBold12.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    PrescriptionChoiceChip(
                      label: 'أسطر سريرية كلاسيكية (Lines)',
                      selected: template.rxLayoutStyle == 'lines',
                      onSelected: () => updateTemplate(
                        () => template.copyWith(rxLayoutStyle: 'lines'),
                      ),
                    ),
                    PrescriptionChoiceChip(
                      label: 'جدول علاجي منظم (Table)',
                      selected: template.rxLayoutStyle == 'table',
                      onSelected: () => updateTemplate(
                        () => template.copyWith(rxLayoutStyle: 'table'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: PrescriptionSwitchItem(
                        label: 'إظهار مربع موعد الاستشارة والمتابعة السريرية',
                        value: template.showFollowUpBox,
                        onChanged: (val) => updateTemplate(
                          () => template.copyWith(showFollowUpBox: val),
                        ),
                      ),
                    ),
                  ],
                ),
                if (template.showFollowUpBox) ...[
                  const SizedBox(height: 6),
                  CustomTextFormField(
                    controller: followUpTextCtrl,
                    headerText: 'نص موعد الاستشارة وشروط الإعادة',
                    hintText:
                        'خلال 7 أيام من تاريخ الكشف مع إحضار أصل الروشتة للمتابعة...',
                    onChanged: (v) {
                      updateTemplate(
                        () => template.copyWith(followUpText: v ?? ''),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ─── 1. Header Margins & Height ──────────────────────────
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'هوامش الترويسة العلوية (Header Margins mm):',
                      style: CustomAppFontStyle.semiBold12.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: CustomTextFormField(
                        controller: headerHeightCtrl,
                        headerText: 'ارتفاع الهيدر (px)',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 110.0;
                          updateTemplate(
                            () => template.copyWith(headerHeight: n),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: headerMarginTopCtrl,
                        headerText: 'أعلى',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 0.0;
                          updateTemplate(
                            () => template.copyWith(headerMarginTop: n),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomTextFormField(
                        controller: headerMarginBottomCtrl,
                        headerText: 'أسفل',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 8.0;
                          updateTemplate(
                            () => template.copyWith(headerMarginBottom: n),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomTextFormField(
                        controller: headerMarginRightCtrl,
                        headerText: 'يمين',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 15.0;
                          updateTemplate(
                            () => template.copyWith(headerMarginRight: n),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomTextFormField(
                        controller: headerMarginLeftCtrl,
                        headerText: 'يسار',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 15.0;
                          updateTemplate(
                            () => template.copyWith(headerMarginLeft: n),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ─── 2. Body Margins ──────────────────────────────────────
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
                Text(
                  'هوامش جسم الروشتة (Rx Body Margins mm):',
                  style: CustomAppFontStyle.semiBold12.copyWith(
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: bodyMarginTopCtrl,
                        headerText: 'أعلى',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 8.0;
                          updateTemplate(
                            () => template.copyWith(bodyMarginTop: n),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomTextFormField(
                        controller: bodyMarginBottomCtrl,
                        headerText: 'أسفل',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 8.0;
                          updateTemplate(
                            () => template.copyWith(bodyMarginBottom: n),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomTextFormField(
                        controller: bodyMarginRightCtrl,
                        headerText: 'يمين',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 15.0;
                          updateTemplate(
                            () => template.copyWith(bodyMarginRight: n),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomTextFormField(
                        controller: bodyMarginLeftCtrl,
                        headerText: 'يسار',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 15.0;
                          updateTemplate(
                            () => template.copyWith(bodyMarginLeft: n),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
