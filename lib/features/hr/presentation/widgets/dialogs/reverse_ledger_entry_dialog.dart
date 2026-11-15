import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/hr/data/models/employee_ledger_entry_model.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_state.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class ReverseLedgerEntryDialog extends StatefulWidget {
  final EmployeeLedgerEntryModel targetEntry;

  const ReverseLedgerEntryDialog({
    super.key,
    required this.targetEntry,
  });

  @override
  State<ReverseLedgerEntryDialog> createState() => _ReverseLedgerEntryDialogState();
}

class _ReverseLedgerEntryDialogState extends State<ReverseLedgerEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
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
                          'hr_reverse_entry_title'.tr(),
                          style: CustomAppFontStyle.bold18.copyWith(color: AppColors.darkText),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: AppColors.gray71717A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Explanatory Note
                  Text(
                    'hr_reverse_entry_desc'.tr(),
                    style: CustomAppFontStyle.regular13.copyWith(color: AppColors.gray),
                  ),
                  const SizedBox(height: 16),

                  // Target Entry Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLevel1,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.grayE2E8F0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'hr_col_entry_id'.tr()}: ${widget.targetEntry.id ?? '-'}',
                          style: CustomAppFontStyle.bold13.copyWith(color: AppColors.darkText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'hr_col_type'.tr()}: ${widget.targetEntry.entryType?.name ?? '-'}',
                          style: CustomAppFontStyle.regular12.copyWith(color: AppColors.gray71717A),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reason TextFormField
                  CustomTextFormField(
                    key: const Key('field_reversal_reason'),
                    controller: _reasonController,
                    hintText: 'hr_reversal_reason_hint'.tr(),
                    maxLine: 3,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'hr_reversal_reason_label'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Confirm Reversal Button
                  CustomPushButton(
                    key: const Key('btn_confirm_reverse_entry'),
                    label: 'hr_confirm_reverse_btn'.tr(),
                    backgroundColor: AppColors.error,
                    isLoading: state.isSubmitting,
                    onTap: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final nav = Navigator.of(context);

                      final targetId = widget.targetEntry.id;
                      final empId = widget.targetEntry.employeeId;
                      if (targetId == null || empId == null) return;

                      final success = await context.read<HrCubit>().reverseLedgerEntry(
                            entryId: targetId,
                            reason: _reasonController.text.trim(),
                            employeeId: empId,
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
