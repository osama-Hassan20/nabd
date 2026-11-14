import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/data/models/cashier_shift_model.dart';
import 'package:eyadty/features/cashier/data/models/enums/shift_status_enum.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'dialogs/approve_shortage_dialog.dart';

class ShiftHistoryTable extends StatelessWidget {
  final List<CashierShiftModel> shifts;

  const ShiftHistoryTable({
    super.key,
    required this.shifts,
  });

  @override
  Widget build(BuildContext context) {
    if (shifts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 48,
              color: AppColors.gray71717A,
            ),
            const SizedBox(height: 12),
            Text(
              'cashier_empty_history'.tr(),
              style: CustomAppFontStyle.medium14.copyWith(
                color: AppColors.gray71717A,
              ),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a');

    final headers = [
      'cashier_shift_code'.tr(),
      'cashier_cashier_name'.tr(),
      'cashier_opened_at'.tr(),
      'cashier_opening_balance'.tr(),
      'cashier_cash_collected'.tr(),
      'cashier_expected_cash'.tr(),
      'cashier_difference_label'.tr(),
      'cashier_status'.tr(),
      'cashier_actions'.tr(),
    ];

    final columnWidths = const <int, TableColumnWidth>{
      0: FixedColumnWidth(110),
      1: FixedColumnWidth(130),
      2: FixedColumnWidth(160),
      3: FixedColumnWidth(120),
      4: FixedColumnWidth(120),
      5: FixedColumnWidth(130),
      6: FixedColumnWidth(120),
      7: FixedColumnWidth(140),
      8: FixedColumnWidth(110),
    };

    final rows = shifts.map((shift) {
      final formattedTime = shift.openedAt != null
          ? dateFormat.format(shift.openedAt!)
          : '-';
      final openingBalance =
          Money(shift.openingBalancePiastres ?? 0).formatEgp();
      final cashCollected =
          Money(shift.totalCashCollectedPiastres ?? 0).formatEgp();
      final expectedCash =
          Money(shift.expectedCashPiastres ?? 0).formatEgp();

      final diffPiastres = shift.cashDifferencePiastres ?? 0;
      final diffText = diffPiastres == 0
          ? '0.00 ج.م'
          : Money(diffPiastres.abs()).formatEgp();
      final isShortage = diffPiastres < 0;
      final isSurplus = diffPiastres > 0;

      final isPending =
          shift.status == ShiftStatusEnum.closedPendingApproval;

      return [
        // 0: Shift Code
        Text(
          shift.id ?? '-',
          style: CustomAppFontStyle.bold12.copyWith(color: AppColors.primary),
        ),

        // 1: Cashier Name
        Text(
          shift.cashierName ?? 'كاشير',
          style: CustomAppFontStyle.medium12.copyWith(color: AppColors.darkText),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // 2: Opened At
        Text(
          formattedTime,
          style: CustomAppFontStyle.regular11.copyWith(
            color: AppColors.gray71717A,
          ),
        ),

        // 3: Opening Balance
        Text(
          openingBalance,
          style: CustomAppFontStyle.medium12.copyWith(color: AppColors.darkText),
        ),

        // 4: Cash Collected
        Text(
          cashCollected,
          style: CustomAppFontStyle.bold12.copyWith(
            color: const Color(0xff007834),
          ),
        ),

        // 5: Expected Cash
        Text(
          expectedCash,
          style: CustomAppFontStyle.bold12.copyWith(color: AppColors.darkText),
        ),

        // 6: Difference
        Text(
          isShortage ? '-$diffText' : isSurplus ? '+$diffText' : diffText,
          style: CustomAppFontStyle.bold12.copyWith(
            color: isShortage
                ? AppColors.red
                : isSurplus
                    ? const Color(0xff007834)
                    : AppColors.gray71717A,
          ),
        ),

        // 7: Status Badge
        _buildStatusBadge(shift.status),

        // 8: Actions
        if (isPending)
          CustomPushButton(
            height: 28,
            backgroundColor: AppColors.white,
            boxBorder:
                Border.all(color: const Color(0xffF59E0B).withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(6),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => ApproveShortageDialog(shift: shift),
              );
            },
            child: Text(
              'اعتماد',
              style: CustomAppFontStyle.medium11.copyWith(
                color: const Color(0xffD97706),
              ),
            ),
          )
        else
          const SizedBox.shrink(),
      ];
    }).toList();

    return CustomTable(
      headers: headers,
      rows: rows,
      columnWidths: columnWidths,
      minWidth: 1050,
    );
  }

  Widget _buildStatusBadge(ShiftStatusEnum? status) {
    String label = 'cashier_status_closed'.tr();
    Color bg = const Color(0xffF1F5F9);
    Color fg = const Color(0xff64748B);

    switch (status) {
      case ShiftStatusEnum.open:
        label = 'cashier_status_open'.tr();
        bg = const Color(0xff007834).withValues(alpha: 0.1);
        fg = const Color(0xff007834);
        break;
      case ShiftStatusEnum.closed:
        label = 'cashier_status_closed'.tr();
        bg = const Color(0xffF1F5F9);
        fg = const Color(0xff64748B);
        break;
      case ShiftStatusEnum.closedPendingApproval:
        label = 'cashier_status_pending_approval'.tr();
        bg = const Color(0xffFEF3C7);
        fg = const Color(0xffD97706);
        break;
      case ShiftStatusEnum.forceClosed:
        label = 'cashier_status_force_closed'.tr();
        bg = AppColors.red.withValues(alpha: 0.1);
        fg = AppColors.red;
        break;
      case null:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: CustomAppFontStyle.semiBold11.copyWith(color: fg),
      ),
    );
  }
}
