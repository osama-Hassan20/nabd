import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_period_model.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_state.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'dialogs/generate_payroll_period_dialog.dart';
import 'staff_payroll_table.dart';

class StaffPayrollTab extends StatefulWidget {
  final VoidCallback? onPrintPeriod;

  const StaffPayrollTab({
    super.key,
    this.onPrintPeriod,
  });

  @override
  State<StaffPayrollTab> createState() => _StaffPayrollTabState();
}

class _StaffPayrollTabState extends State<StaffPayrollTab> {
  StaffPayrollPeriodModel? _activePeriod;
  late final TextEditingController _periodController;

  @override
  void initState() {
    super.initState();
    _periodController = TextEditingController();
  }

  @override
  void dispose() {
    _periodController.dispose();
    super.dispose();
  }

  String _periodLabel(StaffPayrollPeriodModel? p) =>
      p != null ? '${p.year} / ${p.month} (${p.status?.name ?? ''})' : '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HrCubit, HrState>(
      builder: (context, state) {
        final evaluator = context.read<HrCubit>().permissionEvaluator;
        final user = state.currentUser;

        // RBAC: manageStaffPayroll or Owner
        final hasAccess = user?.isOwner == true ||
            (evaluator != null &&
                evaluator.can(
                  StaffPermissionEnum.manageStaffPayroll,
                  branchId: state.currentBranchId,
                ));

        if (!hasAccess) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 56, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'hr_unauthorized_payroll'.tr(),
                    style: CustomAppFontStyle.bold16.copyWith(color: AppColors.darkText),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final periods = state.payrollPeriods;
        final currentPeriod = _activePeriod ?? (periods.isNotEmpty ? periods.first : null);
        if (currentPeriod != null && _periodController.text.isEmpty) {
          _periodController.text = _periodLabel(currentPeriod);
        }

        final colors = context.themeColors;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Controls Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Periods Selector
                      if (periods.isNotEmpty) ...[
                        SizedBox(
                          width: 220,
                          child: CustomStackSelector<StaffPayrollPeriodModel>(
                            key: const Key('dropdown_select_payroll_period'),
                            controller: _periodController,
                            hintText: 'hr_month_label'.tr(),
                            list: periods,
                            itemAsString: _periodLabel,
                            changeValue: (val) {
                              setState(() {
                                _activePeriod = val;
                                _periodController.text = _periodLabel(val);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],

                      // Generate Payroll Button
                      ElevatedButton.icon(
                        key: const Key('btn_open_generate_payroll'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.add_chart_outlined, size: 18),
                        label: Text('hr_generate_payroll_btn'.tr(), style: CustomAppFontStyle.bold13),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => BlocProvider.value(
                              value: context.read<HrCubit>(),
                              child: const GeneratePayrollPeriodDialog(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Table
              if (currentPeriod != null)
                StaffPayrollTable(
                  period: currentPeriod,
                  onPrintPeriod: widget.onPrintPeriod,
                )
              else
                Container(
                  padding: const EdgeInsets.all(48),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.date_range_outlined, size: 48, color: AppColors.gray71717A),
                      const SizedBox(height: 12),
                      Text(
                        'hr_empty_payroll'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(color: AppColors.gray71717A),
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
}
