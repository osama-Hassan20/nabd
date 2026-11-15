import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_state.dart';

class CalculateSettlementDraftDialog extends StatefulWidget {
  final String? initialDoctorId;

  const CalculateSettlementDraftDialog({
    super.key,
    this.initialDoctorId,
  });

  @override
  State<CalculateSettlementDraftDialog> createState() => _CalculateSettlementDraftDialogState();
}

class _CalculateSettlementDraftDialogState extends State<CalculateSettlementDraftDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _doctorIdController;

  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final cairoNow = CairoTimeHelper.now();
    _startDate = DateTime(cairoNow.year, cairoNow.month, 1);
    _endDate = DateTime(cairoNow.year, cairoNow.month + 1, 0, 23, 59, 59);
    _doctorIdController = TextEditingController(text: widget.initialDoctorId ?? 'DOC-01');
  }

  @override
  void dispose() {
    _doctorIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');

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
                          'hr_calculate_dialog_title'.tr(),
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
                    key: const Key('field_draft_doctor_id'),
                    controller: _doctorIdController,
                    hintText: 'hr_doctor_id_hint'.tr(),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'hr_doctor_id_required'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Period Selection
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('btn_select_start_date'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _startDate = DateTime(picked.year, picked.month, picked.day));
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            '${'hr_select_start_date'.tr()} ${dateFormat.format(_startDate)}',
                            style: CustomAppFontStyle.regular13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('btn_select_end_date'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
                            }
                          },
                          icon: const Icon(Icons.event, size: 16),
                          label: Text(
                            '${'hr_select_end_date'.tr()} ${dateFormat.format(_endDate)}',
                            style: CustomAppFontStyle.regular13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  CustomPushButton(
                    key: const Key('btn_calculate_draft'),
                    label: 'hr_calculate_draft_btn'.tr(),
                    isLoading: state.isSubmitting,
                    onTap: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final nav = Navigator.of(context);

                      final success = await context.read<HrCubit>().calculateDraftSettlement(
                            doctorId: _doctorIdController.text.trim(),
                            periodStart: _startDate,
                            periodEnd: _endDate,
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
