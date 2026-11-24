import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/prescription_template_model.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_state.dart';
import 'package:eyadty/features/visits/data/models/prescription_item_model.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/presentation/helpers/prescription_pdf_generator.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

import 'components/prescription_document_tabs.dart';
import 'components/prescription_live_preview.dart';
import 'components/prescription_preset_dialog.dart';
import 'components/prescription_top_bar.dart';
import 'panels/prescription_assets_panel.dart';
import 'panels/prescription_back_page_panel.dart';
import 'panels/prescription_branches_panel.dart';
import 'panels/prescription_clinical_panel.dart';
import 'panels/prescription_header_studio_panel.dart';

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

  // Preview face: 0: وجه الروشتة (Front Page), 1: ظهر الروشتة (Back Page)
  int _previewFace = 0;

  // Preview controls
  double _zoomScale = 0.70;
  bool _showMarginGuides = false;
  bool _isGrayscalePreview = false;

  // Controllers for editable fields
  late final TextEditingController _doctorNameCtrl;
  late final TextEditingController _clinicNameCtrl;
  late final TextEditingController _doctorTitleCtrl;
  late final TextEditingController _englishDoctorNameCtrl;
  late final TextEditingController _englishDoctorTitleCtrl;
  late final TextEditingController _medicalLicenseCtrl;
  late final TextEditingController _ministryLicenseCtrl;
  late final TextEditingController _disclaimerCtrl;
  late final TextEditingController _watermarkTextCtrl;
  late final TextEditingController _stampTextCtrl;
  final List<TextEditingController> _addressCtrls = [];
  final List<TextEditingController> _phoneCtrls = [];

  // Controllers for Heights and 4-way Margins (Header, Body, Footer)
  late final TextEditingController _headerHeightCtrl;
  late final TextEditingController _footerHeightCtrl;
  late final TextEditingController _headerMarginTopCtrl;
  late final TextEditingController _headerMarginBottomCtrl;
  late final TextEditingController _headerMarginRightCtrl;
  late final TextEditingController _headerMarginLeftCtrl;
  late final TextEditingController _bodyMarginTopCtrl;
  late final TextEditingController _bodyMarginBottomCtrl;
  late final TextEditingController _bodyMarginRightCtrl;
  late final TextEditingController _bodyMarginLeftCtrl;
  late final TextEditingController _footerMarginTopCtrl;
  late final TextEditingController _footerMarginBottomCtrl;
  late final TextEditingController _footerMarginRightCtrl;
  late final TextEditingController _footerMarginLeftCtrl;

  // Controllers for Back of Prescription (ظهر الروشتة)
  late final TextEditingController _backPageTitleCtrl;
  late final TextEditingController _backPageDietCtrl;
  late final TextEditingController _backPageEmergencyCtrl;
  late final TextEditingController _backPageFooterCtrl;
  final List<TextEditingController> _backInstructionsCtrls = [];
  late final TextEditingController _followUpTextCtrl;

  @override
  void initState() {
    super.initState();
    _template = const PrescriptionTemplateModel();
    _doctorNameCtrl = TextEditingController(text: _template.doctorDisplayName);
    _clinicNameCtrl = TextEditingController(text: _template.clinicDisplayName);
    _doctorTitleCtrl = TextEditingController(text: _template.doctorTitle);
    _englishDoctorNameCtrl =
        TextEditingController(text: _template.englishDoctorName);
    _englishDoctorTitleCtrl =
        TextEditingController(text: _template.englishDoctorTitle);
    _medicalLicenseCtrl =
        TextEditingController(text: _template.medicalLicenseNumber);
    _ministryLicenseCtrl =
        TextEditingController(text: _template.ministryLicenseNumber);
    _disclaimerCtrl = TextEditingController(text: _template.legalDisclaimer);
    _watermarkTextCtrl =
        TextEditingController(text: _template.watermarkCustomText);
    _stampTextCtrl = TextEditingController(text: _template.officialStampText);
    _followUpTextCtrl = TextEditingController(text: _template.followUpText);

    _headerHeightCtrl =
        TextEditingController(text: _template.headerHeight.toInt().toString());
    _footerHeightCtrl =
        TextEditingController(text: _template.footerHeight.toInt().toString());

    _headerMarginTopCtrl =
        TextEditingController(text: _template.headerMarginTop.toInt().toString());
    _headerMarginBottomCtrl = TextEditingController(
        text: _template.headerMarginBottom.toInt().toString());
    _headerMarginRightCtrl = TextEditingController(
        text: _template.headerMarginRight.toInt().toString());
    _headerMarginLeftCtrl = TextEditingController(
        text: _template.headerMarginLeft.toInt().toString());

    _bodyMarginTopCtrl =
        TextEditingController(text: _template.bodyMarginTop.toInt().toString());
    _bodyMarginBottomCtrl =
        TextEditingController(text: _template.bodyMarginBottom.toInt().toString());
    _bodyMarginRightCtrl =
        TextEditingController(text: _template.bodyMarginRight.toInt().toString());
    _bodyMarginLeftCtrl =
        TextEditingController(text: _template.bodyMarginLeft.toInt().toString());

    _footerMarginTopCtrl =
        TextEditingController(text: _template.footerMarginTop.toInt().toString());
    _footerMarginBottomCtrl = TextEditingController(
        text: _template.footerMarginBottom.toInt().toString());
    _footerMarginRightCtrl = TextEditingController(
        text: _template.footerMarginRight.toInt().toString());
    _footerMarginLeftCtrl =
        TextEditingController(text: _template.footerMarginLeft.toInt().toString());

    _backPageTitleCtrl = TextEditingController(text: _template.backPageTitle);
    _backPageDietCtrl =
        TextEditingController(text: _template.backPageDietAdvice);
    _backPageEmergencyCtrl =
        TextEditingController(text: _template.backPageEmergencyNotes);
    _backPageFooterCtrl =
        TextEditingController(text: _template.backPageFooterNotes);

    _syncAddressControllers(_template.addresses);
    _syncPhoneControllers(_template.phoneNumbers);
    _syncBackInstructionControllers(_template.backPageInstructions);

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

  void _syncBackInstructionControllers(List<String> items) {
    for (final c in _backInstructionsCtrls) {
      c.dispose();
    }
    _backInstructionsCtrls.clear();
    for (final it in items) {
      _backInstructionsCtrls.add(TextEditingController(text: it));
    }
  }

  void _loadFromSettings(PrescriptionTemplateModel template) {
    _template = template;
    _doctorNameCtrl.text = template.doctorDisplayName;
    _clinicNameCtrl.text = template.clinicDisplayName;
    _doctorTitleCtrl.text = template.doctorTitle;
    _englishDoctorNameCtrl.text = template.englishDoctorName;
    _englishDoctorTitleCtrl.text = template.englishDoctorTitle;
    _medicalLicenseCtrl.text = template.medicalLicenseNumber;
    _ministryLicenseCtrl.text = template.ministryLicenseNumber;
    _disclaimerCtrl.text = template.legalDisclaimer;
    _watermarkTextCtrl.text = template.watermarkCustomText;
    _stampTextCtrl.text = template.officialStampText;
    _headerHeightCtrl.text = template.headerHeight.toInt().toString();
    _footerHeightCtrl.text = template.footerHeight.toInt().toString();

    _headerMarginTopCtrl.text = template.headerMarginTop.toInt().toString();
    _headerMarginBottomCtrl.text =
        template.headerMarginBottom.toInt().toString();
    _headerMarginRightCtrl.text = template.headerMarginRight.toInt().toString();
    _headerMarginLeftCtrl.text = template.headerMarginLeft.toInt().toString();

    _bodyMarginTopCtrl.text = template.bodyMarginTop.toInt().toString();
    _bodyMarginBottomCtrl.text = template.bodyMarginBottom.toInt().toString();
    _bodyMarginRightCtrl.text = template.bodyMarginRight.toInt().toString();
    _bodyMarginLeftCtrl.text = template.bodyMarginLeft.toInt().toString();

    _footerMarginTopCtrl.text = template.footerMarginTop.toInt().toString();
    _footerMarginBottomCtrl.text =
        template.footerMarginBottom.toInt().toString();
    _footerMarginRightCtrl.text = template.footerMarginRight.toInt().toString();
    _footerMarginLeftCtrl.text = template.footerMarginLeft.toInt().toString();

    _backPageTitleCtrl.text = template.backPageTitle;
    _backPageDietCtrl.text = template.backPageDietAdvice;
    _backPageEmergencyCtrl.text = template.backPageEmergencyNotes;
    _backPageFooterCtrl.text = template.backPageFooterNotes;
    _followUpTextCtrl.text = template.followUpText;

    _syncAddressControllers(template.addresses);
    _syncPhoneControllers(template.phoneNumbers);
    _syncBackInstructionControllers(template.backPageInstructions);
    _initialized = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      try {
        final cubit = widget.settingsCubit ?? context.read<SettingsCubit>();
        if (cubit.state.settings != null) {
          _loadFromSettings(cubit.state.settings!.effectivePrescriptionTemplate);
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _doctorNameCtrl.dispose();
    _clinicNameCtrl.dispose();
    _doctorTitleCtrl.dispose();
    _englishDoctorNameCtrl.dispose();
    _englishDoctorTitleCtrl.dispose();
    _medicalLicenseCtrl.dispose();
    _ministryLicenseCtrl.dispose();
    _disclaimerCtrl.dispose();
    _watermarkTextCtrl.dispose();
    _stampTextCtrl.dispose();
    _followUpTextCtrl.dispose();
    _headerHeightCtrl.dispose();
    _footerHeightCtrl.dispose();
    _headerMarginTopCtrl.dispose();
    _headerMarginBottomCtrl.dispose();
    _headerMarginRightCtrl.dispose();
    _headerMarginLeftCtrl.dispose();
    _bodyMarginTopCtrl.dispose();
    _bodyMarginBottomCtrl.dispose();
    _bodyMarginRightCtrl.dispose();
    _bodyMarginLeftCtrl.dispose();
    _footerMarginTopCtrl.dispose();
    _footerMarginBottomCtrl.dispose();
    _footerMarginRightCtrl.dispose();
    _footerMarginLeftCtrl.dispose();
    _backPageTitleCtrl.dispose();
    _backPageDietCtrl.dispose();
    _backPageEmergencyCtrl.dispose();
    _backPageFooterCtrl.dispose();
    for (final c in _addressCtrls) {
      c.dispose();
    }
    for (final c in _phoneCtrls) {
      c.dispose();
    }
    for (final c in _backInstructionsCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateTemplate(PrescriptionTemplateModel Function() updater) {
    setState(() {
      _template = updater();
    });
  }

  Future<void> _pickImage(void Function(String base64) onPicked) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        final b64 = base64Encode(bytes);
        onPicked(b64);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        CustomToast(
          context: context,
          header: 'تعذر رفع الصورة: $e',
        ).showTopToast();
      }
    }
  }

  Future<void> _handleSaveTemplate() async {
    final cubit = widget.settingsCubit ?? context.read<SettingsCubit>();

    final updated = _template.copyWith(
      doctorDisplayName: _doctorNameCtrl.text.trim(),
      clinicDisplayName: _clinicNameCtrl.text.trim(),
      doctorTitle: _doctorTitleCtrl.text.trim(),
      englishDoctorName: _englishDoctorNameCtrl.text.trim(),
      englishDoctorTitle: _englishDoctorTitleCtrl.text.trim(),
      medicalLicenseNumber: _medicalLicenseCtrl.text.trim(),
      ministryLicenseNumber: _ministryLicenseCtrl.text.trim(),
      legalDisclaimer: _disclaimerCtrl.text.trim(),
      watermarkCustomText: _watermarkTextCtrl.text.trim(),
      officialStampText: _stampTextCtrl.text.trim(),
      headerHeight: double.tryParse(_headerHeightCtrl.text.trim()) ??
          _template.headerHeight,
      footerHeight: double.tryParse(_footerHeightCtrl.text.trim()) ??
          _template.footerHeight,
      headerMarginTop: double.tryParse(_headerMarginTopCtrl.text.trim()) ??
          _template.headerMarginTop,
      headerMarginBottom:
          double.tryParse(_headerMarginBottomCtrl.text.trim()) ??
              _template.headerMarginBottom,
      headerMarginRight:
          double.tryParse(_headerMarginRightCtrl.text.trim()) ??
              _template.headerMarginRight,
      headerMarginLeft:
          double.tryParse(_headerMarginLeftCtrl.text.trim()) ??
              _template.headerMarginLeft,
      bodyMarginTop: double.tryParse(_bodyMarginTopCtrl.text.trim()) ??
          _template.bodyMarginTop,
      bodyMarginBottom: double.tryParse(_bodyMarginBottomCtrl.text.trim()) ??
          _template.bodyMarginBottom,
      bodyMarginRight: double.tryParse(_bodyMarginRightCtrl.text.trim()) ??
          _template.bodyMarginRight,
      bodyMarginLeft: double.tryParse(_bodyMarginLeftCtrl.text.trim()) ??
          _template.bodyMarginLeft,
      footerMarginTop: double.tryParse(_footerMarginTopCtrl.text.trim()) ??
          _template.footerMarginTop,
      footerMarginBottom:
          double.tryParse(_footerMarginBottomCtrl.text.trim()) ??
              _template.footerMarginBottom,
      footerMarginRight:
          double.tryParse(_footerMarginRightCtrl.text.trim()) ??
              _template.footerMarginRight,
      footerMarginLeft:
          double.tryParse(_footerMarginLeftCtrl.text.trim()) ??
              _template.footerMarginLeft,
      addresses: _addressCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      phoneNumbers: _phoneCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      backPageTitle: _backPageTitleCtrl.text.trim(),
      backPageDietAdvice: _backPageDietCtrl.text.trim(),
      backPageEmergencyNotes: _backPageEmergencyCtrl.text.trim(),
      backPageFooterNotes: _backPageFooterCtrl.text.trim(),
      backPageInstructions: _backInstructionsCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      followUpText: _followUpTextCtrl.text.trim(),
    );

    final success = await cubit.updatePrescriptionTemplate(updated);
    if (!mounted) return;
    if (success) {
      CustomToast(
        context: context,
        header: 'تم حفظ وتطبيق قالب الروشتة والمطبوعات بنجاح',
      ).showTopToast();
    } else {
      CustomToast(
        context: context,
        header: cubit.state.errMessage ?? 'فشل في حفظ قالب الروشتة',
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
          frequency:
              'قرص عند الشعور بالصداع أو ارتفاع درجة الحرارة (بحد أقصى 3 مرات يومياً)',
          instructions: 'عند اللزوم فقط',
        ),
        const PrescriptionItemModel(
          tradeName: 'Concor 5mg Tab (Bisoprolol Fumarate)',
          dosage: 'قرص 5 ملجم',
          frequency:
              'قرص واحد صباحاً يومياً قبل وجبة الإفطار مع قياس الضغط أسبوعياً',
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
    setState(() {});
    CustomToast(
      context: context,
      header: 'تمت استعادة الإعدادات القياسية لنموذج الروشتة بنجاح',
    ).showTopToast();
  }

  void _openPresetsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ClinicSpecialtyPresetsDialog(
        currentTemplate: _template,
        onPresetSelected: (presetTemplate) {
          _loadFromSettings(presetTemplate);
          setState(() {});
        },
      ),
    );
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

        final topBar = PrescriptionTopBar(
          isLoading: isLoading,
          onOpenPresets: _openPresetsDialog,
          onResetDefault: _handleResetDefault,
          onPrintTestPage: _handlePrintTestPage,
          onSaveTemplate: _handleSaveTemplate,
        );

        final docTabs = PrescriptionDocumentTabs(
          activeTab: _activeTopTab,
          onTabChanged: (tab) => setState(() => _activeTopTab = tab),
        );

        final livePreview = PrescriptionLivePreview(
          template: _template,
          previewFace: _previewFace,
          onFaceChanged: (face) => setState(() => _previewFace = face),
          zoomScale: _zoomScale,
          onZoomChanged: (z) => setState(() => _zoomScale = z),
          showMarginGuides: _showMarginGuides,
          onToggleMarginGuides: (v) => setState(() => _showMarginGuides = v),
          isGrayscalePreview: _isGrayscalePreview,
          onToggleGrayscale: (v) => setState(() => _isGrayscalePreview = v),
          onPaperSizeChanged: (size) => _updateTemplate(
            () => _template.copyWith(defaultPaperSize: size),
          ),
          doctorNameCtrl: _doctorNameCtrl,
          englishDoctorNameCtrl: _englishDoctorNameCtrl,
          doctorTitleCtrl: _doctorTitleCtrl,
          englishDoctorTitleCtrl: _englishDoctorTitleCtrl,
          clinicNameCtrl: _clinicNameCtrl,
          medicalLicenseCtrl: _medicalLicenseCtrl,
          ministryLicenseCtrl: _ministryLicenseCtrl,
          addressCtrls: _addressCtrls,
          phoneCtrls: _phoneCtrls,
          watermarkTextCtrl: _watermarkTextCtrl,
          backPageTitleCtrl: _backPageTitleCtrl,
          backInstructionsCtrls: _backInstructionsCtrls,
          backPageDietCtrl: _backPageDietCtrl,
          backPageEmergencyCtrl: _backPageEmergencyCtrl,
          backPageFooterCtrl: _backPageFooterCtrl,
        );

        final rightControls = _buildRightControls();

        if (isMobile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                topBar,
                const SizedBox(height: 12),
                docTabs,
                const SizedBox(height: 16),
                rightControls,
                const SizedBox(height: 20),
                livePreview,
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              topBar,
              const SizedBox(height: 10),
              docTabs,
              const SizedBox(height: 12),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column: Live A4 Preview
                    Expanded(
                      flex: 48,
                      child: livePreview,
                    ),
                    const SizedBox(width: 14),
                    // Right Column: Scrollable Settings Studio Panels
                    Expanded(
                      flex: 52,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: rightControls,
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

  Widget _buildRightControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Panel 1: Header Studio & Banner Upload ────────────────
        PrescriptionHeaderStudioPanel(
          template: _template,
          doctorNameCtrl: _doctorNameCtrl,
          englishDoctorNameCtrl: _englishDoctorNameCtrl,
          doctorTitleCtrl: _doctorTitleCtrl,
          englishDoctorTitleCtrl: _englishDoctorTitleCtrl,
          clinicNameCtrl: _clinicNameCtrl,
          medicalLicenseCtrl: _medicalLicenseCtrl,
          ministryLicenseCtrl: _ministryLicenseCtrl,
          headerHeightCtrl: _headerHeightCtrl,
          updateTemplate: _updateTemplate,
          onPickImage: _pickImage,
          onStateChanged: () => setState(() {}),
        ),
        const SizedBox(height: 12),

        // ─── Panel 2: Branches & Hotlines ──────────────────────────
        PrescriptionBranchesPanel(
          template: _template,
          addressCtrls: _addressCtrls,
          phoneCtrls: _phoneCtrls,
          footerHeightCtrl: _footerHeightCtrl,
          footerMarginTopCtrl: _footerMarginTopCtrl,
          footerMarginBottomCtrl: _footerMarginBottomCtrl,
          footerMarginRightCtrl: _footerMarginRightCtrl,
          footerMarginLeftCtrl: _footerMarginLeftCtrl,
          updateTemplate: _updateTemplate,
          onAddAddress: () {
            setState(() {
              _addressCtrls.add(TextEditingController());
            });
          },
          onRemoveAddress: (idx) {
            setState(() {
              _addressCtrls.removeAt(idx).dispose();
            });
          },
          onAddPhone: () {
            setState(() {
              _phoneCtrls.add(TextEditingController());
            });
          },
          onRemovePhone: (idx) {
            setState(() {
              _phoneCtrls.removeAt(idx).dispose();
            });
          },
          onStateChanged: () => setState(() {}),
        ),
        const SizedBox(height: 12),

        // ─── Panel 3: Uploaded Images, QR, Watermark & Stamp ───────
        PrescriptionAssetsPanel(
          template: _template,
          watermarkTextCtrl: _watermarkTextCtrl,
          stampTextCtrl: _stampTextCtrl,
          updateTemplate: _updateTemplate,
          onPickImage: _pickImage,
          onStateChanged: () => setState(() {}),
        ),
        const SizedBox(height: 12),

        // ─── Panel 4: Clinical Data & Margins ──────────────────────
        PrescriptionClinicalPanel(
          template: _template,
          disclaimerCtrl: _disclaimerCtrl,
          followUpTextCtrl: _followUpTextCtrl,
          headerHeightCtrl: _headerHeightCtrl,
          headerMarginTopCtrl: _headerMarginTopCtrl,
          headerMarginBottomCtrl: _headerMarginBottomCtrl,
          headerMarginRightCtrl: _headerMarginRightCtrl,
          headerMarginLeftCtrl: _headerMarginLeftCtrl,
          bodyMarginTopCtrl: _bodyMarginTopCtrl,
          bodyMarginBottomCtrl: _bodyMarginBottomCtrl,
          bodyMarginRightCtrl: _bodyMarginRightCtrl,
          bodyMarginLeftCtrl: _bodyMarginLeftCtrl,
          updateTemplate: _updateTemplate,
          onStateChanged: () => setState(() {}),
        ),
        const SizedBox(height: 12),

        // ─── Panel 5: Back Page Designer (ظهر الروشتة) ─────────────
        PrescriptionBackPagePanel(
          template: _template,
          backPageTitleCtrl: _backPageTitleCtrl,
          backInstructionsCtrls: _backInstructionsCtrls,
          backPageDietCtrl: _backPageDietCtrl,
          backPageEmergencyCtrl: _backPageEmergencyCtrl,
          backPageFooterCtrl: _backPageFooterCtrl,
          updateTemplate: _updateTemplate,
          onPickImage: _pickImage,
          onSyncBackInstructions: _syncBackInstructionControllers,
          onFaceChanged: (face) => setState(() => _previewFace = face),
          onStateChanged: () => setState(() {}),
        ),
      ],
    );
  }
}
