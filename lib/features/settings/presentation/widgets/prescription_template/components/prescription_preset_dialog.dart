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
        title: 'النمط الملكي الفاخر (Royal Bilingual Dual Studio)',
        tag: 'تصميم هيدر وفوتر ملكي متناظر ثنائي اللغة',
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFF2563EB),
        description:
            'ترويسة ملكية متدرجة كحلي وأزرق ملكي مع فوتر متناسق، توزيع متناظر ثنائي اللغة (عربي / إنجليزي)، جدول علاجي تحليلي للأدوية وتنبيهات الأمراض المزمنة.',
        template: currentTemplate.copyWith(
          headerMode: 'customDesign',
          headerBackgroundStyle: 'gradientBlue',
          headerShapeStyle: 'roundedCard',
          headerAlignment: 'dual',
          headerLayout: 'dual',
          headerHeight: 115.0,
          footerMode: 'dynamicComposed',
          footerBackgroundStyle: 'gradientBlue',
          footerShapeStyle: 'roundedCard',
          footerHeight: 85.0,
          rxLayoutStyle: 'table',
          showVitalSigns: true,
          showChronicDiseasesAndAllergies: true,
          showClinicalDiagnosis: true,
          showFollowUpBox: true,
          followUpText:
              'إعادة الكشف والمتابعة خلال 7 إلى 10 أيام مع إحضار قياسات الضغط والسكر اليومية وأصل الروشتة',
          enableBackPage: true,
          backPageMode: 'instructions',
          backPageTitle: 'إرشادات دوائية وسريرية هامة للمريض',
          backPageSubtitle: 'الالتزام التام بالتعليمات يضمن سرعة التعافي وتفادي الآثار الجانبية',
          backPageDietAdvice:
              'شرب 2 إلى 3 لتر ماء يومياً، وتناول وجبات خفيفة متوازنة قبل أو بعد الأدوية حسب التعليمات.',
          backPageEmergencyNotes:
              'في حالات الطوارئ يرجى الاتصال فوراً بالخط الساخن أو التوجه لأقرب مركز طوارئ.',
          backPageFooterNotes:
              'مواعيد الاستشارة والمتابعة خلال 7 أيام من تاريخ الكشف مع إحضار الروشتة.',
        ),
      ),
      (
        title: 'النمط العصري المنحني (Modern Curved Wave Studio)',
        tag: 'ترويسة انسيابية مائلة مع لوجو بارز',
        icon: Icons.waves_rounded,
        color: const Color(0xFF0D9488),
        description:
            'مستوحى من التصاميم الطبية العصرية: ترويسة تركواز بانحناءة موجية ناعمة، شارة اللوجو البارزة جهة اليمين، فوتر بحواف انسيابية، وتفعيل أسئلة الأمان الدوائي للمريض في ظهر الروشتة.',
        template: currentTemplate.copyWith(
          headerMode: 'customDesign',
          headerBackgroundStyle: 'gradientTeal',
          headerShapeStyle: 'curvedWave',
          headerAlignment: 'rightLogo',
          headerLayout: 'rightLogo',
          headerHeight: 110.0,
          footerMode: 'dynamicComposed',
          footerBackgroundStyle: 'gradientTeal',
          footerShapeStyle: 'curvedWave',
          footerHeight: 80.0,
          rxLayoutStyle: 'lines',
          showVitalSigns: false,
          showChronicDiseasesAndAllergies: true,
          showClinicalDiagnosis: true,
          showFollowUpBox: true,
          followUpText:
              'المتابعة الدورية بعد 5 أيام لفحص قاع العين وضغط العين، أو فوراً عند حدوث أي طارئ',
          enableBackPage: true,
          backPageMode: 'faqs',
          backPageTitle: 'الأسئلة الأكثر شيوعاً والأمان الدوائي للمريض',
          backPageSubtitle: 'إجابات طبية معتمدة على استفسارات المرضى الأكثر تكراراً',
          backPageDietAdvice:
              'تجنب تناول المشروبات المنبهة أو الغازية بالقرب من مواعيد تناول الأدوية والقطرات.',
          backPageEmergencyNotes:
              'للاستفسارات العاجلة: تواصل مع فريق الاستشارات الطبية على مدار الساعة.',
          backPageFooterNotes:
              'العيادة متاحة للمتابعة الهاتفية يومياً من 9 صباحاً حتى 9 مساءً.',
        ),
      ),
      (
        title: 'قالب مجمع العيادات والمراكز الطبية (Polyclinic Multi-Specialty)',
        tag: 'ترويسة فخمة متعددة الفروع ودليل تخصصات',
        icon: Icons.apartment_rounded,
        color: const Color(0xFF0F172A),
        description:
            'مخصص للمراكز الطبية الكبرى: لوجو مجمع مركزي، ترويسة كحلية داكنة مع خطوط تأكيد مذهبة، فوتر كروت الفروع المتعددة وأرقام الخط الساخن، وظهور دليل أقسام وخدمات المركز في الظهر.',
        template: currentTemplate.copyWith(
          headerMode: 'customDesign',
          headerBackgroundStyle: 'gradientDark',
          headerShapeStyle: 'doubleLine',
          headerAlignment: 'centerLogo',
          headerLayout: 'centerLogo',
          headerHeight: 115.0,
          footerMode: 'dynamicComposed',
          footerBackgroundStyle: 'softCard',
          footerShapeStyle: 'flat',
          footerHeight: 90.0,
          rxLayoutStyle: 'lines',
          showVitalSigns: true,
          showChronicDiseasesAndAllergies: true,
          showClinicalDiagnosis: true,
          showFollowUpBox: true,
          enableBackPage: true,
          backPageMode: 'centerServices',
          backPageTitle: 'دليل الأقسام الطبية والخدمات التخصصية بالمركز',
          backPageSubtitle: 'رعاية صحية متكاملة تحت سقف واحد بأحدث التقنيات والمعايير الدولية',
          backPageDietAdvice:
              'قسم التغذية العلاجية يقدم استشارات مخصصة لإنقاص الوزن والسكري والرياضيين.',
          backPageEmergencyNotes:
              'وحدة الطوارئ واستقبال الحالات الحرجة تعمل على مدار 24 ساعة طوال أيام الأسبوع.',
          backPageFooterNotes:
              'نستقبلكم يومياً من الساعة 9:00 صباحاً حتى 11:00 مساءً — الجمعة من 1:00 ظهراً.',
        ),
      ),
      (
        title: 'قالب عيادات التجميل والجلدية والنخبة (Luxury Aesthetic Protocol)',
        tag: 'أناقة بنفسجية وبروتوكول عناية بالبشرة',
        icon: Icons.spa_outlined,
        color: const Color(0xFF9333EA),
        description:
            'ترويسة بنفسجية راقية مع لوجو أنيق، فوتر كروت بيضاء ناعمة، وتفعيل ظهر الروشتة لتعليمات روتين البشرة، واقي الشمس، وتجنب المقشرات قبل جلسات الليزر.',
        template: currentTemplate.copyWith(
          headerMode: 'customDesign',
          headerBackgroundStyle: 'gradientPurple',
          headerShapeStyle: 'roundedCard',
          headerAlignment: 'leftLogo',
          headerLayout: 'leftLogo',
          headerHeight: 110.0,
          footerMode: 'dynamicComposed',
          footerBackgroundStyle: 'white',
          footerShapeStyle: 'roundedCard',
          footerHeight: 80.0,
          rxLayoutStyle: 'lines',
          showVitalSigns: false,
          showChronicDiseasesAndAllergies: true,
          showClinicalDiagnosis: true,
          enableBackPage: true,
          backPageMode: 'dietProtocol',
          backPageTitle: 'بروتوكول العناية اليومية بالبشرة والتعليمات الوقائية',
          backPageSubtitle: 'دليل العناية للحفاظ على نتائج الجلسات العلاجية ونضارة البشرة',
          backPageDietAdvice:
              'شرب 2 إلى 3 لتر ماء يومياً مع الإكثار من الفواكه الغنية بمضادات الأكسدة وفيتامين C.',
          backPageEmergencyNotes:
              'في حالة حدوث تورم أو تحسس غير معتاد يرجى التواصل فوراً مع مسؤولة التجميل.',
          backPageFooterNotes:
              'يرجى الالتزام بموعد جلسة الرتوش أو الاستشارة المحددة بالروشتة.',
          showFollowUpBox: true,
          followUpText:
              'المتابعة بعد أسبوعين إلى 3 أسابيع لتقييم استجابة البشرة وجلسات العلاج المعتمدة',
        ),
      ),
      (
        title: 'الروشتة السريرية التحليلية (Clinical Matrix & Chronic Care)',
        tag: 'جدول دوائي متقدم وتوثيق قياسات وعلامات حيوية',
        icon: Icons.table_chart_outlined,
        color: const Color(0xFF0284C7),
        description:
            'ترويسة طبية نقية ذات حواف تأكيد أنيقة، جدول تحليلي كامل للدواء والجرعة والمدة، شريط علامات حيوية متكامل (الضغط، السكر، النبض، الحرارة، الوزن) وتوثيق استشاري معتمد.',
        template: currentTemplate.copyWith(
          headerMode: 'customDesign',
          headerBackgroundStyle: 'accentBorder',
          headerShapeStyle: 'flat',
          headerAlignment: 'dual',
          headerLayout: 'dual',
          headerHeight: 105.0,
          footerMode: 'dynamicComposed',
          footerBackgroundStyle: 'white',
          footerShapeStyle: 'doubleLine',
          footerHeight: 85.0,
          rxLayoutStyle: 'table',
          showVitalSigns: true,
          showChronicDiseasesAndAllergies: true,
          showClinicalDiagnosis: true,
          showFollowUpBox: true,
          followUpText:
              'المتابعة بعد أسبوع مع إحضار جدول قياسات الضغط اليومية ونتائج تحاليل الدم المطلوبة',
          enableBackPage: true,
          backPageMode: 'instructions',
          backPageTitle: 'بروتوكول متابعة الأمراض المزمنة ونمط الحياة الصحي',
          backPageSubtitle: 'إرشادات سريرية للمحافظة على استقرار الضغط والسكر وحماية الشرايين',
          backPageDietAdvice:
              'التقليل من ملح الطعام والأطعمة الغنية بالدهون المشبعة واستبدالها بالخضار والأسماك.',
          backPageEmergencyNotes:
              'عند ارتفاع الضغط أعلى من 180/110 أو الشعور بألم بالصدر يرجى التوجه فوراً للطوارئ.',
          backPageFooterNotes:
              'الاستشارة مجانية خلال 14 يوماً من تاريخ الكشف.',
        ),
      ),
      (
        title: 'ورق مطبوع مسبقاً (سادة عيادات ومطابع)',
        tag: 'الأكثر استخداماً للروشتات المطبوعة بالمطبعة',
        icon: Icons.print_disabled_outlined,
        color: const Color(0xFFF97316),
        description:
            'مخصص للورق المطبوع مسبقاً في المطبعة: تفريغ علوي 45 مم للترويسة وسفلي 30 مم للعناوين مع إخفاء طباعة العناوين لمنع تداخل النصوص مع الورق المطبوع.',
        template: currentTemplate.copyWith(
          headerMode: 'preprinted',
          footerMode: 'preprinted',
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
          enableBackPage: false,
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
