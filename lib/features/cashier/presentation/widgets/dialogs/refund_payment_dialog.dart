import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/data/models/payment_transaction_model.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_cubit.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_state.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class RefundPaymentDialog extends StatefulWidget {
  final PaymentTransactionModel payment;

  const RefundPaymentDialog({
    super.key,
    required this.payment,
  });

  @override
  State<RefundPaymentDialog> createState() => _RefundPaymentDialogState();
}

class _RefundPaymentDialogState extends State<RefundPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final egp = (widget.payment.amountPiastres ?? 0) / 100.0;
    _amountController = TextEditingController(text: egp.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>().state;
    final user = session.currentUser;

    return BlocConsumer<CashierCubit, CashierState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          CustomToast(
            context: context,
            header: state.errorMessage!.tr(),
          ).showErrorToast();
          context.read<CashierCubit>().clearMessages();
        } else if (state.successMessage != null && state.lastRefund != null) {
          CustomToast(
            context: context,
            header: state.successMessage!.tr(),
          ).showTopToast();
          context.read<CashierCubit>().clearMessages();
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop(true);
          }
        }
      },
      builder: (context, state) {
        final activeShiftId = state.activeShift?.id;

        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.replay_rounded,
                                  color: AppColors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'cashier_refund_dialog_title'.tr(),
                                  style: CustomAppFontStyle.bold17.copyWith(
                                    color: AppColors.darkText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close,
                              color: AppColors.gray71717A),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Payment Details Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.grayf6,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grayE2E8F0),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.payment.patientName ?? '-',
                                style: CustomAppFontStyle.bold14.copyWith(
                                  color: AppColors.darkText,
                                ),
                              ),
                              Text(
                                widget.payment.receiptNumber.isNotEmpty
                                    ? widget.payment.receiptNumber
                                    : '-',
                                style: CustomAppFontStyle.medium12.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'cashier_amount'.tr(),
                                style: CustomAppFontStyle.regular12.copyWith(
                                  color: AppColors.gray71717A,
                                ),
                              ),
                              Text(
                                Money(widget.payment.amountPiastres ?? 0)
                                    .formatEgp(),
                                style: CustomAppFontStyle.bold14.copyWith(
                                  color: const Color(0xff007834),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Refund Amount Field
                    CustomTextFormField(
                      controller: _amountController,
                      headerText: 'cashier_refund_amount_label'.tr(),
                      textInputType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'cashier_validation_amount_required'.tr();
                        }
                        final parsed = double.tryParse(val.trim());
                        final maxEgp =
                            (widget.payment.amountPiastres ?? 0) / 100.0;
                        if (parsed == null || parsed <= 0 || parsed > maxEgp) {
                          return 'cashier_validation_amount_required'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Reason Field
                    CustomTextFormField(
                      controller: _reasonController,
                      headerText: 'cashier_refund_reason_label'.tr(),
                      hintText: 'cashier_refund_reason_label'.tr(),
                      maxLine: 2,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'cashier_validation_reason_required'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        CustomPushButton(
                          height: 40,
                          backgroundColor: AppColors.white,
                          boxBorder: Border.all(color: AppColors.grayE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'cancel'.tr(),
                            style: CustomAppFontStyle.medium13.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                        ),
                        CustomPushButton(
                          height: 40,
                          backgroundColor: AppColors.red,
                          borderRadius: BorderRadius.circular(10),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          isLoading: state.isSubmitting,
                          onTap: () {
                            if (activeShiftId == null) {
                              CustomToast(
                                context: context,
                                header: 'cashier_no_active_shift'.tr(),
                              ).showErrorToast();
                              return;
                            }
                            if (_formKey.currentState?.validate() ?? false) {
                              final money = Money.fromEgpString(
                                  _amountController.text.trim());
                              context.read<CashierCubit>().refundPayment(
                                    clientRequestId:
                                        'req-ref-${DateTime.now().millisecondsSinceEpoch}',
                                    originalPaymentId: widget.payment.id!,
                                    shiftId: activeShiftId,
                                    branchId: widget.payment.branchId!,
                                    bookingId: widget.payment.bookingId!,
                                    patientId: widget.payment.patientId ?? '',
                                    refundAmountPiastres: money.piastres,
                                    refundMethod: widget.payment.paymentMethod
                                            ?.name ??
                                        PaymentMethod.cash.name,
                                    reason: _reasonController.text.trim(),
                                    authorizedByUserId: user?.id,
                                    authorizedByName: user?.fullName,
                                  );
                            }
                          },
                          child: Text(
                            'cashier_confirm_refund'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
