import 'package:flutter/material.dart';

import '../../../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../../../core/utils/theme/app_colors.dart';
import '../../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../../shared/widgets/custom_container.dart';
import '../../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../data/models/prescription_template_model.dart';


class PrescriptionBackPagePanel extends StatelessWidget {
  final PrescriptionTemplateModel template;
  final TextEditingController backPageTitleCtrl;
  final List<TextEditingController> backInstructionsCtrls;
  final TextEditingController backPageDietCtrl;
  final TextEditingController backPageEmergencyCtrl;
  final TextEditingController backPageFooterCtrl;
  final void Function(PrescriptionTemplateModel Function()) updateTemplate;
  final Future<void> Function(void Function(String base64)) onPickImage;
  final void Function(List<String>) onSyncBackInstructions;
  final ValueChanged<int>? onFaceChanged;
  final VoidCallback onStateChanged;

  const PrescriptionBackPagePanel({
    super.key,
    required this.template,
    required this.backPageTitleCtrl,
    required this.backInstructionsCtrls,
    required this.backPageDietCtrl,
    required this.backPageEmergencyCtrl,
    required this.backPageFooterCtrl,
    required this.updateTemplate,
    required this.onPickImage,
    required this.onSyncBackInstructions,
    this.onFaceChanged,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return CustomContainer(
      backGroundColor: colors.cardBackground,
      border: Border.all(
        color: template.enableBackPage
            ? colors.primary
            : colors.borderSubtle,
        width: template.enableBackPage ? 1.5 : 1,
      ),
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flip_to_back_rounded,
                  size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تصميم ظهر الروشتة (Back Page Guidelines)',
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: template.enableBackPage,
                  activeThumbColor: colors.primary,
                  onChanged: (val) {
                    updateTemplate(
                      () => template.copyWith(enableBackPage: val),
                    );
                    if (val && onFaceChanged != null) {
                      onFaceChanged!(1);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'تفعيل طباعة صفحة ثانية في ظهر الروشتة مخصصة لإرشادات المريض، الحمية الغذائية، وأرقام الطوارئ.',
            style: CustomAppFontStyle.regular12.copyWith(
              color: colors.textSecondary,
            ),
          ),

          if (template.enableBackPage) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: colors.borderSubtle),
            const SizedBox(height: 10),

            // Back Header Banner uploader
            Row(
              children: [
                Expanded(
                  child: CustomTextFormField(
                    controller: backPageTitleCtrl,
                    headerText: 'عنوان ظهر الروشتة الرئيسي',
                    hintText: 'إرشادات وتعليمات طبية هامة للمريض',
                    onChanged: (_) => onStateChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                CustomPushButton(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  backgroundColor: colors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => onPickImage((b64) {
                    updateTemplate(
                      () => template.copyWith(
                          backPageHeaderBannerBase64: b64),
                    );
                  }),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        template.backPageHeaderBannerBase64 != null
                            ? 'تغيير بانر الظهر'
                            : 'رفع بانر لظهر الروشتة',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quick Preset Buttons for instructions
            Text(
              'قوالب تعليمات جاهزة وسريعة:',
              style: CustomAppFontStyle.medium11.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildPresetButton(context, 'باطنة وتغذية', [
                  'الالتزام التام بالجرعات المقررة ومواعيد تناول الدواء قبل أو بعد الأكل بدقة.',
                  'الابتعاد عن الأطعمة الدسمة والمسبكة والوجبات السريعة والمشروبات الغازية.',
                  'قياس الضغط والسكر دورياً وتسجيل القراءات في دفتر المتابعة الخاص بك.',
                  'شرب ما لا يقل عن 2 إلى 3 لتر ماء يومياً لتعزيز وظائف الكلى.',
                  'مراجعة العيادة فوراً عند الشعور بأي دوخة شديدة أو عدم انتظام ضربات القلب.',
                ]),
                _buildPresetButton(context, 'عيون وبصريات', [
                  'غسل اليدين جيداً بالماء والصابون قبل وضع أي قطرة أو مرهم للعين.',
                  'ترك فاصل زمني 5 دقائق على الأقل بين كل قطرة والأخرى لضمان الامتصاص.',
                  'تجنب فرك العينين نهائياً والابتعاد عن مصادر الغبار والأتربة والدخان.',
                  'ارتداء النظارة الشمسية الطبية عند الخروج نهاراً في الضوء الساطع.',
                  'الالتزام بموعد فحص قاع العين وضغط العين الدوري المذكور بالروشتة.',
                ]),
                _buildPresetButton(context, 'جلدية وتجميل', [
                  'استخدام واقي الشمس الموصوف قبل الخروج بنصف ساعة وتجديده كل ساعتين.',
                  'تجنب استخدام أي مقشرات كيميائية أو صابون عطري على البشرة المعالجة.',
                  'ترطيب البشرة بالكريم الموصوف مرتين إلى ثلاث مرات يومياً بانتظام.',
                  'تجنب حك أو لمس المناطق المعالجة بالليزر أو التقشير باليد إطلاقاً.',
                  'شرب كميات وافرة من الماء وتجنب التعرض لحرارة الأفران والساونا.',
                ]),
                _buildPresetButton(context, 'ما بعد الجراحة', [
                  'الالتزام التام بتغيير الغيار الطبي المعقم في المواعيد المحددة.',
                  'تجنب حمل الأوزان الثقيلة أو بذل أي مجهود بدني عنيف لمدة أسبوعين.',
                  'الحفاظ على نظافة وجفاف الجرح تماماً وعدم ملامسة الماء له حتى إزالة الغرز.',
                  'تناول مسكنات الألم ومضادات الالتهاب الموصوفة بعد الأكل بانتظام.',
                  'التواصل الفوري مع الطبيب في حالة حدوث نزيف أو ارتفاع مفاجئ في درجة الحرارة.',
                ]),
              ],
            ),
            const SizedBox(height: 10),

            // Patient Instructions Items Editor
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'نقاط التعليمات الطبية (يمكن إضافة وتعديل أي عدد):',
                  style: CustomAppFontStyle.semiBold12.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                CustomPushButton(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: colors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    backInstructionsCtrls.add(TextEditingController());
                    onStateChanged();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'إضافة بند',
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

            ...backInstructionsCtrls.asMap().entries.map((entry) {
              final idx = entry.key;
              final ctrl = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: colors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${idx + 1}',
                        style: CustomAppFontStyle.bold11.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomTextFormField(
                        controller: ctrl,
                        hintText: 'اكتب نص التوجيه أو الإرشاد رقم ${idx + 1}',
                        onChanged: (_) => onStateChanged(),
                      ),
                    ),
                    if (backInstructionsCtrls.length > 1) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: AppColors.error),
                        onPressed: () {
                          backInstructionsCtrls.removeAt(idx).dispose();
                          onStateChanged();
                        },
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),

            // Diet advice
            CustomTextFormField(
              controller: backPageDietCtrl,
              headerText: 'نصائح التغذية والحمية الغذائية',
              hintText: 'تجنب الأطعمة الدسمة، وتناول الخضروات والفواكه...',
              onChanged: (_) => onStateChanged(),
            ),
            const SizedBox(height: 8),

            // Emergency & working hours
            Row(
              children: [
                Expanded(
                  child: CustomTextFormField(
                    controller: backPageEmergencyCtrl,
                    headerText: 'تعليمات الطوارئ والمتابعة',
                    hintText: 'الاتصال بالخط الساخن أو الطوارئ...',
                    onChanged: (_) => onStateChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextFormField(
                    controller: backPageFooterCtrl,
                    headerText: 'تذييل ظهر الروشتة ومواعيد العمل',
                    hintText: 'يومياً من 10 ص حتى 10 م عدا الجمعة...',
                    onChanged: (_) => onStateChanged(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetButton(
      BuildContext context, String label, List<String> presetItems) {
    final colors = context.themeColors;
    return InkWell(
      onTap: () {
        onSyncBackInstructions(presetItems);
        onStateChanged();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surfaceLevel1,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Text(
          label,
          style: CustomAppFontStyle.medium11.copyWith(
            color: colors.primary,
          ),
        ),
      ),
    );
  }
}
