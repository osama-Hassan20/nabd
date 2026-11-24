import 'package:flutter/material.dart';
import '../../../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../../../core/utils/theme/app_icons.dart';
import '../../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../../shared/widgets/custom_asset_image.dart';
import '../../../../data/models/prescription_template_model.dart';
import 'prescription_ui_helpers.dart';

class PrescriptionLivePreview extends StatelessWidget {
  final PrescriptionTemplateModel template;
  final int previewFace;
  final ValueChanged<int> onFaceChanged;
  final double zoomScale;
  final ValueChanged<double> onZoomChanged;
  final bool showMarginGuides;
  final ValueChanged<bool> onToggleMarginGuides;
  final bool isGrayscalePreview;
  final ValueChanged<bool> onToggleGrayscale;
  final ValueChanged<String> onPaperSizeChanged;

  final TextEditingController doctorNameCtrl;
  final TextEditingController englishDoctorNameCtrl;
  final TextEditingController doctorTitleCtrl;
  final TextEditingController englishDoctorTitleCtrl;
  final TextEditingController clinicNameCtrl;
  final TextEditingController medicalLicenseCtrl;
  final TextEditingController ministryLicenseCtrl;
  final List<TextEditingController> addressCtrls;
  final List<TextEditingController> phoneCtrls;
  final TextEditingController watermarkTextCtrl;

  final TextEditingController backPageTitleCtrl;
  final List<TextEditingController> backInstructionsCtrls;
  final TextEditingController backPageDietCtrl;
  final TextEditingController backPageEmergencyCtrl;
  final TextEditingController backPageFooterCtrl;

