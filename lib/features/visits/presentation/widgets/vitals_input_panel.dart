import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../data/models/vitals_model.dart';

class VitalsInputPanel extends StatefulWidget {
  final VitalsModel vitals;
  final ValueChanged<VitalsModel> onVitalsChanged;
  final bool isReadOnly;

  const VitalsInputPanel({
    super.key,
    required this.vitals,
    required this.onVitalsChanged,
    this.isReadOnly = false,
  });

  @override
  State<VitalsInputPanel> createState() => _VitalsInputPanelState();
}

class _VitalsInputPanelState extends State<VitalsInputPanel> {
  late final TextEditingController _systolicController;
  late final TextEditingController _diastolicController;
  late final TextEditingController _heartRateController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _oxygenController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _systolicController = TextEditingController(
      text: widget.vitals.systolicBp?.toString() ?? '',
    );
    _diastolicController = TextEditingController(
      text: widget.vitals.diastolicBp?.toString() ?? '',
    );
    _heartRateController = TextEditingController(
      text: widget.vitals.heartRate?.toString() ?? '',
    );
    _temperatureController = TextEditingController(
      text: widget.vitals.temperature?.toString() ?? '',
    );
    _oxygenController = TextEditingController(
      text: widget.vitals.oxygenSaturation?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.vitals.weightKg?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.vitals.heightCm?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant VitalsInputPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vitals != oldWidget.vitals) {
      _syncTextIfDifferent(_systolicController, widget.vitals.systolicBp?.toString());
      _syncTextIfDifferent(_diastolicController, widget.vitals.diastolicBp?.toString());
      _syncTextIfDifferent(_heartRateController, widget.vitals.heartRate?.toString());
      _syncTextIfDifferent(_temperatureController, widget.vitals.temperature?.toString());
      _syncTextIfDifferent(_oxygenController, widget.vitals.oxygenSaturation?.toString());
      _syncTextIfDifferent(_weightController, widget.vitals.weightKg?.toString());
      _syncTextIfDifferent(_heightController, widget.vitals.heightCm?.toString());
    }
  }

  void _syncTextIfDifferent(TextEditingController controller, String? value) {
    final target = value ?? '';
    if (controller.text != target && !controller.value.isComposingRangeValid) {
      controller.text = target;
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _temperatureController.dispose();
    _oxygenController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _notifyUpdate({
    int? systolicBp,
    int? diastolicBp,
    int? heartRate,
    double? temperature,
    int? oxygenSaturation,
    double? weightKg,
    double? heightCm,
    bool clearSystolic = false,
    bool clearDiastolic = false,
    bool clearHeartRate = false,
    bool clearTemperature = false,
    bool clearOxygen = false,
    bool clearWeight = false,
    bool clearHeight = false,
  }) {
    widget.onVitalsChanged(
      widget.vitals.copyWith(
        systolicBp: clearSystolic ? null : (systolicBp ?? widget.vitals.systolicBp),
        diastolicBp: clearDiastolic ? null : (diastolicBp ?? widget.vitals.diastolicBp),
        heartRate: clearHeartRate ? null : (heartRate ?? widget.vitals.heartRate),
        temperature: clearTemperature ? null : (temperature ?? widget.vitals.temperature),
        oxygenSaturation:
            clearOxygen ? null : (oxygenSaturation ?? widget.vitals.oxygenSaturation),
        weightKg: clearWeight ? null : (weightKg ?? widget.vitals.weightKg),
        heightCm: clearHeight ? null : (heightCm ?? widget.vitals.heightCm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bmi = widget.vitals.bmi;
    String? bmiCategory;
    if (bmi != null) {
      if (bmi < 18.5) {
        bmiCategory = 'visits_bmi_underweight'.tr();
      } else if (bmi < 25.0) {
        bmiCategory = 'visits_bmi_normal'.tr();
      } else if (bmi < 30.0) {
        bmiCategory = 'visits_bmi_overweight'.tr();
      } else {
        bmiCategory = 'visits_bmi_obese'.tr();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Row 1: Blood Pressure (Systolic + Diastolic) ─────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFieldWithWarning(
                controller: _systolicController,
                headerText: 'visits_systolic_bp'.tr(),
                hintText: '120',
                warningKey: widget.vitals.systolicBpWarning,
                onChanged: (val) {
                  final parsed = int.tryParse((val ?? '').trim());
                  _notifyUpdate(
                    systolicBp: parsed,
                    clearSystolic: parsed == null,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFieldWithWarning(
                controller: _diastolicController,
                headerText: 'visits_diastolic_bp'.tr(),
                hintText: '80',
                warningKey: widget.vitals.diastolicBpWarning,
                onChanged: (val) {
                  final parsed = int.tryParse((val ?? '').trim());
                  _notifyUpdate(
                    diastolicBp: parsed,
                    clearDiastolic: parsed == null,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─── Row 2: Heart Rate & Temperature ──────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFieldWithWarning(
                controller: _heartRateController,
                headerText: 'visits_heart_rate'.tr(),
                hintText: '75',
                warningKey: widget.vitals.heartRateWarning,
                onChanged: (val) {
                  final parsed = int.tryParse((val ?? '').trim());
                  _notifyUpdate(
                    heartRate: parsed,
                    clearHeartRate: parsed == null,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFieldWithWarning(
                controller: _temperatureController,
                headerText: 'visits_temperature'.tr(),
                hintText: '37.0',
                warningKey: widget.vitals.temperatureWarning,
                isDecimal: true,
                onChanged: (val) {
                  final parsed = double.tryParse((val ?? '').trim());
                  _notifyUpdate(
                    temperature: parsed,
                    clearTemperature: parsed == null,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─── Row 3: Oxygen Saturation ─────────────────────────────────
        _buildFieldWithWarning(
          controller: _oxygenController,
          headerText: 'visits_oxygen_saturation'.tr(),
          hintText: '98',
          warningKey: widget.vitals.oxygenSaturationWarning,
          onChanged: (val) {
            final parsed = int.tryParse((val ?? '').trim());
            _notifyUpdate(
              oxygenSaturation: parsed,
              clearOxygen: parsed == null,
            );
          },
        ),
        const SizedBox(height: 12),

        // ─── Row 4: Weight & Height ───────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFieldWithWarning(
                controller: _weightController,
                headerText: 'visits_weight_kg'.tr(),
                hintText: '70',
                warningKey: widget.vitals.weightWarning,
                isDecimal: true,
                onChanged: (val) {
                  final parsed = double.tryParse((val ?? '').trim());
                  _notifyUpdate(
                    weightKg: parsed,
                    clearWeight: parsed == null,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFieldWithWarning(
                controller: _heightController,
                headerText: 'visits_height_cm'.tr(),
                hintText: '175',
                warningKey: widget.vitals.heightWarning,
                isDecimal: true,
                onChanged: (val) {
                  final parsed = double.tryParse((val ?? '').trim());
                  _notifyUpdate(
                    heightCm: parsed,
                    clearHeight: parsed == null,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─── BMI Display (Calculated) ─────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // Slate 50
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFE2E8F0), // Slate 200
              width: 0.8,
            ),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                '${'visits_bmi'.tr()}: ',
                style: CustomAppFontStyle.bold14.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              Text(
                bmi != null ? '$bmi' : '—',
                style: CustomAppFontStyle.bold14.copyWith(
                  color: AppColors.primary,
                ),
              ),
              if (bmiCategory != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    bmiCategory,
                    style: CustomAppFontStyle.medium12.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldWithWarning({
    required TextEditingController controller,
    required String headerText,
    required String hintText,
    required String? warningKey,
    required void Function(String?) onChanged,
    bool isDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextFormField(
          controller: controller,
          headerText: headerText,
          hintText: hintText,
          isReadOnly: widget.isReadOnly,
          isEnabled: !widget.isReadOnly,
          textInputType: TextInputType.numberWithOptions(decimal: isDecimal),
          inputFormatters: [
            if (isDecimal)
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            else
              FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: onChanged,
        ),
        if (warningKey != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFD97706), // Amber 600
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  warningKey.tr(),
                  style: CustomAppFontStyle.medium12.copyWith(
                    color: const Color(0xFFD97706), // Amber 600
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
