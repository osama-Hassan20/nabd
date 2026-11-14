import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/data/models/payment_transaction_model.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'dialogs/refund_payment_dialog.dart';

class PaymentsHistoryTable extends StatelessWidget {
  final List<PaymentTransactionModel> payments;

  const PaymentsHistoryTable({
    super.key,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.gray71717A,
            ),
            const SizedBox(height: 12),
            Text(
              'cashier_empty_payments'.tr(),
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
      'cashier_receipt_number'.tr(),
      'cashier_booking_number'.tr(),
      'cashier_patient'.tr(),
      'cashier_payment_method'.tr(),
      'cashier_amount'.tr(),
      'cashier_time'.tr(),
      'cashier_status'.tr(),
      'cashier_actions'.tr(),
    ];

    final columnWidths = const <int, TableColumnWidth>{
      0: FixedColumnWidth(130),
      1: FixedColumnWidth(120),
      2: FixedColumnWidth(160),
      3: FixedColumnWidth(130),
      4: FixedColumnWidth(110),
      5: FixedColumnWidth(160),
      6: FixedColumnWidth(100),
      7: FixedColumnWidth(90),
    };

    final rows = payments.map((payment) {
      final formattedTime = payment.createdAt != null
          ? dateFormat.format(payment.createdAt!)
          : '-';
      final formattedAmount =
          Money(payment.amountPiastres ?? 0).formatEgp();
      final isRefunded = payment.isRefunded == true;

      return [
        // 0: Receipt Number
        Text(
          payment.receiptNumber.isNotEmpty ? payment.receiptNumber : '-',
          style: CustomAppFontStyle.bold12.copyWith(color: AppColors.primary),
        ),

        // 1: Booking Number
        Text(
          payment.bookingId ?? '-',
          style: CustomAppFontStyle.medium12.copyWith(color: AppColors.darkText),
        ),

        // 2: Patient Name
        Text(
          payment.patientName ?? '-',
          style: CustomAppFontStyle.medium12.copyWith(color: AppColors.darkText),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // 3: Payment Method
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              payment.isCash
                  ? Icons.money_rounded
                  : payment.isCard
                      ? Icons.credit_card_rounded
                      : Icons.account_balance_rounded,
              size: 14,
              color: AppColors.gray71717A,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                payment.paymentMethod?.translationKey.tr() ?? 'نقدي',
                style: CustomAppFontStyle.regular12.copyWith(
                  color: AppColors.darkText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // 4: Amount
        Text(
          formattedAmount,
          style: CustomAppFontStyle.bold12.copyWith(
            color: const Color(0xff007834),
          ),
        ),

        // 5: Time
        Text(
          formattedTime,
          style: CustomAppFontStyle.regular11.copyWith(
            color: AppColors.gray71717A,
          ),
        ),

        // 6: Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isRefunded
                ? AppColors.red.withValues(alpha: 0.1)
                : const Color(0xff007834).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isRefunded ? 'مسترد' : 'مسدد',
            style: CustomAppFontStyle.semiBold11.copyWith(
              color: isRefunded ? AppColors.red : const Color(0xff007834),
            ),
          ),
        ),

        // 7: Actions
        if (!isRefunded)
          CustomPushButton(
            height: 28,
            backgroundColor: AppColors.white,
            boxBorder: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(6),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => RefundPaymentDialog(payment: payment),
              );
            },
            child: Text(
              'cashier_refund_btn'.tr(),
              style: CustomAppFontStyle.medium11.copyWith(
                color: AppColors.red,
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
      minWidth: 900,
    );
  }
}
