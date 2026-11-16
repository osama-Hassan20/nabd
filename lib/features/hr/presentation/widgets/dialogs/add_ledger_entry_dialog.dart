import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/hr/data/models/enums/employee_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/ledger_entry_type_enum.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_state.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class AddLedgerEntryDialog extends StatefulWidget {
  final String? initialEmployeeId;

  const AddLedgerEntryDialog({
    super.key,
    this.initialEmployeeId,
  });

  @override
  State<AddLedgerEntryDialog> createState() => _AddLedgerEntryDialogState();
}

class _AddLedgerEntryDialogState extends State<AddLedgerEntryDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _employeeIdController;
  late TextEditingController _amountController;
  late TextEditingController _reasonController;
  late TextEditingController _typeController;

  LedgerEntryTypeEnum _selectedType = LedgerEntryTypeEnum.advance;
  final EmployeeTypeEnum _selectedEmployeeType = EmployeeTypeEnum.staff;

  String _entryTypeLabel(LedgerEntryTypeEnum type) {
    switch (type) {
      case LedgerEntryTypeEnum.advance:
        return 'hr_entry_type_advance'.tr();
      case LedgerEntryTypeEnum.deduction:
        return 'hr_entry_type_deduction'.tr();
      default:
        return type.name;
    }
  }

  @override
  void initState() {
    super.initState();
    _employeeIdController = TextEditingController(text: widget.initialEmployeeId ?? '');
    _amountController = TextEditingController();
    _reasonController = TextEditingController();
    _typeController = TextEditingController(text: _entryTypeLabel(_selectedType));
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    _typeController.dispose();
    super.dispose();
  }

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
            width: 480,
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
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
                          'hr_add_ledger_entry_title'.tr(),
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

                  // Employee ID
                  CustomTextFormField(
                    key: const Key('field_add_entry_employee_id'),
                    controller: _employeeIdController,
                    hintText: 'hr_employee_id_hint'.tr(),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'hr_staff_user_id_required'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Entry Type Dropdown
                  CustomStackSelector<LedgerEntryTypeEnum>(
                    key: const Key('dropdown_entry_type'),
                    controller: _typeController,
                    header: 'hr_entry_type_label'.tr(),
                    list: const [
                      LedgerEntryTypeEnum.advance,
                      LedgerEntryTypeEnum.deduction,
                    ],
                    itemAsString: _entryTypeLabel,
                    changeValue: (val) {
                      setState(() {
                        _selectedType = val;
                        _typeController.text = _entryTypeLabel(val);
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // Amount in EGP
                  CustomTextFormField(
                    key: const Key('field_ledger_amount'),
                    controller: _amountController,
                    hintText: 'hr_amount_egp_hint'.tr(),
                    textInputType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'hr_invalid_deduction'.tr();
                      final parsed = int.tryParse(val.trim());
                      if (parsed == null || parsed <= 0) return 'hr_invalid_deduction'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Reason / Notes
                  CustomTextFormField(
                    key: const Key('field_ledger_notes'),
                    controller: _reasonController,
                    hintText: 'hr_notes_hint'.tr(),
                    maxLine: 2,
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  CustomPushButton(
                    key: const Key('btn_save_ledger_entry'),
                    label: 'hr_save_entry_btn'.tr(),
                    isLoading: state.isSubmitting,
                    onTap: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final nav = Navigator.of(context);

                      final amountPiastres = Money.fromEgpString(_amountController.text.trim()).piastres;

                      final success = await context.read<HrCubit>().addAdvance(
                            employeeId: _employeeIdController.text.trim(),
                            employeeType: _selectedEmployeeType,
                            amountPiastres: amountPiastres,
                            reason: _reasonController.text.trim().isNotEmpty
                                ? _reasonController.text.trim()
                                : 'movement_entry',
                          );

                      if (success && mounted) {
                        nav.pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
