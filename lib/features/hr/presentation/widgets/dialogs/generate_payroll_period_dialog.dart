import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_state.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class GeneratePayrollPeriodDialog extends StatefulWidget {
  final int? initialMonth;
  final int? initialYear;

  const GeneratePayrollPeriodDialog({
    super.key,
    this.initialMonth,
    this.initialYear,
  });

  @override
  State<GeneratePayrollPeriodDialog> createState() => _GeneratePayrollPeriodDialogState();
}

class _GeneratePayrollPeriodDialogState extends State<GeneratePayrollPeriodDialog> {
  final _formKey = GlobalKey<FormState>();

  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = CairoTimeHelper.now();
    _selectedMonth = widget.initialMonth ?? now.month;
    _selectedYear = widget.initialYear ?? now.year;
  }

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (index) => index + 1);
    final years = List.generate(7, (index) => 2024 + index);

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
            width: 440,
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
                          'hr_generate_payroll_title'.tr(),
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

                  // Month Selector
                  DropdownButtonFormField<int>(
                    key: const Key('dropdown_payroll_month'),
                    isExpanded: true,
                    initialValue: _selectedMonth,
                    decoration: InputDecoration(
                      labelText: 'hr_month_label'.tr(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.surfaceLevel1,
                    ),
                    items: months.map((m) {
                      return DropdownMenuItem<int>(
                        value: m,
                        child: Text('$m'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedMonth = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Year Selector
                  DropdownButtonFormField<int>(
                    key: const Key('dropdown_payroll_year'),
                    isExpanded: true,
                    initialValue: _selectedYear,
                    decoration: InputDecoration(
                      labelText: 'hr_year_label'.tr(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.surfaceLevel1,
                    ),
                    items: years.map((y) {
                      return DropdownMenuItem<int>(
                        value: y,
                        child: Text('$y'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedYear = val);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  CustomPushButton(
                    key: const Key('btn_generate_payroll'),
                    label: 'hr_generate_payroll_btn'.tr(),
                    isLoading: state.isSubmitting,
                    onTap: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final nav = Navigator.of(context);

                      final success = await context.read<HrCubit>().generateStaffPayrollPeriod(
                            month: _selectedMonth,
                            year: _selectedYear,
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
