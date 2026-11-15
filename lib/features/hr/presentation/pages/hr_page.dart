import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/animation/fade_transition_animation.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_state.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_tab_enum.dart';
import 'package:eyadty/features/hr/presentation/widgets/doctor_settlements_tab.dart';
import 'package:eyadty/features/hr/presentation/widgets/employee_ledger_tab.dart';
import 'package:eyadty/features/hr/presentation/widgets/staff_payroll_tab.dart';

class HrPage extends StatelessWidget {
  const HrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HrCubit, HrState>(
      builder: (context, state) {
        return FadeTransitionAnimation(
          duration: const Duration(milliseconds: 300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tab Header
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    _buildTabButton(
                      context: context,
                      tab: HrTabEnum.settlements,
                      label: 'hr_tab_settlements'.tr(),
                      isSelected: state.selectedTab == HrTabEnum.settlements,
                    ),
                    const SizedBox(width: 8),
                    _buildTabButton(
                      context: context,
                      tab: HrTabEnum.staffPayroll,
                      label: 'hr_tab_staff_payroll'.tr(),
                      isSelected: state.selectedTab == HrTabEnum.staffPayroll,
                    ),
                    const SizedBox(width: 8),
                    _buildTabButton(
                      context: context,
                      tab: HrTabEnum.employeeLedger,
                      label: 'hr_tab_employee_ledger'.tr(),
                      isSelected: state.selectedTab == HrTabEnum.employeeLedger,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.grayE2E8F0),

              // Active Tab Content
              Expanded(
                child: _buildTabBody(state.selectedTab),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required HrTabEnum tab,
    required String label,
    required bool isSelected,
  }) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        foregroundColor: isSelected ? AppColors.primary : AppColors.gray71717A,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: () => context.read<HrCubit>().switchTab(tab),
      child: Text(
        label,
        style: isSelected ? CustomAppFontStyle.bold14 : CustomAppFontStyle.medium14,
      ),
    );
  }

  Widget _buildTabBody(HrTabEnum tab) {
    switch (tab) {
      case HrTabEnum.settlements:
      case HrTabEnum.compensationRules:
        return const DoctorSettlementsTab();
      case HrTabEnum.staffPayroll:
        return const StaffPayrollTab();
      case HrTabEnum.employeeLedger:
        return const EmployeeLedgerTab();
    }
  }
}
