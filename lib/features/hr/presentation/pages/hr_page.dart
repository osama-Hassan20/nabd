import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/animation/fade_transition_animation.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_state.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_tab_enum.dart';
import 'package:eyadty/features/hr/presentation/widgets/doctor_settlements_tab.dart';
import 'package:eyadty/features/hr/presentation/widgets/employee_ledger_tab.dart';
import 'package:eyadty/features/hr/presentation/widgets/staff_payroll_tab.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class HrPage extends StatelessWidget {
  final HrCubit? cubit;

  const HrPage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<HrCubit>.value(
        value: cubit!,
        child: const _HrPageView(),
      );
    }

    return BlocProvider<HrCubit>(
      create: (context) {
        final session = context.read<SessionCubit>().state;
        final branchId = session.activeBranchId ?? 'branch_1';
        final user = session.currentUser ??
            const StaffUserModel(id: 'dev_user', fullName: 'طبيب النظام');
        return getIt<HrCubit>()..init(branchId: branchId, user: user);
      },
      child: const _HrPageView(),
    );
  }
}

class _HrPageView extends StatelessWidget {
  const _HrPageView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionCubit, SessionState>(
      listenWhen: (prev, curr) =>
          prev.activeBranchId != curr.activeBranchId ||
          prev.currentUser?.id != curr.currentUser?.id,
      listener: (context, session) {
        final branchId = session.activeBranchId ?? 'branch_1';
        final user = session.currentUser;
        if (user != null) {
          context.read<HrCubit>().onBranchOrUserChanged(
                newBranchId: branchId,
                newUser: user,
              );
        }
      },
      child: BlocBuilder<HrCubit, HrState>(
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
      ),
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
