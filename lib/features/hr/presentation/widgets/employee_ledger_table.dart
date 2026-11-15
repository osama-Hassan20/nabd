import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/hr/data/models/employee_ledger_entry_model.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';
import 'dialogs/reverse_ledger_entry_dialog.dart';

class EmployeeLedgerTable extends StatelessWidget {
  final List<EmployeeLedgerEntryModel> entries;

  const EmployeeLedgerTable({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.gray71717A),
            const SizedBox(height: 12),
            Text(
              'hr_empty_ledger'.tr(),
              style: CustomAppFontStyle.medium14.copyWith(color: AppColors.gray71717A),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    final headers = [
      'hr_col_entry_id'.tr(),
      'hr_col_date'.tr(),
      'hr_col_type'.tr(),
      'hr_col_amount'.tr(),
      'hr_notes_label'.tr(),
      'hr_col_reverses_id'.tr(),
      'hr_col_actions'.tr(),
    ];

    final columnWidths = const <int, TableColumnWidth>{
      0: FixedColumnWidth(130),
      1: FixedColumnWidth(150),
      2: FixedColumnWidth(160),
      3: FixedColumnWidth(110),
      4: FixedColumnWidth(180),
      5: FixedColumnWidth(130),
      6: FixedColumnWidth(80),
    };

    final rows = entries.map((entry) {
      final entryDate = entry.date ?? entry.createdAt;
      final dateStr = entryDate != null ? dateFormat.format(entryDate) : '-';
      final isReversal = entry.reversesEntryId != null;
      final isReversed = entries.any((other) => other.reversesEntryId == entry.id);

      final canReverse = !isReversed && !isReversal;

      return [
        Text(entry.id ?? '-', style: CustomAppFontStyle.medium13),
        Text(dateStr, style: CustomAppFontStyle.regular12.copyWith(color: AppColors.gray71717A)),
        Text(entry.entryType?.name ?? '-', style: CustomAppFontStyle.medium13),
        Text(
          Money.fromPiastres(entry.amountPiastres ?? 0).formatEgp(),
          style: CustomAppFontStyle.bold13.copyWith(
            color: isReversal ? AppColors.error : AppColors.primary,
          ),
        ),
        Text(entry.reason ?? '-', style: CustomAppFontStyle.regular12),
        Text(
          entry.reversesEntryId != null
              ? 'معكوس: ${entry.reversesEntryId}'
              : (isReversed ? 'تم عكسه' : '-'),
          style: CustomAppFontStyle.regular12.copyWith(
            color: isReversed || isReversal ? AppColors.error : AppColors.gray71717A,
          ),
        ),
        canReverse
            ? IconButton(
                key: Key('btn_reverse_entry_${entry.id}'),
                tooltip: 'hr_reverse_entry_title'.tr(),
                icon: const Icon(Icons.undo_outlined, size: 18, color: AppColors.error),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => BlocProvider.value(
                      value: context.read<HrCubit>(),
                      child: ReverseLedgerEntryDialog(targetEntry: entry),
                    ),
                  );
                },
              )
            : const SizedBox(),
      ];
    }).toList();

    return CustomTable(
      headers: headers,
      rows: rows,
      columnWidths: columnWidths,
    );
  }
}
