import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_model.dart';

class SettlementBreakdownDialog extends StatelessWidget {
  final DoctorSettlementModel settlement;

  const SettlementBreakdownDialog({
    super.key,
    required this.settlement,
  });

  @override
  Widget build(BuildContext context) {
    final items = settlement.items ?? [];
    final dateFormat = DateFormat('yyyy/MM/dd');

    final headers = [
      'hr_col_visit_id'.tr(),
      'hr_col_recognition_date'.tr(),
      'hr_col_patient'.tr(),
      'hr_col_service'.tr(),
      'hr_col_gross'.tr(),
      'hr_col_discount'.tr(),
      'hr_col_net'.tr(),
      'hr_col_doctor_share'.tr(),
      'hr_col_clinic_share'.tr(),
    ];

    final columnWidths = const <int, TableColumnWidth>{
      0: FixedColumnWidth(100),
      1: FixedColumnWidth(110),
      2: FixedColumnWidth(140),
      3: FixedColumnWidth(120),
      4: FixedColumnWidth(100),
      5: FixedColumnWidth(90),
      6: FixedColumnWidth(100),
      7: FixedColumnWidth(110),
      8: FixedColumnWidth(110),
    };

    final rows = items.map((item) {
      return [
        Text(item.visitId ?? '-', style: CustomAppFontStyle.regular13),
        Text(
          item.recognitionDate != null ? dateFormat.format(item.recognitionDate!) : '-',
          style: CustomAppFontStyle.regular13,
        ),
        Text(item.patientName ?? item.patientId ?? '-', style: CustomAppFontStyle.medium13),
        Text(item.serviceName ?? 'كشف عام', style: CustomAppFontStyle.regular13),
        Text(Money.fromPiastres(item.grossFeePiastres ?? 0).formatEgp(), style: CustomAppFontStyle.regular13),
        Text(Money.fromPiastres(item.discountAmountPiastres ?? 0).formatEgp(), style: CustomAppFontStyle.regular13),
        Text(Money.fromPiastres(item.netAmountPiastres ?? 0).formatEgp(), style: CustomAppFontStyle.medium13),
        Text(
          Money.fromPiastres(item.doctorEarnedPiastres ?? 0).formatEgp(),
          style: CustomAppFontStyle.bold13.copyWith(color: AppColors.primary),
        ),
        Text(
          Money.fromPiastres(item.clinicSharePiastres ?? 0).formatEgp(),
          style: CustomAppFontStyle.regular13,
        ),
      ];
    }).toList();

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 960,
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 700),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'hr_breakdown_title'.tr(),
                      style: CustomAppFontStyle.bold18.copyWith(color: AppColors.darkText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${settlement.settlementNumber ?? ''} - ${settlement.doctorName ?? ''}',
                      style: CustomAppFontStyle.regular13.copyWith(color: AppColors.gray),
                    ),
                  ],
                ),
                IconButton(
                  key: const Key('btn_close_breakdown'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.gray71717A),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Table
            Flexible(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'لا توجد كشوفات مسجلة لهذه التسوية',
                          style: CustomAppFontStyle.medium14.copyWith(color: AppColors.gray71717A),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: CustomTable(
                        headers: headers,
                        rows: rows,
                        columnWidths: columnWidths,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // Financial Summary Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLevel1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grayE2E8F0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    label: 'إجمالي الكشوفات',
                    value: '${settlement.totalVisitsCount ?? items.length}',
                  ),
                  _SummaryItem(
                    label: 'إجمالي الإيراد',
                    value: Money.fromPiastres(settlement.totalNetRevenuePiastres ?? 0).formatEgp(),
                  ),
                  _SummaryItem(
                    label: 'الراتب الأساسي',
                    value: Money.fromPiastres(settlement.baseSalaryPiastres ?? 0).formatEgp(),
                  ),
                  _SummaryItem(
                    label: 'السلف المستقطعة',
                    value: Money.fromPiastres(settlement.totalAdvancesDeductedPiastres ?? 0).formatEgp(),
                  ),
                  _SummaryItem(
                    label: 'صافي المستحق',
                    value: Money.fromPiastres(settlement.netPayablePiastres ?? 0).formatEgp(),
                    isHighlight: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: CustomAppFontStyle.regular12.copyWith(color: AppColors.gray)),
        const SizedBox(height: 4),
        Text(
          value,
          style: isHighlight
              ? CustomAppFontStyle.bold16.copyWith(color: AppColors.primary)
              : CustomAppFontStyle.bold14.copyWith(color: AppColors.darkText),
        ),
      ],
    );
  }
}
