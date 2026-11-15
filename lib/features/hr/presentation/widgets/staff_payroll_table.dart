import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/hr/data/models/enums/payroll_status_enum.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_period_model.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';

class StaffPayrollTable extends StatelessWidget {
  final StaffPayrollPeriodModel period;
  final VoidCallback? onPrintPeriod;

  const StaffPayrollTable({
    super.key,
    required this.period,
    this.onPrintPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final items = period.items ?? [];
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.badge_outlined, size: 48, color: AppColors.gray71717A),
            const SizedBox(height: 12),
            Text(
              'hr_empty_payroll'.tr(),
              style: CustomAppFontStyle.medium14.copyWith(color: AppColors.gray71717A),
            ),
          ],
        ),
      );
    }

    final headers = [
      'hr_col_employee'.tr(),
      'hr_col_role'.tr(),
      'hr_col_base_salary'.tr(),
      'hr_col_allowances'.tr(),
      'hr_col_deductions'.tr(),
      'hr_col_advances_deducted'.tr(),
      'hr_col_net_payable'.tr(),
      'hr_col_status'.tr(),
      'hr_col_actions'.tr(),
    ];

    final columnWidths = const <int, TableColumnWidth>{
      0: FixedColumnWidth(160),
      1: FixedColumnWidth(120),
      2: FixedColumnWidth(110),
      3: FixedColumnWidth(100),
      4: FixedColumnWidth(100),
      5: FixedColumnWidth(110),
      6: FixedColumnWidth(120),
      7: FixedColumnWidth(100),
      8: FixedColumnWidth(140),
    };

    final rows = items.map((item) {
      return [
        Text(item.employeeName ?? item.staffUserId ?? '-', style: CustomAppFontStyle.medium13),
        Text(item.jobTitle ?? '-', style: CustomAppFontStyle.regular12.copyWith(color: AppColors.gray71717A)),
        Text(Money.fromPiastres(item.baseSalaryPiastres ?? 0).formatEgp(), style: CustomAppFontStyle.regular13),
        Text(Money.fromPiastres(item.totalAllowancesPiastres ?? 0).formatEgp(), style: CustomAppFontStyle.regular13),
        Text(Money.fromPiastres(item.totalDeductionsPiastres ?? 0).formatEgp(), style: CustomAppFontStyle.regular13),
        Text(Money.fromPiastres(item.advancesDeductedPiastres ?? 0).formatEgp(), style: CustomAppFontStyle.regular13),
        Text(
          Money.fromPiastres(item.netSalaryPiastres ?? 0).formatEgp(),
          style: CustomAppFontStyle.bold13.copyWith(color: AppColors.primary),
        ),
        _PayrollStatusBadge(status: period.status ?? PayrollStatusEnum.draft),
        _PayrollActionsCell(period: period, onPrint: onPrintPeriod),
      ];
    }).toList();

    return CustomTable(
      headers: headers,
      rows: rows,
      columnWidths: columnWidths,
    );
  }
}

class _PayrollStatusBadge extends StatelessWidget {
  final PayrollStatusEnum status;

  const _PayrollStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case PayrollStatusEnum.draft:
        bg = AppColors.secondary.withValues(alpha: 0.12);
        fg = AppColors.secondary;
        text = 'hr_status_draft'.tr();
        break;
      case PayrollStatusEnum.confirmed:
        bg = AppColors.primary.withValues(alpha: 0.12);
        fg = AppColors.primary;
        text = 'hr_status_confirmed'.tr();
        break;
      case PayrollStatusEnum.paid:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        text = 'hr_status_paid'.tr();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: CustomAppFontStyle.medium12.copyWith(color: fg),
      ),
    );
  }
}

class _PayrollActionsCell extends StatelessWidget {
  final StaffPayrollPeriodModel period;
  final VoidCallback? onPrint;

  const _PayrollActionsCell({
    required this.period,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HrCubit>();
    final user = cubit.state.currentUser;
    final evaluator = cubit.permissionEvaluator;

    final isDraft = period.status == PayrollStatusEnum.draft;
    final isConfirmed = period.status == PayrollStatusEnum.confirmed;

    final canConfirm = isDraft;
    bool canPayout = false;
    if (isConfirmed) {
      if (user?.isOwner == true) {
        canPayout = true;
      } else if (evaluator != null) {
        canPayout = evaluator.can(
          StaffPermissionEnum.payoutSettlement,
          branchId: period.primaryBranchId,
        );
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Confirm Button
        if (canConfirm)
          IconButton(
            key: Key('btn_confirm_payroll_${period.id}'),
            tooltip: 'hr_action_confirm'.tr(),
            icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.primary),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('hr_confirm_payroll_title'.tr()),
                  content: Text('hr_confirm_payroll_desc'.tr()),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('confirm'.tr())),
                  ],
                ),
              );
              if (confirm == true && period.id != null) {
                cubit.confirmStaffPayrollPeriod(period.id!);
              }
            },
          ),

        // Payout Button
        if (canPayout)
          IconButton(
            key: Key('btn_payout_payroll_${period.id}'),
            tooltip: 'hr_action_payout'.tr(),
            icon: const Icon(Icons.payments_outlined, size: 18, color: AppColors.success),
            onPressed: () async {
              if (period.id != null) {
                cubit.payoutStaffPayrollPeriod(period.id!);
              }
            },
          ),

        // Print Button
        IconButton(
          key: Key('btn_print_payroll_${period.id}'),
          tooltip: 'hr_action_print'.tr(),
          icon: const Icon(Icons.print_outlined, size: 18, color: AppColors.gray71717A),
          onPressed: onPrint ?? () {},
        ),
      ],
    );
  }
}
