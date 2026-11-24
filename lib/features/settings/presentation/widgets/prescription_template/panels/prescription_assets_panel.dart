import 'package:flutter/material.dart';

import '../../../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../../../core/utils/theme/app_colors.dart';
import '../../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../../shared/widgets/custom_container.dart';
import '../../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../data/models/prescription_template_model.dart';
import '../components/prescription_ui_helpers.dart';

class PrescriptionAssetsPanel extends StatelessWidget {
  final PrescriptionTemplateModel template;
  final TextEditingController? watermarkTextCtrl;
  final TextEditingController? stampTextCtrl;
  final void Function(PrescriptionTemplateModel Function()) updateTemplate;
  final Future<void> Function(void Function(String base64)) onPickImage;
  final VoidCallback onStateChanged;

  const PrescriptionAssetsPanel({
    super.key,
    required this.template,
    this.watermarkTextCtrl,
    this.stampTextCtrl,
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
              Icon(Icons.security_outlined, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الصور والعلامة المائية والختم والتوقيع الرقمي',
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 1. Watermark section
          Row(
            children: [
              Expanded(
                child: Text(
                  'العلامة المائية في خلفية الروشتة:',
                  style: CustomAppFontStyle.medium12.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: template.watermarkEnabled,
                  activeThumbColor: colors.primary,
                  onChanged: (val) => updateTemplate(
                    () => template.copyWith(watermarkEnabled: val),
                  ),
                ),
              ),
            ],
          ),

          if (template.watermarkEnabled) ...[
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    children: [
                      PrescriptionChoiceChip(
                        label: 'رفع صورة علامة مائية',
                        selected: template.watermarkType == 'customImage',
                        onSelected: () => updateTemplate(
                          () => template.copyWith(watermarkType: 'customImage'),
                        ),
                      ),
                      PrescriptionChoiceChip(
                        label: 'شعار المركز',
                        selected: template.watermarkType == 'logo',
                        onSelected: () => updateTemplate(
                          () => template.copyWith(watermarkType: 'logo'),
                        ),
                      ),
                      PrescriptionChoiceChip(
                        label: 'نص مخصص',
                        selected: template.watermarkType == 'customText',
                        onSelected: () => updateTemplate(
                          () => template.copyWith(watermarkType: 'customText'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (template.watermarkType == 'customImage')
                  CustomPushButton(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor: colors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => onPickImage((b64) {
                      updateTemplate(
                        () => template.copyWith(watermarkImageBase64: b64),
                      );
                    }),
                    child: Text(
                      template.watermarkImageBase64 != null
                          ? 'تغيير الصورة'
                          : 'رفع صورة',
                      style: CustomAppFontStyle.medium11.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            if (template.watermarkType == 'customText' && watermarkTextCtrl != null) ...[
              const SizedBox(height: 6),
              CustomTextFormField(
                controller: watermarkTextCtrl,
                headerText: 'نص العلامة المائية المخصص',
                hintText: 'مثال: نسخة معتمدة - عيادتي',
                onChanged: (_) => onStateChanged(),
              ),
            ],
            const SizedBox(height: 6),

            // Watermark Opacity
            Row(
              children: [
                Text(
                  'شفافية العلامة (${(template.watermarkOpacity * 100).toInt()}%):',
                  style: CustomAppFontStyle.medium11.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: template.watermarkOpacity,
                    min: 0.05,
                    max: 0.40,
                    divisions: 35,
                    activeColor: colors.primary,
                    onChanged: (val) => updateTemplate(
                      () => template.copyWith(watermarkOpacity: val),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 8),

          // 2. Official Stamp & Doctor Signature Uploaders
          Row(
            children: [
              // Stamp Image Uploader
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
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
                            'ختم العيادة الرسمي (PNG):',
                            style: CustomAppFontStyle.medium11.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: template.includeOfficialStamp,
                              activeThumbColor: colors.primary,
                              onChanged: (val) => updateTemplate(
                                () => template.copyWith(
                                    includeOfficialStamp: val),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (template.includeOfficialStamp) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (template.stampImageBase64 != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: PrescriptionBase64Image(
                                  base64Str: template.stampImageBase64,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 15, color: AppColors.error),
                                onPressed: () => updateTemplate(
                                  () => template.copyWith(
                                      stampImageBase64: null),
                                ),
                              ),
                            ],
                            CustomPushButton(
                              height: 24,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              backgroundColor: colors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => onPickImage((b64) {
                                updateTemplate(
                                  () => template.copyWith(
                                      stampImageBase64: b64),
                                );
                              }),
                              child: Text(
                                template.stampImageBase64 != null
                                    ? 'تغيير'
                                    : 'رفع ختم PNG',
                                style: CustomAppFontStyle.medium10.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (stampTextCtrl != null) ...[
                          const SizedBox(height: 6),
                          CustomTextFormField(
                            controller: stampTextCtrl,
                            headerText: 'النص المطبوع داخل الختم',
                            hintText: 'مركز المهندسين - ختم معتمد',
                            onChanged: (_) => onStateChanged(),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Signature Image Uploader
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
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
                            'توقيع الطبيب المعتمد:',
                            style: CustomAppFontStyle.medium11.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: template.includeDoctorSignature,
                              activeThumbColor: colors.primary,
                              onChanged: (val) => updateTemplate(
                                () => template.copyWith(
                                    includeDoctorSignature: val),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (template.includeDoctorSignature) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (template.signatureImageBase64 != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: PrescriptionBase64Image(
                                  base64Str: template.signatureImageBase64,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 15, color: AppColors.error),
                                onPressed: () => updateTemplate(
                                  () => template.copyWith(
                                      signatureImageBase64: null),
                                ),
                              ),
                            ],
                            CustomPushButton(
                              height: 24,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              backgroundColor: colors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => onPickImage((b64) {
                                updateTemplate(
                                  () => template.copyWith(
                                      signatureImageBase64: b64),
                                );
                              }),
                              child: Text(
                                template.signatureImageBase64 != null
                                    ? 'تغيير'
                                    : 'رفع توقيع PNG',
                                style: CustomAppFontStyle.medium10.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