  const PrescriptionLivePreview({
    super.key,
    required this.template,
    required this.previewFace,
    required this.onFaceChanged,
    required this.zoomScale,
    required this.onZoomChanged,
    required this.showMarginGuides,
    required this.onToggleMarginGuides,
    required this.isGrayscalePreview,
    required this.onToggleGrayscale,
    required this.onPaperSizeChanged,
    required this.doctorNameCtrl,
    required this.englishDoctorNameCtrl,
    required this.doctorTitleCtrl,
    required this.englishDoctorTitleCtrl,
    required this.clinicNameCtrl,
    required this.medicalLicenseCtrl,
    required this.ministryLicenseCtrl,
    required this.addressCtrls,
    required this.phoneCtrls,
    required this.watermarkTextCtrl,
    required this.backPageTitleCtrl,
    required this.backInstructionsCtrls,
    required this.backPageDietCtrl,
    required this.backPageEmergencyCtrl,
    required this.backPageFooterCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: [
              // Face Switcher: وجه الروشتة (Front) vs ظهر الروشتة (Back)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colors.surfaceLevel1,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => onFaceChanged(0),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: previewFace == 0
                              ? colors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'وجه الروشتة (Front)',
                          style: CustomAppFontStyle.semiBold11.copyWith(
                            color: previewFace == 0
                                ? Colors.white
                                : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => onFaceChanged(1),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: previewFace == 1
                              ? colors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ظهر الروشتة (Back)',
                              style: CustomAppFontStyle.semiBold11.copyWith(
                                color: previewFace == 1
                                    ? Colors.white
                                    : colors.textSecondary,
                              ),
                            ),
                            if (template.enableBackPage) ...[
                              const SizedBox(width: 4),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Zoom selector
              IconButton(
                icon: const Icon(Icons.zoom_out_rounded, size: 16),
                tooltip: 'تصغير',
                color: colors.textSecondary,
                onPressed: zoomScale > 0.5
                    ? () => onZoomChanged((zoomScale - 0.05).clamp(0.5, 1.3))
                    : null,
              ),
              Text(
                '${(zoomScale * 100).toInt()}%',
                style: CustomAppFontStyle.medium11.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in_rounded, size: 16),
                tooltip: 'تكبير',
                color: colors.textSecondary,
                onPressed: zoomScale < 1.3
                    ? () => onZoomChanged((zoomScale + 0.05).clamp(0.5, 1.3))
                    : null,
              ),
              const SizedBox(width: 4),

              // Margins guide toggle
              InkWell(
                onTap: () => onToggleMarginGuides(!showMarginGuides),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: showMarginGuides
                        ? colors.primaryLight
                        : colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: showMarginGuides
                          ? colors.primary
                          : colors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.crop_free_rounded,
                          size: 13,
                          color: showMarginGuides
                              ? colors.primary
                              : colors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        'هوامش',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: showMarginGuides
                              ? colors.primary
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // B&W Laser toggle
              InkWell(
                onTap: () => onToggleGrayscale(!isGrayscalePreview),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isGrayscalePreview
                        ? colors.surfaceLevel2
                        : colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isGrayscalePreview
                          ? colors.textPrimary
                          : colors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tonality_rounded,
                          size: 13,
                          color: isGrayscalePreview
                              ? colors.textPrimary
                              : colors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        'أبيض/أسود',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: isGrayscalePreview
                              ? colors.textPrimary
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Preview Sheet Container
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceLevel1,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(10)),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(10)),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Center(
                  child: Transform.scale(
                    scale: zoomScale,
                    alignment: Alignment.topCenter,
                    child: ColorFiltered(
                      colorFilter: isGrayscalePreview
                          ? const ColorFilter.matrix([
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0,      0,      0,      1, 0,
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent, BlendMode.multiply),
                      child: previewFace == 0
                          ? _buildPhysicalA4Sheet(context, colors)
                          : _buildPhysicalA4BackSheet(context, colors),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        _buildPaperFormatSelector(context, colors),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PHYSICAL A4 SHEET EMULATION (FRONT FACE)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildPhysicalA4Sheet(BuildContext context, AppThemeColors colors) {
    final effectiveDoctorName = doctorNameCtrl.text.trim().isEmpty
        ? template.doctorDisplayName
        : doctorNameCtrl.text.trim();
    final effectiveClinicName = clinicNameCtrl.text.trim().isEmpty
        ? template.clinicDisplayName
        : clinicNameCtrl.text.trim();
    final effectiveDoctorTitle = doctorTitleCtrl.text.trim().isEmpty
        ? template.doctorTitle
        : doctorTitleCtrl.text.trim();
    final effectiveEnglishName = englishDoctorNameCtrl.text.trim().isEmpty
        ? template.englishDoctorName
        : englishDoctorNameCtrl.text.trim();
    final effectiveEnglishTitle = englishDoctorTitleCtrl.text.trim().isEmpty
        ? template.englishDoctorTitle
        : englishDoctorTitleCtrl.text.trim();
    final effectiveMedicalLicense = medicalLicenseCtrl.text.trim().isEmpty
        ? template.medicalLicenseNumber
        : medicalLicenseCtrl.text.trim();
    final effectiveMinistryLicense = ministryLicenseCtrl.text.trim().isEmpty
        ? template.ministryLicenseNumber
        : ministryLicenseCtrl.text.trim();

    final activeAddrs = addressCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final displayAddresses =
        activeAddrs.isEmpty ? template.addresses : activeAddrs;

    final activePhones = phoneCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final displayPhones =
        activePhones.isEmpty ? template.phoneNumbers : activePhones;

    return Container(
      width: 480,
      constraints: const BoxConstraints(minHeight: 680),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: showMarginGuides
            ? Border.all(color: Colors.red.shade300, width: 1.5)
            : Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // ── Watermark Layer (Logo, Uploaded Image, or Text) ────────
          if (template.watermarkEnabled)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: template.watermarkOpacity.clamp(0.04, 0.45),
                    child: template.watermarkType == 'customImage' &&
                            template.watermarkImageBase64 != null
                        ? PrescriptionBase64Image(
                            base64Str: template.watermarkImageBase64,
                            width: 220,
                            height: 220,
                            fit: BoxFit.contain,
                          )
                        : template.watermarkType == 'customText'
                            ? Transform.rotate(
                                angle: -0.4,
                                child: Text(
                                  watermarkTextCtrl.text.trim().isEmpty
                                      ? template.watermarkCustomText
                                      : watermarkTextCtrl.text.trim(),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE0583E),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : template.logoImageBase64 != null
                                ? PrescriptionBase64Image(
                                    base64Str: template.logoImageBase64,
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.contain,
                                  )
                                : const CustomAssetImage(
                                    path: AppIcons.service,
                                    width: 160,
                                    height: 160,
                                    color: Color(0xFFE0583E),
                                  ),
                  ),
                ),
              ),
            ),

          // ── Content Layer (Independent Header, Body, and Footer) ───
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Dynamic Header Area (Independent 4-way margins & height)
              Padding(
                padding: EdgeInsets.only(
                  top: template.headerMarginTop * 0.75,
                  bottom: template.headerMarginBottom * 0.75,
                  right: template.headerMarginRight * 0.75,
                  left: template.headerMarginLeft * 0.75,
                ),
                child: SizedBox(
                  height: template.headerHeight > 0
                      ? template.headerHeight
                      : null,
                  child: _buildDynamicHeaderWidget(
                    clinicName: effectiveClinicName,
                    doctorName: effectiveDoctorName,
                    doctorTitle: effectiveDoctorTitle,
                    englishName: effectiveEnglishName,
                    englishTitle: effectiveEnglishTitle,
                    ministryLicense: effectiveMinistryLicense,
                    medicalLicense: effectiveMedicalLicense,
                  ),
                ),
              ),

              const Divider(
                  height: 10, thickness: 1.5, color: Color(0xFFE2E8F0)),

              // 2. Rx Body Area (Independent 4-way margins)
              Padding(
                padding: EdgeInsets.only(
                  top: template.bodyMarginTop * 0.75,
                  bottom: template.bodyMarginBottom * 0.75,
                  right: template.bodyMarginRight * 0.75,
                  left: template.bodyMarginLeft * 0.75,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Patient Meta Box
                    _buildA4PatientBox(),
                    const SizedBox(height: 6),

                    // Clinical Alert: Chronic Diseases & Allergies
                    if (template.showChronicDiseasesAndAllergies) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 15, color: Color(0xFFDC2626)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF991B1B),
                                    fontFamily: 'Cairo',
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'الأمراض المزمنة والحساسية: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text:
                                          'حساسية بنسلين شديدة | سكري من النوع الثاني | ارتفاع ضغط الدم',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Clinical Diagnosis Box
                    if (template.showClinicalDiagnosis) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_hospital_outlined,
                                size: 14, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'التشخيص السريري (Clinical Diagnosis): Acute Upper Respiratory Tract Infection with Mild Hypertension',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Prescriptions List (Rx)
                    _buildA4RxSection(),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 3. Footer Area (Independent 4-way margins & height)
              Padding(
                padding: EdgeInsets.only(
                  top: template.footerMarginTop * 0.75,
                  bottom: template.footerMarginBottom * 0.75,
                  right: template.footerMarginRight * 0.75,
                  left: template.footerMarginLeft * 0.75,
                ),
                child: SizedBox(
                  height: template.footerHeight > 0
                      ? template.footerHeight
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildA4SignatureStampBox(
                        doctorName: effectiveDoctorName,
                        doctorTitle: effectiveDoctorTitle,
                        medicalLicense: effectiveMedicalLicense,
                      ),
                      const SizedBox(height: 4),
                      if (template.headerMode == 'preprinted' &&
                          template.hideFooterOnPreprinted) ...[
                        Container(
                          height: template.preprintedFooterHeight * 1.5,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.shade300, width: 0.8),
                            color: Colors.grey.shade50.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'مساحة تذييل الورق المطبوع مسبقاً (${template.preprintedFooterHeight.toInt()}mm) — فارغة في الطباعة',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ] else ...[
                        _buildA4Footer(
                          addresses: displayAddresses,
                          phones: displayPhones,
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

  // ═════════════════════════════════════════════════════════════════════════
  // PHYSICAL A4 SHEET EMULATION (BACK FACE - ظهر الروشتة)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildPhysicalA4BackSheet(BuildContext context, AppThemeColors colors) {
    final title = backPageTitleCtrl.text.trim().isEmpty
        ? template.backPageTitle
        : backPageTitleCtrl.text.trim();
    final diet = backPageDietCtrl.text.trim().isEmpty
        ? template.backPageDietAdvice
        : backPageDietCtrl.text.trim();
    final emergency = backPageEmergencyCtrl.text.trim().isEmpty
        ? template.backPageEmergencyNotes
        : backPageEmergencyCtrl.text.trim();
    final footer = backPageFooterCtrl.text.trim().isEmpty
        ? template.backPageFooterNotes
        : backPageFooterCtrl.text.trim();

    final activeInstructions = backInstructionsCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final displayInstructions = activeInstructions.isEmpty
        ? template.backPageInstructions
        : activeInstructions;

    return Container(
      width: 480,
      constraints: const BoxConstraints(minHeight: 680),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: showMarginGuides
            ? Border.all(color: Colors.blue.shade300, width: 1.5)
            : Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Back Header (Banner or Styled Title)
          if (template.backPageHeaderBannerBase64 != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: PrescriptionBase64Image(
                base64Str: template.backPageHeaderBannerBase64,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.health_and_safety_outlined,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'نصائح طبية وإرشادات هامة للحفاظ على صحتك وسرعة الشفاء',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFE0E7FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // 2. Instructions & Advice List
          Row(
            children: const [
              Icon(Icons.check_circle_rounded,
                  size: 16, color: Color(0xFF10B981)),
              SizedBox(width: 6),
              Text(
                'التعليمات والإرشادات الطبية المعتمدة:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...displayInstructions.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final text = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$idx',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF334155),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // 3. Diet & Nutrition Box
          if (diet.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.restaurant_outlined,
                      size: 16, color: Color(0xFF059669)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'نصائح التغذية ونمط الحياة الصحي:',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          diet,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF047857),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // 4. Emergency & Appointment Box
          if (emergency.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.phone_in_talk_outlined,
                      size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'للطوارئ والاستفسارات العاجلة:',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          emergency,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF1D4ED8),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // 5. Back Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Text(
              footer,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // DYNAMIC HEADER RENDERER
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildDynamicHeaderWidget({
    required String clinicName,
    required String doctorName,
    required String doctorTitle,
    required String englishName,
    required String englishTitle,
    required String ministryLicense,
    required String medicalLicense,
  }) {
    // Mode 1: Custom Uploaded Banner Image
    if (template.headerMode == 'customBannerImage') {
      if (template.headerBannerBase64 != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: PrescriptionBase64Image(
            base64Str: template.headerBannerBase64,
            height: template.headerHeight,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      } else {
        return Container(
          height: template.headerHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 32, color: Color(0xFF64748B)),
                SizedBox(height: 4),
                Text(
                  'انقر على لوحة الإعدادات لرفع صورة ترويسة الروشتة (Header Banner)',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Mode 2: Preprinted Header gap
    if (template.headerMode == 'preprinted') {
      return Container(
        height: template.preprintedHeaderHeight * 1.5,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.orange.shade300,
            style: BorderStyle.solid,
          ),
          color: Colors.orange.shade50.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            'مساحة مخصصة للترويسة الخارجية (${template.preprintedHeaderHeight.toInt()}mm مطبوع مسبقاً)',
            style: TextStyle(
              color: Colors.orange.shade800,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Mode 3: Dynamic Composed Studio Header
    final gradientColors = _getHeaderGradientColors(template.headerBackgroundStyle);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: gradientColors != null
            ? LinearGradient(
                colors: gradientColors,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              )
            : null,
        color: gradientColors == null ? Colors.white : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: _buildComposedHeaderLayout(
        clinicName: clinicName,
        doctorName: doctorName,
        doctorTitle: doctorTitle,
        englishName: englishName,
        englishTitle: englishTitle,
        ministryLicense: ministryLicense,
        medicalLicense: medicalLicense,
        isDarkHeader: gradientColors != null,
      ),
    );
  }

  List<Color>? _getHeaderGradientColors(String style) {
    switch (style) {
      case 'gradientBlue':
        return const [Color(0xFF1E3A8A), Color(0xFF2563EB)];
      case 'gradientTeal':
        return const [Color(0xFF0F766E), Color(0xFF14B8A6)];
      case 'gradientPurple':
        return const [Color(0xFF581C87), Color(0xFF9333EA)];
      case 'gradientWavy':
        return const [Color(0xFF0C4A6E), Color(0xFF0284C7)];
      default:
        return null;
    }
  }

  Widget _buildComposedHeaderLayout({
    required String clinicName,
    required String doctorName,
    required String doctorTitle,
    required String englishName,
    required String englishTitle,
    required String ministryLicense,
    required String medicalLicense,
    required bool isDarkHeader,
  }) {
    final textColor = isDarkHeader ? Colors.white : const Color(0xFF0F172A);
    final subTextColor =
        isDarkHeader ? const Color(0xFFE2E8F0) : const Color(0xFF475569);

    final logoWidget = template.logoImageBase64 != null
        ? Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: PrescriptionBase64Image(
                base64Str: template.logoImageBase64,
                fit: BoxFit.contain,
              ),
            ),
          )
        : Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDarkHeader
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFFE0583E).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.health_and_safety_outlined,
              color: isDarkHeader ? Colors.white : const Color(0xFFE0583E),
              size: 24,
            ),
          );

    if (template.headerAlignment == 'bilingual') {
      return Row(
        children: [
          // English Doctor Info (Left)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  englishName.isNotEmpty ? englishName : 'Dr. Doctor Name',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  englishTitle.isNotEmpty
                      ? englishTitle
                      : 'Consultant Specialist',
                  style: TextStyle(fontSize: 8.5, color: subTextColor),
                ),
                if (medicalLicense.isNotEmpty)
                  Text(
                    'Lic: $medicalLicense',
                    style: TextStyle(fontSize: 7.5, color: subTextColor),
                  ),
              ],
            ),
          ),

          // Center Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: logoWidget,
          ),

          // Arabic Doctor Info (Right)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  doctorName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  doctorTitle,
                  style: TextStyle(fontSize: 8.5, color: subTextColor),
                  textAlign: TextAlign.end,
                ),
                if (ministryLicense.isNotEmpty)
                  Text(
                    'ترخيص: $ministryLicense',
                    style: TextStyle(fontSize: 7.5, color: subTextColor),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    // Default Dual Layout
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            logoWidget,
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clinicName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (ministryLicense.isNotEmpty)
                  Text(
                    'ترخيص: $ministryLicense',
                    style: TextStyle(fontSize: 8.5, color: subTextColor),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              doctorName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              doctorTitle,
              style: TextStyle(fontSize: 8.5, color: subTextColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildA4PatientBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _patientMetaItem('اسم المريض:', 'أحمد عبد العزيز الشناوي'),
              ),
              Container(width: 1, height: 22, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _patientMetaItem('السن / النوع:', '42 سنة / ذكر'),
              ),
              Container(width: 1, height: 22, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _patientMetaItem('تاريخ الكشف:', '2026/11/24'),
              ),
              Container(width: 1, height: 22, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _patientMetaItem('رقم الملف:', '#40288'),
              ),
            ],
          ),
          if (template.showVitalSigns) ...[
            const SizedBox(height: 5),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 4),
            Row(
              children: const [
                Icon(Icons.monitor_heart_outlined,
                    size: 13, color: Color(0xFF2563EB)),
                SizedBox(width: 5),
                Text(
                  'العلامات الحيوية: ',
                  style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A)),
                ),
                Text(
                  'ضغط الدم: 120/80 mmHg   •   الوزن: 78 kg   •   الحرارة: 37°C   •   السكر: 110 mg/dL',
                  style: TextStyle(fontSize: 8.5, color: Color(0xFF475569)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _patientMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildA4RxSection() {
    final drugs = [
      (
        'Augmentin 1g Tab (Amoxicillin / Clavulanate)',
        'قرص واحد بالفم كل 12 ساعة بعد الوجبات لمدة 7 أيام متواصلة',
        'صرف علبة 1'
      ),
      (
        'Panadol Extra 500mg Tablet',
        'قرص عند الشعور بالصداع أو ارتفاع درجة الحرارة (بحد أقصى 3 مرات يومياً)',
        'عند اللزوم'
      ),
      (
        'Concor 5mg Tab (Bisoprolol Fumarate)',
        'قرص واحد صباحاً يومياً قبل وجبة الإفطار مع قياس الضغط أسبوعياً',
        'علاج دوري مستمر'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Text(
                  '℞',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                    fontFamily: 'serif',
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'PRESCRIBED MEDICAL TREATMENT',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ختم الصيدلية وصلاحية الصرف 7 أيام',
                style: TextStyle(fontSize: 7.5, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (template.rxLayoutStyle == 'table') ...[
          Table(
            border:
                TableBorder.all(color: const Color(0xFFE2E8F0), width: 0.8),
            columnWidths: const {
              0: FlexColumnWidth(3.2),
              1: FlexColumnWidth(1.4),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(2.6),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: Text('الدواء والعلاج',
                        style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A))),
                  ),
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: Text('الجرعة والتكرار',
                        style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A))),
                  ),
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: Text('المدة',
                        style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A))),
                  ),
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: Text('التعليمات السريرية',
                        style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A))),
                  ),
                ],
              ),
              ...drugs.asMap().entries.map((entry) {
                final d = entry.value;
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(d.$1,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A))),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(5),
                      child: Text('قرص كل 12 ساعة',
                          style: TextStyle(
                              fontSize: 8.5, color: Color(0xFF334155))),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(5),
                      child: Text('7 أيام',
                          style: TextStyle(
                              fontSize: 8.5, color: Color(0xFF334155))),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(d.$2,
                          style: const TextStyle(
                              fontSize: 8, color: Color(0xFF475569))),
                    ),
                  ],
                );
              }),
            ],
          ),
        ] else ...[
          ...drugs.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final d = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.only(bottom: 6),
              decoration: const BoxDecoration(
                border: Border(
                    bottom:
                        BorderSide(color: Color(0xFFF1F5F9), width: 0.8)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF2563EB), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$idx',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  d.$1,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                d.$3,
                                style: const TextStyle(
                                    fontSize: 7.5,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 11, color: Color(0xFF2563EB)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                d.$2,
                                style: const TextStyle(
                                    fontSize: 8.5, color: Color(0xFF475569)),
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
          }),
        ],

        if (template.showFollowUpBox) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available_outlined,
                    size: 13, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                const Text(
                  'موعد الاستشارة والإعادة: ',
                  style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A)),
                ),
                Expanded(
                  child: Text(
                    template.followUpText,
                    style:
                        const TextStyle(fontSize: 8, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildA4SignatureStampBox({
    required String doctorName,
    required String doctorTitle,
    required String medicalLicense,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (template.includeDoctorSignature)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'توقيع الطبيب الاستشاري:',
                style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              template.signatureImageBase64 != null
                  ? PrescriptionBase64Image(
                      base64Str: template.signatureImageBase64,
                      width: 90,
                      height: 40,
                      fit: BoxFit.contain,
                    )
                  : Container(
                      width: 85,
                      height: 35,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF94A3B8), width: 1),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'توقيع معتمد',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
            ],
          )
        else
          const SizedBox(),

        if (template.includeOfficialStamp)
          template.stampImageBase64 != null
              ? PrescriptionBase64Image(
                  base64Str: template.stampImageBase64,
                  width: 70,
                  height: 50,
                  fit: BoxFit.contain,
                )
              : Container(
                  width: 80,
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFF0D9488), width: 1.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    template.officialStampText.isNotEmpty
                        ? template.officialStampText
                        : 'ختم المركز المعتمد',
                    style: const TextStyle(
                      fontSize: 7.5,
                      color: Color(0xFF0F766E),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
        else
          const SizedBox(),
      ],
    );
  }

  Widget _buildA4Footer({
    required List<String> addresses,
    required List<String> phones,
  }) {
    return Column(
      children: [
        if (template.legalDisclaimer.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              template.legalDisclaimer,
              style: const TextStyle(fontSize: 7.5, color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (addresses.isNotEmpty || phones.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  addresses.join('  •  '),
                  style: const TextStyle(fontSize: 7.5, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (phones.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  phones.join('  |  '),
                  style: const TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569)),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildPaperFormatSelector(BuildContext context, AppThemeColors colors) {
    final formats = [
      ('روشتة العيادة الخارجية (القياسية) A4', 'a4', '210x297mm'),
      ('روشتة مدمجة A5', 'a5', '148x210mm'),
      ('إيصال حراري سريع POS', 'thermal80', '80mm Thermal'),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: formats.map((f) {
        final isSelected = template.defaultPaperSize == f.$2;
        return InkWell(
          onTap: () => onPaperSizeChanged(f.$2),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? colors.primaryLight : colors.cardBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? colors.primary : colors.borderSubtle,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 13,
                  color: isSelected ? colors.primary : colors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  '${f.$1} (${f.$3})',
                  style: CustomAppFontStyle.medium11.copyWith(
                    color: isSelected ? colors.primary : colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
