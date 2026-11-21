import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/payment_method.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/layout_adaptive/widgets/cutom_table.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../cashier/domain/helpers/money.dart';
import '../../data/models/doctor_settlement_model.dart';
import '../../data/models/enums/settlement_status_enum.dart';
import '../manager/hr_cubit.dart';
import 'dialogs/settlement_breakdown_dialog.dart';

class SettlementsTable extends StatelessWidget {
  final List<DoctorSettlementModel> settlements;
  final VoidCallback? onPrintSettlement;

  const SettlementsTable({
    super.key,
    required this.settlements,
    this.onPrintSettlement,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    if (settlements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 48, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'hr_empty_settlements'.tr(),
              style: CustomAppFontStyle.medium14.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('yyyy/MM/dd');

    final headers = [
      'hr_col_settlement_number'.tr(),
      'hr_col_doctor'.tr(),
      'hr_col_period'.tr(),
      'hr_col_visits'.tr(),
      'hr_col_total_revenue'.tr(),
      'hr_col_doctor_share'.tr(),
      'hr_col_status'.tr(),
      'hr_col_actions'.tr(),
    ];

    final columnWidths = const <int, TableColumnWidth>{
      0: FixedColumnWidth(160),
      1: FixedColumnWidth(140),
      2: FixedColumnWidth(180),
      3: FixedColumnWidth(90),
      4: FixedColumnWidth(120),
      5: FixedColumnWidth(120),
      6: FixedColumnWidth(110),
      7: FixedColumnWidth(190),
    };

    final rows = settlements.map((s) {
      final periodText = (s.periodStart != null && s.periodEnd != null)
          ? '${dateFormat.format(s.periodStart!)} - ${dateFormat.format(s.periodEnd!)}'
          : '-';

      return [
        Text(s.settlementNumber ?? s.id ?? '-', style: CustomAppFontStyle.medium13),
        Text(s.doctorName ?? s.doctorId ?? '-', style: CustomAppFontStyle.medium13),
        Text(periodText, style: CustomAppFontStyle.regular12),
        Text('${s.totalVisitsCount ?? 0}', style: CustomAppFontStyle.regular13),
        Text(Money.fromPiastres(s.totalNetRevenuePiastres ?? 0).formatEgp(), style: CustomAppFontStyle.regular13),
        Text(
          Money.fromPiastres(s.netPayablePiastres ?? s.totalDoctorCommissionPiastres ?? 0).formatEgp(),
          style: CustomAppFontStyle.bold13.copyWith(color: AppColors.primary),
        ),
        _StatusBadge(status: s.status ?? SettlementStatusEnum.draft),
        _SettlementActionsCell(settlement: s, onPrint: onPrintSettlement),
      ];
    }).toList();

    return CustomTable(
      headers: headers,
      rows: rows,
      columnWidths: columnWidths,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SettlementStatusEnum status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case SettlementStatusEnum.draft:
        bg = AppColors.secondary.withValues(alpha: 0.12);
        fg = AppColors.secondary;
        text = 'hr_status_draft'.tr();
        break;
      case SettlementStatusEnum.confirmed:
        bg = AppColors.primary.withValues(alpha: 0.12);
        fg = AppColors.primary;
        text = 'hr_status_confirmed'.tr();
        break;
      case SettlementStatusEnum.paid:
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

class _SettlementActionsCell extends StatelessWidget {
  final DoctorSettlementModel settlement;
  final VoidCallback? onPrint;

  const _SettlementActionsCell({
    required this.settlement,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HrCubit>();
    final user = cubit.state.currentUser;
    final evaluator = cubit.permissionEvaluator;

    final isDraft = settlement.status == SettlementStatusEnum.draft;
    final isConfirmed = settlement.status == SettlementStatusEnum.confirmed;

    // Separation of duties for confirmation:
    // Attending doctor CANNOT confirm their own settlement, unless owner!
    final linkedDocId = user?.linkedDoctorId;
    final isAttendingDoctor = linkedDocId != null &&
        settlement.doctorId != null &&
        linkedDocId == settlement.doctorId;
    final canConfirm = isDraft && (!isAttendingDoctor || user?.isOwner == true);

    // Payout permission: Accountant or Owner only
    bool canPayout = false;
    if (isConfirmed) {
      if (user?.isOwner == true) {
        canPayout = true;
      } else if (evaluator != null) {
        canPayout = evaluator.can(
          StaffPermissionEnum.payoutSettlement,
          branchId: settlement.branchId,
        );
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Breakdown
        IconButton(
          key: Key('btn_view_breakdown_${settlement.id}'),
          tooltip: 'hr_action_view_breakdown'.tr(),
          icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => SettlementBreakdownDialog(settlement: settlement),
            );
          },
        ),

        // Confirm
        if (canConfirm)
          IconButton(
            key: Key('btn_confirm_settlement_${settlement.id}'),
            tooltip: 'hr_action_confirm'.tr(),
            icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.primary),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('hr_confirm_settlement_title'.tr()),
                  content: Text('hr_confirm_settlement_desc'.tr()),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('confirm'.tr())),
                  ],
                ),
              );
              if (confirm == true && settlement.id != null) {
                cubit.confirmSettlement(settlement.id!);
              }
            },
          ),

        // Payout
        if (canPayout)
          IconButton(
            key: Key('btn_payout_settlement_${settlement.id}'),
            tooltip: 'hr_action_payout'.tr(),
            icon: const Icon(Icons.payments_outlined, size: 18, color: AppColors.success),
            onPressed: () async {
              if (settlement.id != null) {
                cubit.payoutSettlement(
                  settlementId: settlement.id!,
                  method: PaymentMethod.cash,
                );
              }
            },
          ),

        // Print
        IconButton(
          key: Key('btn_print_settlement_${settlement.id}'),
          tooltip: 'hr_action_print'.tr(),
          icon: const Icon(Icons.print_outlined, size: 18, color: AppColors.gray71717A),
          onPressed: onPrint ?? () {},
        ),
      ],
    );
  }
}
