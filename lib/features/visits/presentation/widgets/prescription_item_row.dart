import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../drugs/data/models/drug_model.dart';
import '../../../patients/domain/repo/medical_catalog_repo.dart';
import '../../data/models/prescription_item_model.dart';
import '../manager/visits_cubit.dart';
import 'dialogs/allergy_warning_dialog.dart';

class PrescriptionItemRow extends StatefulWidget {
  final VisitsCubit cubit;
  final String visitId;
  final String? patientId;
  final String? branchId;
  final PrescriptionItemModel? initialItem;
  final VoidCallback onCancel;

  const PrescriptionItemRow({
    super.key,
    required this.cubit,
    required this.visitId,
    this.patientId,
    this.branchId,
    this.initialItem,
    required this.onCancel,
  });

  @override
  State<PrescriptionItemRow> createState() => _PrescriptionItemRowState();
}

class _PrescriptionItemRowState extends State<PrescriptionItemRow> {
  final _tradeNameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _concentrationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();

  String? _nameError;

  final List<String> _frequencyPresets = const [
    'rx_freq_once_daily',
    'rx_freq_twice_daily',
    'rx_freq_thrice_daily',
    'rx_freq_four_times',
    'rx_freq_as_needed',
    'rx_freq_before_meals',
    'rx_freq_after_meals',
    'rx_freq_bedtime',
  ];

  final List<String> _durationPresets = const [
    'rx_duration_3_days',
    'rx_duration_5_days',
    'rx_duration_7_days',
    'rx_duration_10_days',
    'rx_duration_14_days',
    'rx_duration_1_month',
    'rx_duration_continuous',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _tradeNameController.text = item.tradeName ?? '';
      _scientificNameController.text = item.scientificName ?? '';
      _concentrationController.text = item.concentration ?? '';
      _dosageController.text = item.dosage ?? '';
      _frequencyController.text = item.frequency ?? '';
      _durationController.text = item.duration ?? '';
      _instructionsController.text = item.instructions ?? '';
    }
  }

  @override
  void dispose() {
    _tradeNameController.dispose();
    _scientificNameController.dispose();
    _concentrationController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _onSave() async {
    final tradeName = _tradeNameController.text.trim();
    if (tradeName.isEmpty) {
      setState(() => _nameError = 'drugs_trade_name'.tr());
      return;
    }

    final scientificName = _scientificNameController.text.trim().isEmpty
        ? null
        : _scientificNameController.text.trim();

    // Allergy check
    final drugCandidate = DrugModel(
      name: tradeName,
      scientificName: scientificName,
    );

    // Retrieve allergy catalog items if registered
    List<dynamic>? catalogItems;
    try {
      if (getIt.isRegistered<MedicalCatalogRepo>()) {
        final repo = getIt<MedicalCatalogRepo>();
        final res = await repo.getCatalogItems(type: 'allergy');
        catalogItems = res.getOrElse(() => []);
      }
    } catch (_) {}

    final match = widget.cubit.checkDrugAllergy(
      drug: drugCandidate,
      catalogItems: catalogItems?.cast(),
    );

    if (match.hasConflict &&
        !widget.cubit.state.formState.isAllergyWarningDismissed) {
      AuditLogger? logger;
      try {
        logger = getIt<AuditLogger>();
      } catch (_) {}

      if (!mounted) return;
      final proceed = await AllergyWarningDialog.show(
        context: context,
        drug: drugCandidate,
        matchResult: match,
        visitId: widget.visitId,
        patientId: widget.patientId,
        branchId: widget.branchId,
        auditLogger: logger,
      );

      if (proceed != true) {
        return; // Doctor canceled
      }
    }

    final item = PrescriptionItemModel(
      id: widget.initialItem?.id,
      drugId: widget.initialItem?.drugId,
      tradeName: tradeName,
      scientificName: scientificName,
      concentration: _concentrationController.text.trim().isEmpty
          ? null
          : _concentrationController.text.trim(),
      dosage: _dosageController.text.trim().isEmpty
          ? null
          : _dosageController.text.trim(),
      frequency: _frequencyController.text.trim().isEmpty
          ? null
          : _frequencyController.text.trim(),
      duration: _durationController.text.trim().isEmpty
          ? null
          : _durationController.text.trim(),
      instructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
      orderIndex: widget.initialItem?.orderIndex,
    );

    if (widget.initialItem != null) {
      widget.cubit.updatePrescriptionItem(item);
    } else {
      widget.cubit.addPrescriptionItem(item);
    }

    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: CustomTextFormField(
                  controller: _tradeNameController,
                  headerText: 'drugs_trade_name'.tr(),
                  hintText: 'drugs_trade_name_hint'.tr(),
                  validator: (_) => _nameError,
                  onChanged: (_) {
                    if (_nameError != null) {
                      setState(() => _nameError = null);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: CustomTextFormField(
                  controller: _scientificNameController,
                  headerText: 'drugs_scientific_name'.tr(),
                  hintText: 'drugs_scientific_name_hint'.tr(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CustomTextFormField(
                  controller: _concentrationController,
                  headerText: 'drugs_concentration'.tr(),
                  hintText: 'drugs_concentration_hint'.tr(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextFormField(
                  controller: _dosageController,
                  headerText: 'rx_col_dosage'.tr(),
                  hintText: 'drugs_dosage_hint'.tr(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'rx_col_frequency'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: AppColors.darkText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.arrow_drop_down_circle_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          tooltip: 'rx_col_frequency'.tr(),
                          onSelected: (val) {
                            _frequencyController.text = val.tr();
                          },
                          itemBuilder: (context) {
                            return _frequencyPresets.map((preset) {
                              return PopupMenuItem(
                                value: preset,
                                child: Text(preset.tr()),
                              );
                            }).toList();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _frequencyController,
                      decoration: InputDecoration(
                        hintText: 'rx_freq_twice_daily'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'rx_col_duration'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: AppColors.darkText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.arrow_drop_down_circle_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          tooltip: 'rx_col_duration'.tr(),
                          onSelected: (val) {
                            _durationController.text = val.tr();
                          },
                          itemBuilder: (context) {
                            return _durationPresets.map((preset) {
                              return PopupMenuItem(
                                value: preset,
                                child: Text(preset.tr()),
                              );
                            }).toList();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _durationController,
                      decoration: InputDecoration(
                        hintText: 'rx_duration_7_days'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextFormField(
            controller: _instructionsController,
            headerText: 'rx_col_instructions'.tr(),
            hintText: 'rx_freq_after_meals'.tr(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: Text(
                  'cancel'.tr(),
                  style: CustomAppFontStyle.medium14.copyWith(
                    color: AppColors.gray71717A,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CustomPushButton(
                height: 38,
                width: 120,
                backgroundColor: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                onTap: _onSave,
                child: Center(
                  child: Text(
                    'save'.tr(),
                    style: CustomAppFontStyle.bold13.copyWith(
                      color: AppColors.white,
                    ),
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
