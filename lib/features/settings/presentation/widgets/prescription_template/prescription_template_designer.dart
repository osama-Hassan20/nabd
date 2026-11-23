import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/prescription_template_model.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'package:eyadty/features/visits/data/models/prescription_item_model.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/visits/presentation/helpers/prescription_pdf_generator.dart';

class PrescriptionTemplateDesigner extends StatefulWidget {
  final SettingsCubit? settingsCubit;

  const PrescriptionTemplateDesigner({super.key, this.settingsCubit});

  @override
  State<PrescriptionTemplateDesigner> createState() =>
      _PrescriptionTemplateDesignerState();
}

class _PrescriptionTemplateDesignerState
    extends State<PrescriptionTemplateDesigner> {
  late PrescriptionTemplateModel _template;
  bool _initialized = false;
  int _activeTopTab = 0; // 0: Rx, 1: Invoices, 2: Thermal POS

  // Preview controls
  double _zoomScale = 0.70;
  bool _showMarginGuides = false;
  bool _isGrayscalePreview = false;

  // Controllers for editable fields
  late final TextEditingController _doctorNameCtrl;
  late final TextEditingController _clinicNameCtrl;
  late final TextEditingController _doctorTitleCtrl;
  late final TextEditingController _medicalLicenseCtrl;
  late final TextEditingController _ministryLicenseCtrl;
  late final TextEditingController _disclaimerCtrl;
  late final TextEditingController _watermarkTextCtrl;
  late final TextEditingController _stampTextCtrl;
  final List<TextEditingController> _addressCtrls = [];
  final List<TextEditingController> _phoneCtrls = [];

  @override
  void initState() {
    super.initState();
    _template = const PrescriptionTemplateModel();
    _doctorNameCtrl = TextEditingController(text: _template.doctorDisplayName);
    _clinicNameCtrl = TextEditingController(text: _template.clinicDisplayName);
    _doctorTitleCtrl = TextEditingController(text: _template.doctorTitle);
    _medicalLicenseCtrl =
        TextEditingController(text: _template.medicalLicenseNumber);
    _ministryLicenseCtrl =
        TextEditingController(text: _template.ministryLicenseNumber);
    _disclaimerCtrl = TextEditingController(text: _template.legalDisclaimer);
    _watermarkTextCtrl =
        TextEditingController(text: _template.watermarkCustomText);
    _stampTextCtrl = TextEditingController(text: _template.officialStampText);

    _syncAddressControllers(_template.addresses);
    _syncPhoneControllers(_template.phoneNumbers);

    final cubit = widget.settingsCubit;
    if (cubit != null && cubit.state.settings != null) {
      _loadFromSettings(cubit.state.settings!.effectivePrescriptionTemplate);
    }
  }

  void _syncAddressControllers(List<String> addresses) {
    for (final c in _addressCtrls) {
      c.dispose();
    }
    _addressCtrls.clear();
    for (final a in addresses) {
      _addressCtrls.add(TextEditingController(text: a));
    }
  }

  void _syncPhoneControllers(List<String> phones) {
    for (final c in _phoneCtrls) {
      c.dispose();
    }
    _phoneCtrls.clear();
    for (final p in phones) {
      _phoneCtrls.add(TextEditingController(text: p));
    }
  }

  void _loadFromSettings(PrescriptionTemplateModel template) {
    _template = template;
    _doctorNameCtrl.text = template.doctorDisplayName;
    _clinicNameCtrl.text = template.clinicDisplayName;
    _doctorTitleCtrl.text = template.doctorTitle;
    _medicalLicenseCtrl.text = template.medicalLicenseNumber;
    _ministryLicenseCtrl.text = template.ministryLicenseNumber;
    _disclaimerCtrl.text = template.legalDisclaimer;
    _watermarkTextCtrl.text = template.watermarkCustomText;
    _stampTextCtrl.text = template.officialStampText;
    _syncAddressControllers(template.addresses);
    _syncPhoneControllers(template.phoneNumbers);
    _initialized = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      try {
        final cubit = widget.settingsCubit ?? context.read<SettingsCubit>();
        if (cubit.state.settings != null) {
          _loadFromSettings(
            cubit.state.settings!.effectivePrescriptionTemplate,
          );
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _doctorNameCtrl.dispose();
    _clinicNameCtrl.dispose();
    _doctorTitleCtrl.dispose();
    _medicalLicenseCtrl.dispose();
    _ministryLicenseCtrl.dispose();
    _disclaimerCtrl.dispose();
    _watermarkTextCtrl.dispose();
    _stampTextCtrl.dispose();
    for (final c in _addressCtrls) {
      c.dispose();
    }
    for (final c in _phoneCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateTemplate(PrescriptionTemplateModel Function() updater) {
    setState(() {
      _template = updater();
    });
  }

  Future<void> _handleSave() async {
    final cubit = widget.settingsCubit ?? context.read<SettingsCubit>();
    // Collect active addresses and phones
    final addrs = _addressCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final phones = _phoneCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final toSave = _template.copyWith(
      doctorDisplayName: _doctorNameCtrl.text.trim(),
      clinicDisplayName: _clinicNameCtrl.text.trim(),
      doctorTitle: _doctorTitleCtrl.text.trim(),
      medicalLicenseNumber: _medicalLicenseCtrl.text.trim(),
      ministryLicenseNumber: _ministryLicenseCtrl.text.trim(),
      legalDisclaimer: _disclaimerCtrl.text.trim(),
      watermarkCustomText: _watermarkTextCtrl.text.trim(),
      officialStampText: _stampTextCtrl.text.trim(),
      addresses: addrs.isEmpty ? _template.addresses : addrs,
      phoneNumbers: phones.isEmpty ? _template.phoneNumbers : phones,
    );

    final success = await cubit.updatePrescriptionTemplate(toSave);
    if (success && mounted) {
      CustomToast(
        context: context,
        header: 'تم حفظ وتطبيق قالب الروشتة بنجاح',
      ).showTopToast();
    }
  }

  Future<void> _handlePrintTestPage() async {
    try {
      final sampleVisit = VisitModel(
        id: 'VISIT-TEST-01',
        patientId: 'PAT-40288',
        patientName: 'أحمد عبد العزيز الشناوي',
        doctorId: 'DOC-TEST',
        doctorName: _template.doctorDisplayName,
        startedAt: DateTime.now(),
        finalizedAt: DateTime.now(),
        diagnosis:
            'Acute Upper Respiratory Tract Infection with Mild Hypertension',
      );

      final samplePatient = PatientModel(
        id: 'PAT-40288',
        fileNumber: '40288',
        name: 'أحمد عبد العزيز الشناوي',
        phone: '01012345678',
        dateOfBirth: DateTime(1982, 5, 14),
        allergies: const ['حساسية بنسلين شديدة'],
        chronicDiseases: const ['ارتفاع ضغط الدم', 'سكري نوع 2'],
      );

      final sampleItems = [
        const PrescriptionItemModel(
          tradeName: 'Augmentin 1g (Amoxicillin / Clavulanate)',
          dosage: 'قرص 1 جم',
          frequency: 'قرص واحد بالفم كل 12 ساعة بعد الوجبات لمدة 7 أيام متواصلة',
          instructions: 'صرف علبة 1 بعد الأكل',
        ),
        const PrescriptionItemModel(
          tradeName: 'Panadol Extra 500mg Tablet',
          dosage: 'قرص 500 ملجم',
          frequency: 'قرص عند الشعور بالصداع أو ارتفاع درجة الحرارة (بحد أقصى 3 مرات يومياً)',
          instructions: 'عند اللزوم فقط',
        ),
        const PrescriptionItemModel(
          tradeName: 'Concor 5mg Tab (Bisoprolol Fumarate)',
          dosage: 'قرص 5 ملجم',
          frequency: 'قرص واحد صباحاً يومياً قبل وجبة الإفطار مع قياس الضغط أسبوعياً',
          instructions: 'علاج دوري مستمر مع متابعة النبض',
        ),
      ];

      final cubit = widget.settingsCubit ?? context.read<SettingsCubit>();
      final currentSettings = cubit.state.settings;
      final effectiveSettings = (currentSettings ?? const CompanySettingsModel())
          .copyWith(prescriptionTemplate: _template);

      final pdfBytes = await PrescriptionPdfGenerator.generate(
        visit: sampleVisit,
        patient: samplePatient,
        effectiveItems: sampleItems,
        settings: effectiveSettings,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Prescription_Template_Test',
      );
    } catch (e) {
      if (mounted) {
        CustomToast(
          context: context,
          header: 'تعذر طباعة الصفحة التجريبية: $e',
        ).showTopToast();
      }
    }
  }

  void _handleResetDefault() {
    _loadFromSettings(const PrescriptionTemplateModel());
    CustomToast(
      context: context,
      header: 'تمت استعادة الإعدادات القياسية للقالب',
    ).showTopToast();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final isMobile = AdaptiveLayout.isMobile(context);

    return BlocConsumer<SettingsCubit, SettingsState>(
      bloc: widget.settingsCubit,
      listener: (context, state) {
        if (!_initialized && state.settings != null) {
          _loadFromSettings(state.settings!.effectivePrescriptionTemplate);
        }
      },
      builder: (context, state) {
        final isLoading = state.actionStatus == RequestStatusEnum.loading;

        if (isMobile) {
          // Mobile: stacked, fully scrollable
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(context, colors, isLoading, isMobile),
                const SizedBox(height: 12),
                _buildDocumentTypeTabs(colors),
                const SizedBox(height: 16),
                _buildRightControls(context, colors),
                const SizedBox(height: 20),
                _buildLivePreviewColumn(context, colors),
              ],
            ),
          );
        }

        // Desktop: fixed-height two-column split — preview pinned, controls scrollable
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header: Title & Actions ─────────────────────────────
              _buildTopBar(context, colors, isLoading, isMobile),
              const SizedBox(height: 12),

              // ─── Tabs: Rx Prescription / Invoices / Thermal POS ─────
              _buildDocumentTypeTabs(colors),
              const SizedBox(height: 14),

              // ─── Two-Column Layout: Preview (fixed) + Controls (scrollable) ─
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column: Live A4 Preview — fixed, no scroll
                    Expanded(
                      flex: 48,
                      child: _buildLivePreviewColumn(context, colors),
                    ),
                    const SizedBox(width: 16),
                    // Right Column: Scrollable settings panels
                    Expanded(
                      flex: 52,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _buildRightControls(context, colors),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar(
    BuildContext context,
    AppThemeColors colors,
    bool isLoading,
    bool isMobile,
  ) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'تخصيص قوالب الطباعة والعلامة المائية الرسمية',
                  style: CustomAppFontStyle.bold20.copyWith(
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
                    'معتمد ومؤمن',
                    style: CustomAppFontStyle.semiBold12.copyWith(
                      color: colors.isDark
                          ? Colors.teal.shade300
                          : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'ضبط وتخصيص ترويسات وتذييلات مطبوعات المركز الطبي، العلامة المائية الأمنية لمنع التزوير، مقاسات الورق وخيارات الختم الرقمي والتوقيع المعتمد.',
              style: CustomAppFontStyle.regular13.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),

        // Action Buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Reset to Default
            CustomPushButton(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              backgroundColor: colors.surfaceLevel1,
              boxBorder: Border.all(color: colors.borderSubtle),
              borderRadius: BorderRadius.circular(8),
              onTap: _handleResetDefault,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restore_rounded,
                      size: 16, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'استعادة القياسي',
                    style: CustomAppFontStyle.medium13.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Print Test Page
            CustomPushButton(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              backgroundColor: colors.surfaceLevel1,
              boxBorder: Border.all(color: colors.borderSubtle),
              borderRadius: BorderRadius.circular(8),
              onTap: _handlePrintTestPage,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print_outlined,
                      size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'طباعة صفحة تجريبية',
                    style: CustomAppFontStyle.medium13.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Save and Apply
            CustomPushButton(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              backgroundColor: colors.primary,
              isLoading: isLoading,
              borderRadius: BorderRadius.circular(8),
              onTap: _handleSave,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'حفظ وتطبيق القالب',
                    style: CustomAppFontStyle.semiBold14.copyWith(
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

  // ═════════════════════════════════════════════════════════════════════════
  // DOCUMENT TYPE TABS
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildDocumentTypeTabs(AppThemeColors colors) {
    final tabs = [
      ('قوالب الروشتة السريرية (Rx Prescription A4)', Icons.medical_services_outlined),
      ('فواتير وإيصالات العيادة (Invoices & Receipts)', Icons.receipt_long_outlined),
      ('إيصالات الصرف الحرارية (Thermal POS 80mm)', Icons.print_outlined),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceLevel1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(tabs.length, (idx) {
          final isSelected = _activeTopTab == idx;
          return InkWell(
            onTap: () => setState(() => _activeTopTab = idx),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colors.cardBackground : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: colors.isDark ? 0.3 : 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
                border: isSelected
                    ? Border.all(color: colors.borderSubtle)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tabs[idx].$2,
                    size: 16,
                    color: isSelected ? colors.primary : colors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tabs[idx].$1,
                    style: CustomAppFontStyle.medium13.copyWith(
                      color: isSelected ? colors.primary : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // LEFT COLUMN: LIVE A4 PREVIEW
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildLivePreviewColumn(
    BuildContext context,
    AppThemeColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview Toolbar — always full color, never grayscale
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'المعاينة الحية الفورية (A4 Preview)',
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),

              // Zoom selector
              IconButton(
                icon: const Icon(Icons.zoom_out_rounded, size: 18),
                tooltip: 'تصغير',
                color: colors.textSecondary,
                onPressed: _zoomScale > 0.5
                    ? () => setState(() => _zoomScale -= 0.05)
                    : null,
              ),
              Text(
                '${(_zoomScale * 100).toInt()}%',
                style: CustomAppFontStyle.medium12.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in_rounded, size: 18),
                tooltip: 'تكبير',
                color: colors.textSecondary,
                onPressed: _zoomScale < 1.2
                    ? () => setState(() => _zoomScale += 0.05)
                    : null,
              ),
              const SizedBox(width: 8),

              // Margins guide toggle
              InkWell(
                onTap: () => setState(() => _showMarginGuides = !_showMarginGuides),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _showMarginGuides
                        ? colors.primaryLight
                        : colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _showMarginGuides
                          ? colors.primary
                          : colors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.crop_free_rounded,
                          size: 14,
                          color: _showMarginGuides
                              ? colors.primary
                              : colors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'خطوط الهامش',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: _showMarginGuides
                              ? colors.primary
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // B&W Laser toggle — applies ONLY to the preview sheet, not the UI
              InkWell(
                onTap: () =>
                    setState(() => _isGrayscalePreview = !_isGrayscalePreview),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isGrayscalePreview
                        ? colors.surfaceLevel2
                        : colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isGrayscalePreview
                          ? colors.textPrimary
                          : colors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tonality_rounded,
                          size: 14,
                          color: _isGrayscalePreview
                              ? colors.textPrimary
                              : colors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'أبيض وأسود',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: _isGrayscalePreview
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

        // Preview Sheet Container — grayscale scoped ONLY here
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceLevel1,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Center(
                  child: Transform.scale(
                    scale: _zoomScale,
                    alignment: Alignment.topCenter,
                    // ★ Grayscale applied ONLY around the A4 paper sheet ★
                    child: ColorFiltered(
                      colorFilter: _isGrayscalePreview
                          ? const ColorFilter.matrix([
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0,      0,      0,      1, 0,
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent, BlendMode.multiply),
                      child: _buildPhysicalA4Sheet(colors),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Bottom Paper Format Selector
        _buildPaperFormatSelector(colors),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PHYSICAL A4 SHEET EMULATION
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildPhysicalA4Sheet(AppThemeColors colors) {
    final effectiveDoctorName = _doctorNameCtrl.text.trim().isEmpty
        ? _template.doctorDisplayName
        : _doctorNameCtrl.text.trim();
    final effectiveClinicName = _clinicNameCtrl.text.trim().isEmpty
        ? _template.clinicDisplayName
        : _clinicNameCtrl.text.trim();
    final effectiveDoctorTitle = _doctorTitleCtrl.text.trim().isEmpty
        ? _template.doctorTitle
        : _doctorTitleCtrl.text.trim();
    final effectiveMedicalLicense = _medicalLicenseCtrl.text.trim().isEmpty
        ? _template.medicalLicenseNumber
        : _medicalLicenseCtrl.text.trim();
    final effectiveMinistryLicense = _ministryLicenseCtrl.text.trim().isEmpty
        ? _template.ministryLicenseNumber
        : _ministryLicenseCtrl.text.trim();

    final activeAddrs = _addressCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final displayAddresses =
        activeAddrs.isEmpty ? _template.addresses : activeAddrs;

    final activePhones = _phoneCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final displayPhones =
        activePhones.isEmpty ? _template.phoneNumbers : activePhones;

    return Container(
        width: 480,
        constraints: const BoxConstraints(minHeight: 680),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: _showMarginGuides
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
        padding: EdgeInsets.only(
          top: _template.topMargin * 0.8,
          bottom: _template.bottomMargin * 0.8,
          right: _template.rightMargin * 0.8,
          left: _template.leftMargin * 0.8,
        ),
        child: Stack(
          children: [
            // Watermark Layer
            if (_template.watermarkEnabled)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Opacity(
                      opacity: _template.watermarkOpacity.clamp(0.04, 0.4),
                      child: _template.watermarkType == 'customText'
                          ? Transform.rotate(
                              angle: -0.4,
                              child: Text(
                                _watermarkTextCtrl.text.trim().isEmpty
                                    ? _template.watermarkCustomText
                                    : _watermarkTextCtrl.text.trim(),
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE0583E),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : const CustomAssetImage(
                              path: AppIcons.service,
                              width: 170,
                              height: 170,
                              color: Color(0xFFE0583E),
                            ),
                    ),
                  ),
                ),
              ),

            // Content Layer
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Area
                if (_template.headerLayout == 'preprinted')
                  Container(
                    height: _template.preprintedHeaderHeight * 1.5,
                    margin: const EdgeInsets.only(bottom: 12),
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
                        'مساحة مخصصة للترويسة الخارجية (${_template.preprintedHeaderHeight.toInt()}mm مطبوع مسبقاً)',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  _buildA4Header(
                    effectiveClinicName: effectiveClinicName,
                    effectiveDoctorName: effectiveDoctorName,
                    effectiveDoctorTitle: effectiveDoctorTitle,
                    effectiveMinistryLicense: effectiveMinistryLicense,
                  ),

                const Divider(height: 16, thickness: 1.5, color: Color(0xFFE2E8F0)),

                // 2. Patient Meta Box
                _buildA4PatientBox(),
                const SizedBox(height: 8),

                // 3. Clinical Alert: Chronic Diseases & Allergies (Requested specifically!)
                if (_template.showChronicDiseasesAndAllergies) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF991B1B),
                                fontFamily: 'Cairo',
                              ),
                              children: [
                                TextSpan(
                                  text: 'الأمراض المزمنة والحساسية: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 8),
                ],

                // 4. Clinical Diagnosis Box
                if (_template.showClinicalDiagnosis) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_hospital_outlined,
                            size: 15, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'التشخيص السريري (Clinical Diagnosis): Acute Upper Respiratory Tract Infection with Mild Hypertension',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // 5. Prescriptions List (Rx)
                _buildA4RxSection(),
                const SizedBox(height: 12),

                // 6. Signature & Official Stamp Area
                _buildA4SignatureStampBox(
                  doctorName: effectiveDoctorName,
                  doctorTitle: effectiveDoctorTitle,
                  medicalLicense: effectiveMedicalLicense,
                ),
                const SizedBox(height: 10),

                // 7. Disclaimer & Branches Footer
                _buildA4Footer(
                  addresses: displayAddresses,
                  phones: displayPhones,
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildA4Header({
    required String effectiveClinicName,
    required String effectiveDoctorName,
    required String effectiveDoctorTitle,
    required String effectiveMinistryLicense,
  }) {
    if (_template.headerLayout == 'centered') {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0583E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(6),
                child: const CustomAssetImage(
                  path: AppIcons.service,
                  color: Color(0xFFE0583E),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    effectiveClinicName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '$effectiveDoctorName - $effectiveDoctorTitle',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                    ),
                  ),
                  if (_template.showMinistryLicense)
                    Text(
                      'ترخيص وزارة الصحة: $effectiveMinistryLicense',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    // Default 'dual' header layout
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clinic / Logo
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE0583E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(8),
              child: const CustomAssetImage(
                path: AppIcons.service,
                color: Color(0xFFE0583E),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  effectiveClinicName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (_template.showMinistryLicense)
                  Text(
                    'ترخيص وزارة الصحة: $effectiveMinistryLicense',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // QR code & Reference
        if (_template.showQrCode)
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Ref: 2026-09823',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  Text(
                    DateFormat('yyyy/MM/dd').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.qr_code_2, size: 28, color: Colors.black87),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildA4PatientBox() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _patientMetaItem('اسم المريض:', 'أحمد عبد العزيز الشناوي'),
          _patientMetaItem('السن / النوع:', '42 سنة / ذكر'),
          _patientMetaItem('رقم الملف:', '#40288'),
          if (_template.showVitalSigns)
            _patientMetaItem('الوزن / الضغط:', '78 كجم / 120/80'),
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
          style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildA4RxSection() {
    final drugs = [
      ('Augmentin 1g (Amoxicillin / Clavulanate) Tab', 'قرص واحد بالفم كل 12 ساعة بعد الوجبات لمدة 7 أيام متواصلة', 'صرف علبة 1'),
      ('Panadol Extra 500mg Tablet', 'قرص عند الشعور بالصداع أو ارتفاع درجة الحرارة (بحد أقصى 3 مرات يومياً)', 'عند اللزوم'),
      ('Concor 5mg Tab (Bisoprolol Fumarate)', 'قرص واحد صباحاً يومياً قبل وجبة الإفطار مع قياس الضغط أسبوعياً', 'علاج دوري مستمر'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Classical Rx Symbol
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
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Drug Items
        ...drugs.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final d = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$idx. ${d.$1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 11, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              d.$2,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    d.$3,
                    style: const TextStyle(fontSize: 8.5, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildA4SignatureStampBox({
    required String doctorName,
    required String doctorTitle,
    required String medicalLicense,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Doctor Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الطبيب الاستشاري المعالج:',
                  style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B)),
                ),
                Text(
                  doctorName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  doctorTitle,
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF475569)),
                ),
                Text(
                  'نقابة الأطباء رقم: $medicalLicense',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // Official Clinic Stamp
          if (_template.includeOfficialStamp)
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _stampTextCtrl.text.trim().isEmpty
                      ? _template.officialStampText
                      : _stampTextCtrl.text.trim(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 12),

          // Doctor Signature Script
          if (_template.includeDoctorSignature)
            Column(
              children: [
                Container(
                  width: 90,
                  height: 38,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.blue.shade900.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Dr. $doctorName',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'توقيع الاستشاري',
                  style: TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildA4Footer({
    required List<String> addresses,
    required List<String> phones,
  }) {
    return Column(
      children: [
        // Legal Disclaimer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _disclaimerCtrl.text.trim().isEmpty
                ? _template.legalDisclaimer
                : _disclaimerCtrl.text.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8.5, color: Color(0xFF92400E)),
          ),
        ),
        const SizedBox(height: 6),

        // Multiple Addresses & Phones
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            ...addresses.map((a) => Text(
                  a,
                  style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                )),
            ...phones.map((p) => Text(
                  '📞 $p',
                  style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildPaperFormatSelector(AppThemeColors colors) {
    final formats = [
      ('روشتة العيادة الخارجية (القياسية) A4', 'a4', '210x297mm'),
      ('روشتة مدمجة A5', 'a5', '148x210mm'),
      ('إيصال حراري سريع POS', 'thermal80', '80mm Thermal'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: formats.map((f) {
        final isSelected = _template.defaultPaperSize == f.$2;
        return InkWell(
          onTap: () => _updateTemplate(() => _template.copyWith(defaultPaperSize: f.$2)),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? colors.primaryLight : colors.cardBackground,
              borderRadius: BorderRadius.circular(8),
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
                  size: 14,
                  color: isSelected ? colors.primary : colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${f.$1} (${f.$3})',
                  style: CustomAppFontStyle.medium12.copyWith(
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

  // ═════════════════════════════════════════════════════════════════════════
  // RIGHT COLUMN: INTERACTIVE ACCORDION PANELS
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildRightControls(BuildContext context, AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Panel 1: Watermark & Security ─────────────────────────
        _buildWatermarkSecurityPanel(colors),
        const SizedBox(height: 16),

        // ─── Panel 2: Header Layout & Doctor Custom Identity ───────
        _buildHeaderDoctorPanel(colors),
        const SizedBox(height: 16),

        // ─── Panel 3: Footer, Signatures & Margins ─────────────────
        _buildFooterSignaturesPanel(colors),
      ],
    );
  }

  // ─── Panel 1: Watermark & Security ─────────────────────────────
  Widget _buildWatermarkSecurityPanel(AppThemeColors colors) {
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
              Icon(Icons.shield_outlined, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'العلامة المائية الأمنية (Anti-Counterfeit Protection)',
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _template.watermarkEnabled,
                  activeThumbColor: colors.primary,
                  onChanged: (val) => _updateTemplate(
                    () => _template.copyWith(watermarkEnabled: val),
                  ),
                ),
              ),
            ],
          ),

          if (_template.watermarkEnabled) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: colors.borderSubtle),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Watermark Type
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نوع العلامة المائية:',
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _choiceChip(
                            label: 'شعار المنشأة',
                            selected: _template.watermarkType == 'logo',
                            colors: colors,
                            onSelected: () => _updateTemplate(
                              () => _template.copyWith(watermarkType: 'logo'),
                            ),
                          ),
                          _choiceChip(
                            label: 'نص مخصص',
                            selected: _template.watermarkType == 'customText',
                            colors: colors,
                            onSelected: () => _updateTemplate(
                              () => _template.copyWith(watermarkType: 'customText'),
                            ),
                          ),
                          _choiceChip(
                            label: 'كود تشفيري',
                            selected: _template.watermarkType == 'code',
                            colors: colors,
                            onSelected: () => _updateTemplate(
                              () => _template.copyWith(watermarkType: 'code'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Opacity Slider
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'درجة الشفافية:',
                            style: CustomAppFontStyle.medium12.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: colors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${(_template.watermarkOpacity * 100).toInt()}% (طباعة)',
                              style: CustomAppFontStyle.medium11.copyWith(
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _template.watermarkOpacity,
                        min: 0.05,
                        max: 0.30,
                        divisions: 25,
                        activeColor: colors.primary,
                        onChanged: (val) => _updateTemplate(
                          () => _template.copyWith(watermarkOpacity: val),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_template.watermarkType == 'customText') ...[
              const SizedBox(height: 6),
              CustomTextFormField(
                controller: _watermarkTextCtrl,
                headerText: 'النص المطبوع كعلامة مائية',
                hintText: 'مثال: نسخة رسمية معتمدة',
                onChanged: (_) => setState(() {}),
              ),
            ],

            const SizedBox(height: 4),

            // Microprint protection checkbox
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _template.enableMicroprintProtection,
                    activeColor: colors.primary,
                    onChanged: (val) => _updateTemplate(
                      () => _template.copyWith(
                        enableMicroprintProtection: val ?? true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'تقنية الحماية ضد التصوير الضوئي (توليد خطوط دقيقة تظهر كلمة COPY)',
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Panel 2: Header Layout & Identity Customization ───────────
  Widget _buildHeaderDoctorPanel(AppThemeColors colors) {
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
              Icon(Icons.dashboard_customize_outlined,
                  size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'ترويسة الورقة الرسمية وبيانات الطبيب المعالج',
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Header Layout Selector
          Row(
            children: [
              Text(
                'شكل الترويسة:',
                style: CustomAppFontStyle.medium12.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _choiceChip(
                      label: 'ترويسة ثنائية',
                      selected: _template.headerLayout == 'dual',
                      colors: colors,
                      onSelected: () => _updateTemplate(
                        () => _template.copyWith(headerLayout: 'dual'),
                      ),
                    ),
                    _choiceChip(
                      label: 'ترويسة مركزية',
                      selected: _template.headerLayout == 'centered',
                      colors: colors,
                      onSelected: () => _updateTemplate(
                        () => _template.copyWith(headerLayout: 'centered'),
                      ),
                    ),
                    _choiceChip(
                      label: 'ورق مطبوع مسبقاً',
                      selected: _template.headerLayout == 'preprinted',
                      colors: colors,
                      onSelected: () => _updateTemplate(
                        () => _template.copyWith(headerLayout: 'preprinted'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_template.headerLayout == 'preprinted') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'مسافة الهامش الفارغ المتروك للهيدر الخارجي (mm):',
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: CustomTextFormField(
                    initialValue: _template.preprintedHeaderHeight.toInt().toString(),
                    textInputType: TextInputType.number,
                    onChanged: (v) {
                      final n = double.tryParse(v ?? '') ?? 45.0;
                      _updateTemplate(
                        () => _template.copyWith(preprintedHeaderHeight: n),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 10),

          // Row 1: Doctor Display Name + Clinic Display Name SIDE-BY-SIDE
          Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                  controller: _doctorNameCtrl,
                  headerText: 'اسم الطبيب المطبوع (أو اسم الشهرة)',
                  hintText: 'مثال: أ.د. حسام الدين عزمي',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomTextFormField(
                  controller: _clinicNameCtrl,
                  headerText: 'اسم العيادة أو المركز الطبي',
                  hintText: 'مثال: مجمع المهندسين التخصصي',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Doctor Title & Degrees
          CustomTextFormField(
            controller: _doctorTitleCtrl,
            headerText: 'الدرجة العلمية والتخصص المطبوع',
            hintText: 'مثال: استشاري الأمراض الباطنة والقلب والأوعية الدموية',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),

          // Row 3: Medical License + Ministry License SIDE-BY-SIDE
          Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                  controller: _medicalLicenseCtrl,
                  headerText: 'رقم ترخيص مزاولة المهنة / النقابة',
                  hintText: 'مثال: 441092',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomTextFormField(
                  controller: _ministryLicenseCtrl,
                  headerText: 'ترخيص وزارة الصحة',
                  hintText: 'مثال: 8849/2021',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 10),

          // ── Multiple Addresses Section (paired 2 per row) ─────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عناوين الفروع المطبوعة (يمكن كتابة أكثر من عنوان):',
                style: CustomAppFontStyle.semiBold13.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              CustomPushButton(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: colors.primaryLight,
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  setState(() {
                    _addressCtrls.add(TextEditingController());
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: colors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'إضافة عنوان فرع',
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

          // ── Multiple Phone Numbers Section (paired 2 per row) ─────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أرقام الهواتف والخط الساخن المطبوعة:',
                style: CustomAppFontStyle.semiBold13.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              CustomPushButton(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: colors.primaryLight,
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  setState(() {
                    _phoneCtrls.add(TextEditingController());
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: colors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'إضافة رقم هاتف',
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

          const SizedBox(height: 12),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 10),

          // ── Clinical & Diagnostic Options (2x2 Grid) ───────────────
          Text(
            'خيارات البيانات الطبية والسريرية المطبوعة:',
            style: CustomAppFontStyle.semiBold13.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _compactSwitchItem(
                  label: 'الأمراض المزمنة والحساسية',
                  value: _template.showChronicDiseasesAndAllergies,
                  colors: colors,
                  onChanged: (val) => _updateTemplate(
                    () => _template.copyWith(showChronicDiseasesAndAllergies: val),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _compactSwitchItem(
                  label: 'القياسات الحيوية (الضغط والوزن)',
                  value: _template.showVitalSigns,
                  colors: colors,
                  onChanged: (val) => _updateTemplate(
                    () => _template.copyWith(showVitalSigns: val),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _compactSwitchItem(
                  label: 'التشخيص الطبي السريري',
                  value: _template.showClinicalDiagnosis,
                  colors: colors,
                  onChanged: (val) => _updateTemplate(
                    () => _template.copyWith(showClinicalDiagnosis: val),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _compactSwitchItem(
                  label: 'رمز الاستجابة QR Code',
                  value: _template.showQrCode,
                  colors: colors,
                  onChanged: (val) => _updateTemplate(
                    () => _template.copyWith(showQrCode: val),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Panel 3: Footer, Signatures & Margins ─────────────────────
  Widget _buildFooterSignaturesPanel(AppThemeColors colors) {
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
              Icon(Icons.edit_note_rounded, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'التذييل والاعتماد وهوامش الطباعة',
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 1: Stamp switch & Doctor signature switch SIDE-BY-SIDE
          Row(
            children: [
              Expanded(
                child: _compactSwitchItem(
                  label: 'تضمين ختم العيادة المعتمد',
                  value: _template.includeOfficialStamp,
                  colors: colors,
                  onChanged: (val) => _updateTemplate(
                    () => _template.copyWith(includeOfficialStamp: val),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _compactSwitchItem(
                  label: 'تضمين توقيع الطبيب المعتمد',
                  value: _template.includeDoctorSignature,
                  colors: colors,
                  onChanged: (val) => _updateTemplate(
                    () => _template.copyWith(includeDoctorSignature: val),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Stamp text and Disclaimer side by side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_template.includeOfficialStamp) ...[
                Expanded(
                  flex: 4,
                  child: CustomTextFormField(
                    controller: _stampTextCtrl,
                    headerText: 'النص داخل الختم الرسمي',
                    hintText: 'مركز المهندسين - ختم معتمد',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: _template.includeOfficialStamp ? 6 : 10,
                child: CustomTextFormField(
                  controller: _disclaimerCtrl,
                  headerText: 'التنبيه القانوني وإخلاء المسؤولية',
                  hintText: 'صالح للصرف خلال 7 أيام...',
                  maxLine: 1,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 8),

          // Margins in one neat compact row
          Row(
            children: [
              Text(
                'هوامش الطباعة (mm):',
                style: CustomAppFontStyle.medium12.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        headerText: 'أعلى',
                        initialValue: _template.topMargin.toInt().toString(),
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 25.0;
                          _updateTemplate(() => _template.copyWith(topMargin: n));
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomTextFormField(
                        headerText: 'أسفل',
                        initialValue: _template.bottomMargin.toInt().toString(),
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 20.0;
                          _updateTemplate(() => _template.copyWith(bottomMargin: n));
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomTextFormField(
                        headerText: 'يمين',
                        initialValue: _template.rightMargin.toInt().toString(),
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 15.0;
                          _updateTemplate(() => _template.copyWith(rightMargin: n));
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomTextFormField(
                        headerText: 'يسار',
                        initialValue: _template.leftMargin.toInt().toString(),
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 15.0;
                          _updateTemplate(() => _template.copyWith(leftMargin: n));
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
    for (int i = 0; i < _addressCtrls.length; i += 2) {
      final ctrl1 = _addressCtrls[i];
      final idx1 = i;
      final hasSecond = (i + 1) < _addressCtrls.length;
      final ctrl2 = hasSecond ? _addressCtrls[i + 1] : null;
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
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_addressCtrls.length > 1) ...[
                      const SizedBox(width: 2),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: AppColors.error),
                        onPressed: () {
                          setState(() {
                            _addressCtrls.removeAt(idx1).dispose();
                          });
                        },
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
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: AppColors.error),
                        onPressed: () {
                          setState(() {
                            _addressCtrls.removeAt(idx2).dispose();
                          });
                        },
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
    for (int i = 0; i < _phoneCtrls.length; i += 2) {
      final ctrl1 = _phoneCtrls[i];
      final idx1 = i;
      final hasSecond = (i + 1) < _phoneCtrls.length;
      final ctrl2 = hasSecond ? _phoneCtrls[i + 1] : null;
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
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_phoneCtrls.length > 1) ...[
                      const SizedBox(width: 2),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: AppColors.error),
                        onPressed: () {
                          setState(() {
                            _phoneCtrls.removeAt(idx1).dispose();
                          });
                        },
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
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: AppColors.error),
                        onPressed: () {
                          setState(() {
                            _phoneCtrls.removeAt(idx2).dispose();
                          });
                        },
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

  Widget _compactSwitchItem({
    required String label,
    required bool value,
    required AppThemeColors colors,
    required void Function(bool) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: value
              ? colors.primary.withValues(alpha: 0.08)
              : colors.surfaceLevel1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? colors.primary : colors.borderSubtle,
            width: value ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CustomAppFontStyle.medium12.copyWith(
                  color: value ? colors.textPrimary : colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Transform.scale(
              scale: 0.75,
              child: Switch(
                value: value,
                activeThumbColor: colors.primary,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choiceChip({
    required String label,
    required bool selected,
    required AppThemeColors colors,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: colors.primary,
      backgroundColor: colors.surfaceLevel1,
      showCheckmark: false,
      labelStyle: CustomAppFontStyle.semiBold12.copyWith(
        color: selected ? Colors.white : colors.textPrimary,
      ),
      side: BorderSide(
        color: selected ? colors.primary : colors.borderSubtle,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
