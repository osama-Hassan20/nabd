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

            // Mode Selection: Instructions, FAQs, Center Services, Diet
            Text(
              'نوع ومحتوى ظهر الروشتة (Back Page Mode):',
              style: CustomAppFontStyle.semiBold12.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildModeChip(
                  context: context,
                  label: 'تعليمات طبية للمريض',
                  icon: Icons.checklist_rtl_rounded,
                  mode: 'instructions',
                ),
                _buildModeChip(
                  context: context,
                  label: 'أسئلة وإجابات شائعة (FAQs)',
                  icon: Icons.quiz_outlined,
                  mode: 'faqs',
                ),
                _buildModeChip(
                  context: context,
                  label: 'دليل تخصصات وخدمات المركز',
                  icon: Icons.local_hospital_outlined,
                  mode: 'centerServices',
                ),
                _buildModeChip(
                  context: context,
                  label: 'بروتوكول عناية وتغذية',
                  icon: Icons.spa_outlined,
                  mode: 'dietProtocol',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Preset Buttons
            Text(
              'قوالب سريرية جاهزة لظهر الروشتة (تطبيق فوري):',
              style: CustomAppFontStyle.medium11.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPresetChip(
                  context: context,
                  label: 'إرشادات دوائية وسريرية',
                  icon: Icons.medication_outlined,
                  mode: 'instructions',
                  title: 'إرشادات دوائية وسريرية هامة للمريض',
                  subtitle: 'الالتزام التام بالتعليمات يضمن سرعة التعافي وتفادي الآثار الجانبية',
                  diet: 'شرب 2 إلى 3 لتر ماء يومياً، وتناول وجبات خفيفة متوازنة قبل أو بعد الأدوية حسب التعليمات.',
                  emergency: 'في حالات الطوارئ يرجى الاتصال فوراً بالخط الساخن أو التوجه لأقرب مركز طوارئ.',
                  footer: 'مواعيد الاستشارة والمتابعة خلال 7 أيام من تاريخ الكشف مع إحضار الروشتة.',
                  items: [
                    'الالتزام الدقيق بمواعيد وجرعات الأدوية دون زيادة أو نقصان من تلقاء نفسك.',
                    'عدم التوقف عن تناول المضادات الحيوية حتى انتهاء الكورس العلاجي بالكامل.',
                    'حفظ الأدوية في درجة حرارة الغرفة (أقل من 25 درجة مئوية) وبعيداً عن متناول الأطفال.',
                    'إبلاغ الطبيب المعالج فوراً بأي حساسية أو أعراض غير معتادة تظهر بعد تناول العلاج.',
                    'مراجعة العيادة لإجراء التحاليل ومتابعة قياسات الضغط والسكر في الموعد المحدد.',
                  ],
                ),
                _buildPresetChip(
                  context: context,
                  label: 'أسئلة وأجوبة شائعة (FAQs)',
                  icon: Icons.live_help_outlined,
                  mode: 'faqs',
                  title: 'الأسئلة الأكثر شيوعاً والأمان الدوائي للمريض',
                  subtitle: 'إجابات طبية معتمدة على استفسارات المرضى الأكثر تكراراً',
                  diet: 'تجنب تناول المشروبات المنبهة أو الغازية بالقرب من مواعيد تناول الأدوية.',
                  emergency: 'للاستفسارات العاجلة: تواصل مع فريق التمريض والاستشارات على مدار الساعة.',
                  footer: 'العيادة متاحة للمتابعة الهاتفية يومياً من 9 صباحاً حتى 9 مساءً.',
                  items: [
                    'س: ماذا أفعل إذا نسيت جرعة من الدواء؟ | ج: تناول الجرعة فور تذكرها ما لم يقترب موعد الجرعة التالية، ولا تضاعف الجرعة نهائياً.',
                    'س: هل يمكن تناول المسكنات عند الحاجة فقط؟ | ج: نعم، المسكنات تؤخذ عند اللزوم وبجرعات محسوبة وبعد الأكل لتجنب تهيج المعدة.',
                    'س: متى يمكنني إيقاف أدوية الضغط أو السكر؟ | ج: أدوية الأمراض المزمنة لا توقف إلا بقرار الطبيب المعالج بعد الفحوصات.',
                    'س: هل يؤثر تناول الفيتامينات مع الأدوية؟ | ج: يفضل ترك فاصل ساعتين على الأقل بين مكملات الكالسيوم أو الحديد والمضادات الحيوية.',
                    'س: كيف أتأكد من استجابة العلاج؟ | ج: بمتابعة تحسن الأعراض وتدوين أي ملاحظات لعرضها في زيارة الاستشارة.',
                  ],
                ),
                _buildPresetChip(
                  context: context,
                  label: 'دليل تخصصات وخدمات المركز',
                  icon: Icons.domain_rounded,
                  mode: 'centerServices',
                  title: 'دليل الأقسام الطبية والخدمات التخصصية بالمركز',
                  subtitle: 'رعاية صحية متكاملة تحت سقف واحد بأحدث التقنيات والمعايير الدولية',
                  diet: 'قسم التغذية العلاجية يقدم استشارات مخصصة لإنقاص الوزن والسكري والرياضيين.',
                  emergency: 'وحدة الطوارئ واستقبال الحالات الحرجة تعمل على مدار 24 ساعة طوال أيام الأسبوع.',
                  footer: 'نستقبلكم يومياً من الساعة 9:00 صباحاً حتى 11:00 مساءً — الجمعة من 1:00 ظهراً.',
                  items: [
                    'عيادة الباطنة والقلب والسكر: فحوصات شاملة وتخطيط القلب ومتابعة الأمراض المزمنة.',
                    'عيادة طب وجراحة العيون: فحص قاع العين، قياس ضغط العين، وتصحيح الإبصار بالليزر.',
                    'عيادة الجلدية والتجميل والليزر: أحدث أجهزة إزالة الشعر وعلاج البشرة ونضارة الوجه.',
                    'عيادة طب وجراحة الأسنان: زراعة وتقويم الأسنان والتركيبات وتبييض الأسنان بالليزر.',
                    'وحدة الفحوصات والتحاليل المعملية: سحب العينات وتوفير نتائج دقيقة بأحدث الأجهزة الآلية.',
                    'وحدة الأشعة التشخيصية والموجات الصوتية: سونار ودوبلر وأشعة رقمية فورية.',
                  ],
                ),
                _buildPresetChip(
                  context: context,
                  label: 'روتين البشرة والتجميل والليزر',
                  icon: Icons.face_retouching_natural_outlined,
                  mode: 'dietProtocol',
                  title: 'بروتوكول العناية اليومية بالبشرة والتعليمات الوقائية',
                  subtitle: 'دليل العناية للحفاظ على نتائج الجلسات العلاجية ونضارة البشرة',
                  diet: 'شرب 2 إلى 3 لتر ماء يومياً مع الإكثار من الفواكه الغنية بمضادات الأكسدة وفيتامين C.',
                  emergency: 'في حالة حدوث تورم أو تحسس غير معتاد يرجى التواصل فوراً مع مسؤولة التجميل.',
                  footer: 'يرجى الالتزام بموعد جلسة الرتوش أو الاستشارة المحددة بالروشتة.',
                  items: [
                    'استخدام واقي الشمس الطبي SPF 50+ يومياً صباحاً وتجديده كل ساعتين عند التعرض للضوء.',
                    'ترطيب البشرة بالكريم الموصوف مرتين إلى ثلاث مرات يومياً لترميم الحاجز الجلدي.',
                    'التوقف التام عن استخدام أي مقشرات أحماض أو ريتينول قبل جلسات الليزر بـ 5 أيام.',
                    'تجنب استخدام الماء الساخن جداً أو حمامات البخار والساونا لمدة 48 ساعة بعد الجلسة.',
                    'عدم لمس أو تقشير أي قشور سطحية باليد لتجنب حدوث أي تصبغات جلدية.',
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

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

  Widget _buildModeChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String mode,
  }) {
    final colors = context.themeColors;
    final isSelected = template.backPageMode == mode;
    return InkWell(
      onTap: () {
        updateTemplate(() => template.copyWith(backPageMode: mode));
        onStateChanged();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryLight : colors.surfaceLevel1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colors.primary : colors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: CustomAppFontStyle.medium11.copyWith(
                color: isSelected ? colors.primary : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String mode,
    required String title,
    required String subtitle,
    required String diet,
    required String emergency,
    required String footer,
    required List<String> items,
  }) {
    final colors = context.themeColors;
    return InkWell(
      onTap: () {
        backPageTitleCtrl.text = title;
        backPageDietCtrl.text = diet;
        backPageEmergencyCtrl.text = emergency;
        backPageFooterCtrl.text = footer;
        onSyncBackInstructions(items);
        updateTemplate(
          () => template.copyWith(
            backPageMode: mode,
            backPageTitle: title,
            backPageSubtitle: subtitle,
            backPageDietAdvice: diet,
            backPageEmergencyNotes: emergency,
            backPageFooterNotes: footer,
            backPageInstructions: items,
          ),
        );
        onStateChanged();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surfaceLevel1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: CustomAppFontStyle.medium11.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
