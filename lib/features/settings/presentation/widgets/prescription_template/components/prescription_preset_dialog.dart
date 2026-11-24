import 'package:flutter/material.dart';
import '../../../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../../../shared/widgets/custom_toast.dart';
import '../../../../data/models/prescription_template_model.dart';

class ClinicSpecialtyPresetsDialog extends StatelessWidget {
  final PrescriptionTemplateModel currentTemplate;
  final ValueChanged<PrescriptionTemplateModel> onPresetSelected;

  ClinicSpecialtyPresetsDialog({
    super.key,
    required this.currentTemplate,
    ValueChanged<PrescriptionTemplateModel>? onPresetSelected,
    ValueChanged<PrescriptionTemplateModel>? onApplyPreset,
  }) : onPresetSelected = (onPresetSelected ?? onApplyPreset)!;

  static Future<void> show({
    required BuildContext context,
    required PrescriptionTemplateModel currentTemplate,
    ValueChanged<PrescriptionTemplateModel>? onPresetSelected,
    ValueChanged<PrescriptionTemplateModel>? onApplyPreset,
  }) {
    return showDialog(
      context: context,
      builder: (dialogCtx) => ClinicSpecialtyPresetsDialog(
        currentTemplate: currentTemplate,
        onPresetSelected: onPresetSelected ?? onApplyPreset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    final presets = [
      (
        title: 'ورق مطبوع مسبقاً (سادة عيادات ومطابع)',
        tag: 'الأكثر استخداماً للروشتات الجاهزة',
        icon: Icons.print_disabled_outlined,
        color: const Color(0xFFF97316),
        description:
            'مخصص للورق المطبوع مسبقاً في المطبعة: تفريغ علوي 45 مم للترويسة وسفلي 30 مم للعناوين مع إخفاء طباعة العناوين لمنع تداخل النصوص.',
        template: currentTemplate.copyWith(
          headerMode: 'preprinted',
          preprintedHeaderHeight: 45.0,
          preprintedFooterHeight: 30.0,
          hideFooterOnPreprinted: true,
          headerMarginTop: 0.0,
          headerMarginBottom: 6.0,
          bodyMarginTop: 6.0,
          bodyMarginBottom: 6.0,
          footerMarginTop: 4.0,
          footerMarginBottom: 0.0,
          rxLayoutStyle: 'lines',
          showChronicDiseasesAndAllergies: true,
          showVitalSigns: true,
        ),
      ),
      (
        title: 'عيادة الباطنة والقلب والأمراض المزمنة',
        tag: 'جدول علاجي منظم للأدوية والضغط',
        icon: Icons.favorite_outline_rounded,
        color: const Color(0xFF2563EB),
        description:
            'ترويسة زرقاء ملكية ثنائية اللغة، جدول أدوية سريري منظم بخانات الجرعات والمدة، إبراز الضغط والسكر وتنبيهات الحساسية.',
        template: currentTemplate.copyWith(
          headerMode: 'customDesign',
          headerBackgroundStyle: 'gradientBlue',
          headerAlignment: 'bilingual',
          headerLayout: 'bilingual',
          rxLayoutStyle: 'table',
          showVitalSigns: true,
          showChronicDiseasesAndAllergies: true,
          showClinicalDiagnosis: true,
          showFollowUpBox: true,
          followUpText:
              'إعادة الكشف والمتابعة خلال 7 إلى 10 أيام مع إحضار قياسات الضغط والسكر اليومية',
        ),
      ),
      (
        title: 'عيادة طب وجراحة العيون',
        tag: 'قطرات ومراهم سريرية دقيقة',
        icon: Icons.visibility_outlined,
        color: const Color(0xFF0D9488),
        description:
            'ترويسة تركواز، أسطر سريرية متباعدة ومريحة للعين، تعليمات القطرات والمراهم وتوقيت الجرعات لكل عين، وملاحظات فحص قاع العين.',
        template: currentTemplate.copyWith(
          headerMode: 'customDesign',
          headerBackgroundStyle: 'gradientTeal',
          headerAlignment: 'bilingual',
          headerLayout: 'bilingual',
          rxLayoutStyle: 'lines',
          showVitalSigns: false,
          showChronicDiseasesAndAllergies: true,
          showClinicalDiagnosis: true,
          showFollowUpBox: true,
          followUpText:
              'المتابعة بعد 5 أيام لفحص ضغط وقاع العين، أو فوراً عند حدوث احمرار أو ألم مفاجئ',
        ),
      ),
      (
        title: 'عيادة الأمراض الجلدية والتجميل والليزر',
        tag: 'تصميم أنيق مع ظهر روشتة للعناية',
        icon: Icons.spa_outlined,
        color: const Color(0xFF9333EA),
        description:
            'ترويسة بنفسجية راقية، تفعيل ظهر الروشتة لتعليمات روتين البشرة، واقي الشمس، وتجنب المقشرات قبل جلسات الليزر.',
        template: currentTemplate.copyWith(
          headerMode: 'customDesign',
          headerBackgroundStyle: 'gradientPurple',
          headerAlignment: 'bilingual',
          headerLayout: 'bilingual',
          rxLayoutStyle: 'lines',
          showVitalSigns: false,
          showChronicDiseasesAndAllergies: true,
          enableBackPage: true,
          backPageTitle: 'بروتوكول العناية اليومية بالبشرة والتعليمات الوقائية',
          backPageDietAdvice:
              'شرب 2-3 لتر ماء يومياً وتناول الخضروات الورقية ومضادات الأكسدة',
          backPageInstructions: [
            'الالتزام بواقي الشمس SPF 50+ وتجديده كل ساعتين خلال فترات النهار',
            'ترطيب البشرة بالكريم الموصوف مرتين يومياً صباحاً ومساءً',
            'التوقف عن المقشرات والأحماض قبل جلسات الليزر بـ 5 أيام على الأقل',
          ],
          showFollowUpBox: true,
          followUpText:
              'المتابعة بعد أسبوعين إلى 3 أسابيع لتقييم استجابة البشرة وجلسات العلاج',
        ),
      ),
      (
        title: 'روشتة مدمجة سريعة مقاس A5 (نصف صفحة)',
        tag: 'موفر للورق وسريع الطباعة',
        icon: Icons.crop_portrait_rounded,
        color: const Color(0xFF16A34A),
        description:
            'قالب مصغر مقاس A5 (148x210mm) مناسب للطابعات المكتبية السريعة والعيادات المزدحمة بهوامش محكمة ومدمجة.',
        template: currentTemplate.copyWith(
          defaultPaperSize: 'a5',
          headerMode: 'customDesign',
          headerHeight: 85.0,
          footerHeight: 45.0,
          headerMarginTop: 4.0,
          headerMarginBottom: 4.0,
          bodyMarginTop: 4.0,
          bodyMarginBottom: 4.0,
          footerMarginTop: 4.0,
          footerMarginBottom: 4.0,
          rxLayoutStyle: 'lines',
          showVitalSigns: true,
        ),
      ),
    ];

    return Dialog(
      backgroundColor: colors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.borderSubtle),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome_rounded,
                        size: 22, color: colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'قوالب الروشتات الجاهزة حسب التخصص الطبي',
                          style: CustomAppFontStyle.bold16.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'اختر قالباً سريرياً جاهزاً ليتم تطبيقه فوراً بضغطة زر مع الحفاظ على إمكانية التعديل',
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: colors.borderSubtle),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: presets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, idx) {
                    final p = presets[idx];
                    return InkWell(
                      onTap: () {
                        onPresetSelected(p.template);
                        Navigator.of(context).pop();
                        CustomToast(
                          context: context,
                          header:
                              'تم تطبيق قالب ${p.title} بنجاح، يمكنك التعديل والحفظ',
                        ).showTopToast();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceLevel1,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: p.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(p.icon, color: p.color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        p.title,
                                        style: CustomAppFontStyle.semiBold14
                                            .copyWith(
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: p.color.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                                p.color.withValues(alpha: 0.3),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          p.tag,
                                          style: CustomAppFontStyle.medium10
                                              .copyWith(
                                            color: p.color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.description,
                                    style:
                                        CustomAppFontStyle.regular12.copyWith(
                                      color: colors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            CustomPushButton(
                              height: 32,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              backgroundColor: colors.surfaceLevel2,
                              boxBorder: Border.all(
                                  color: p.color.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                onPresetSelected(p.template);
                                Navigator.of(context).pop();
                                CustomToast(
                                  context: context,
                                  header:
                                      'تم تطبيق قالب ${p.title} بنجاح، يمكنك التعديل والحفظ',
                                ).showTopToast();
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, size: 14, color: p.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    'تطبيق',
                                    style:
                                        CustomAppFontStyle.semiBold11.copyWith(
                                      color: p.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
