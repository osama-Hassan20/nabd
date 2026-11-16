import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/hr/data/models/doctor_compensation_rule_model.dart';
import 'package:eyadty/features/hr/data/models/enums/compensation_type_enum.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_state.dart';

class DoctorCompensationRuleDialog extends StatefulWidget {
  final DoctorCompensationRuleModel? rule;
  final String? initialDoctorId;

  const DoctorCompensationRuleDialog({
    super.key,
    this.rule,
    this.initialDoctorId,
  });

  @override
  State<DoctorCompensationRuleDialog> createState() => _DoctorCompensationRuleDialogState();
}

class _DoctorCompensationRuleDialogState extends State<DoctorCompensationRuleDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _doctorIdController;
  late TextEditingController _branchIdController;
  late TextEditingController _percentageController;
  late TextEditingController _fixedFeeController;
  late TextEditingController _baseSalaryController;
  late TextEditingController _notesController;
  late TextEditingController _typeController;

  CompensationTypeEnum _selectedType = CompensationTypeEnum.percentage;
  DateTime _effectiveFrom = CairoTimeHelper.now();
  bool _payForFreeVisits = false;

  String _compTypeLabel(CompensationTypeEnum type) {
    switch (type) {
      case CompensationTypeEnum.percentage:
        return 'hr_comp_type_percentage'.tr();
      case CompensationTypeEnum.fixedPerVisit:
        return 'hr_comp_type_fixed'.tr();
      case CompensationTypeEnum.salaryOnly:
        return 'hr_comp_type_salary'.tr();
      case CompensationTypeEnum.salaryPlusPercentage:
        return 'hr_comp_type_salary_plus_pct'.tr();
      case CompensationTypeEnum.salaryPlusFixed:
        return 'hr_comp_type_salary_plus_fixed'.tr();
    }
  }

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _doctorIdController = TextEditingController(text: r?.doctorId ?? widget.initialDoctorId ?? '');
    _branchIdController = TextEditingController(text: r?.branchId ?? 'branch_1');
    _percentageController = TextEditingController(text: r?.commissionPercentage != null ? '${r!.commissionPercentage}' : '');
    _fixedFeeController = TextEditingController(
      text: r?.fixedAmountPerVisitPiastres != null ? '${(r!.fixedAmountPerVisitPiastres! / 100).round()}' : '',
    );
    _baseSalaryController = TextEditingController(
      text: r?.monthlyBaseSalaryPiastres != null ? '${(r!.monthlyBaseSalaryPiastres! / 100).round()}' : '',
    );
    _notesController = TextEditingController(text: r?.notes ?? '');
    _selectedType = r?.compensationType ?? CompensationTypeEnum.percentage;
    _typeController = TextEditingController(text: _compTypeLabel(_selectedType));
    _effectiveFrom = r?.effectiveFrom ?? CairoTimeHelper.now();
    _payForFreeVisits = r?.payForFreeVisits ?? false;
  }

  @override
  void dispose() {
    _doctorIdController.dispose();
    _branchIdController.dispose();
    _percentageController.dispose();
    _fixedFeeController.dispose();
    _baseSalaryController.dispose();
    _notesController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  bool get _showsPercentage =>
      _selectedType == CompensationTypeEnum.percentage ||
      _selectedType == CompensationTypeEnum.salaryPlusPercentage;

  bool get _showsFixedFee =>
      _selectedType == CompensationTypeEnum.fixedPerVisit ||
      _selectedType == CompensationTypeEnum.salaryPlusFixed;

  bool get _showsBaseSalary =>
      _selectedType == CompensationTypeEnum.salaryOnly ||
      _selectedType == CompensationTypeEnum.salaryPlusPercentage ||
      _selectedType == CompensationTypeEnum.salaryPlusFixed;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HrCubit, HrState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          CustomToast(
            context: context,
            header: state.errorMessage!.tr(),
          ).showErrorToast();
        }
      },
      builder: (context, state) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 560,
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'hr_rule_dialog_title'.tr(),
                            style: CustomAppFontStyle.bold18.copyWith(color: AppColors.darkText),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: AppColors.gray71717A),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Doctor ID
                    CustomTextFormField(
                      controller: _doctorIdController,
                      hintText: 'hr_doctor_id_hint'.tr(),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'hr_doctor_id_required'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Compensation Type Selector
                    CustomStackSelector<CompensationTypeEnum>(
                      key: const Key('dropdown_compensation_type'),
                      controller: _typeController,
                      header: 'hr_compensation_type_label'.tr(),
                      list: const [
                        CompensationTypeEnum.percentage,
                        CompensationTypeEnum.fixedPerVisit,
                        CompensationTypeEnum.salaryOnly,
                        CompensationTypeEnum.salaryPlusPercentage,
                        CompensationTypeEnum.salaryPlusFixed,
                      ],
                      itemAsString: _compTypeLabel,
                      changeValue: (val) {
                        setState(() {
                          _selectedType = val;
                          _typeController.text = _compTypeLabel(val);
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Dynamic: Percentage Field
                    if (_showsPercentage) ...[
                      CustomTextFormField(
                        key: const Key('field_commission_percentage'),
                        controller: _percentageController,
                        hintText: 'hr_commission_percentage_hint'.tr(),
                        textInputType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'hr_invalid_commission_percentage'.tr();
                          final numVal = int.tryParse(val);
                          if (numVal == null || numVal < 0 || numVal > 100) {
                            return 'hr_invalid_commission_percentage'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Dynamic: Fixed Amount Field
                    if (_showsFixedFee) ...[
                      CustomTextFormField(
                        key: const Key('field_fixed_fee'),
                        controller: _fixedFeeController,
                        hintText: 'hr_fixed_fee_hint'.tr(),
                        textInputType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'hr_invalid_fixed_amount'.tr();
                          final numVal = int.tryParse(val);
                          if (numVal == null || numVal < 0) return 'hr_invalid_fixed_amount'.tr();
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Dynamic: Base Salary Field
                    if (_showsBaseSalary) ...[
                      CustomTextFormField(
                        key: const Key('field_base_salary'),
                        controller: _baseSalaryController,
                        hintText: 'hr_base_salary_hint'.tr(),
                        textInputType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'hr_invalid_base_salary'.tr();
                          final numVal = int.tryParse(val);
                          if (numVal == null || numVal < 0) return 'hr_invalid_base_salary'.tr();
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Pay for Free Visits Checkbox
                    CheckboxListTile(
                      key: const Key('check_pay_free_visits'),
                      title: Text('hr_pay_free_visits'.tr()),
                      value: _payForFreeVisits,
                      onChanged: (val) => setState(() => _payForFreeVisits = val ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    CustomPushButton(
                      key: const Key('btn_save_rule'),
                      label: 'hr_save_rule_btn'.tr(),
                      isLoading: state.isSubmitting,
                      onTap: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final nav = Navigator.of(context);

                        final percentage = _showsPercentage ? num.tryParse(_percentageController.text.trim()) : null;
                        final fixedFee = _showsFixedFee ? Money.fromEgpString(_fixedFeeController.text.trim()).piastres : null;
                        final baseSalary = _showsBaseSalary ? Money.fromEgpString(_baseSalaryController.text.trim()).piastres : null;

                        final ruleToSave = DoctorCompensationRuleModel(
                          id: widget.rule?.id,
                          doctorId: _doctorIdController.text.trim(),
                          branchId: _branchIdController.text.trim(),
                          compensationType: _selectedType,
                          commissionPercentage: percentage,
                          fixedAmountPerVisitPiastres: fixedFee,
                          monthlyBaseSalaryPiastres: baseSalary,
                          effectiveFrom: _effectiveFrom,
                          payForFreeVisits: _payForFreeVisits,
                          notes: _notesController.text.trim(),
                        );

                        final success = await context.read<HrCubit>().saveCompensationRule(ruleToSave);
                        if (success && mounted) {
                          nav.pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
