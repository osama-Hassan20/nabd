import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_cubit.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_state.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class CollectPaymentDialog extends StatefulWidget {
  final String bookingId;
  final String patientId;
  final String patientName;
  final num totalPrice;
  final num paidAmount;
  final String? shiftId;
  final String? branchId;
  final CashierCubit? cashierCubit;

  const CollectPaymentDialog({
    super.key,
    required this.bookingId,
    required this.patientId,
    required this.patientName,
    required this.totalPrice,
    required this.paidAmount,
    this.shiftId,
    this.branchId,
    this.cashierCubit,
  });

  @override
  State<CollectPaymentDialog> createState() => _CollectPaymentDialogState();
}

class _CollectPaymentDialogState extends State<CollectPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _methodController;
  final _refNumberController = TextEditingController();
  final _notesController = TextEditingController();

  PaymentMethod _selectedMethod = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    final remaining = widget.totalPrice - widget.paidAmount;
    final initialEgp = remaining > 0 ? remaining.toDouble() : 0.0;
    _amountController =
        TextEditingController(text: initialEgp.toStringAsFixed(2));
    _methodController =
        TextEditingController(text: PaymentMethod.cash.translationKey.tr());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _methodController.dispose();
    _refNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = widget.cashierCubit ??
        (context.mounted
            ? (() {
                try {
                  return context.read<CashierCubit>();
                } catch (_) {
                  return getIt<CashierCubit>();
                }
              })()
            : getIt<CashierCubit>());

    final session = context.read<SessionCubit>().state;
    final effectiveBranchId =
        widget.branchId ?? session.activeBranchId ?? 'branch_1';
    final user = session.currentUser;

    final remaining = widget.totalPrice - widget.paidAmount;

    return BlocConsumer<CashierCubit, CashierState>(
      bloc: cubit,
      listener: (context, state) {
        if (state.errorMessage != null) {
          CustomToast(
            context: context,
            header: state.errorMessage!.tr(),
          ).showErrorToast();
          cubit.clearMessages();
        } else if (state.successMessage != null && state.lastPayment != null) {
          CustomToast(
            context: context,
            header: state.successMessage!.tr(),
          ).showTopToast();
          cubit.clearMessages();
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop(true);
          }
        }
      },
      builder: (context, state) {
        final activeShiftId = widget.shiftId ?? state.activeShift?.id;

        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 500,
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
                                  color: const Color(0xff007834)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.payment_rounded,
                                  color: Color(0xff007834),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'cashier_collect_dialog_title'.tr(),
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

                    // Booking Summary Card
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
                                widget.patientName,
                                style: CustomAppFontStyle.bold14.copyWith(
                                  color: AppColors.darkText,
                                ),
                              ),
                              Text(
                                '#${widget.bookingId}',
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'cashier_total_required'.tr(),
                                      style: CustomAppFontStyle.regular11.copyWith(
                                        color: AppColors.gray71717A,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Money(Money.egpToPiastres(widget.totalPrice.toDouble())).formatEgp(),
                                      style: CustomAppFontStyle.bold13.copyWith(
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'cashier_already_paid'.tr(),
                                      style: CustomAppFontStyle.regular11.copyWith(
                                        color: AppColors.gray71717A,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Money(Money.egpToPiastres(widget.paidAmount.toDouble())).formatEgp(),
                                      style: CustomAppFontStyle.semiBold13.copyWith(
                                        color: const Color(0xff007834),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'cashier_remaining_balance'.tr(),
                                      style: CustomAppFontStyle.regular11.copyWith(
                                        color: AppColors.gray71717A,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Money(Money.egpToPiastres(remaining.toDouble())).formatEgp(),
                                      style: CustomAppFontStyle.bold13.copyWith(
                                        color: remaining > 0
                                            ? AppColors.red
                                            : const Color(0xff007834),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Amount Field
                    CustomTextFormField(
                      controller: _amountController,
                      headerText: 'cashier_amount_to_collect'.tr(),
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
                        if (parsed == null || parsed <= 0) {
                          return 'cashier_validation_amount_required'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Payment Method Selector
                    CustomStackSelector<PaymentMethod>(
                      controller: _methodController,
                      header: 'cashier_payment_method'.tr(),
                      list: const [
                        PaymentMethod.cash,
                        PaymentMethod.card,
                        PaymentMethod.bankTransfer,
                      ],
                      itemAsString: (m) => m.translationKey.tr(),
                      changeValue: (m) {
                        setState(() {
                          _selectedMethod = m;
                          _methodController.text = m.translationKey.tr();
                        });
                      },
                    ),

                    if (_selectedMethod != PaymentMethod.cash) ...[
                      const SizedBox(height: 14),
                      CustomTextFormField(
                        controller: _refNumberController,
                        headerText: 'cashier_ref_number_label'.tr(),
                        hintText: 'cashier_ref_number_label'.tr(),
                      ),
                    ],

                    const SizedBox(height: 14),
                    CustomTextFormField(
                      controller: _notesController,
                      headerText: 'cashier_notes_label'.tr(),
                      hintText: 'cashier_notes_hint'.tr(),
                      maxLine: 2,
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
                          backgroundColor: const Color(0xff007834),
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
                              cubit.collectPayment(
                                    clientRequestId:
                                        'req-col-${CairoTimeHelper.now().millisecondsSinceEpoch}',
                                    shiftId: activeShiftId,
                                    branchId: effectiveBranchId,
                                    bookingId: widget.bookingId,
                                    patientId: widget.patientId,
                                    patientName: widget.patientName,
                                    amountPiastres: money.piastres,
                                    paymentMethod: _selectedMethod.name,
                                    cashierUserId: user?.id,
                                    cashierName: user?.fullName,
                                    referenceNumber: _refNumberController.text
                                            .trim()
                                            .isNotEmpty
                                        ? _refNumberController.text.trim()
                                        : null,
                                    notes: _notesController.text
                                            .trim()
                                            .isNotEmpty
                                        ? _notesController.text.trim()
                                        : null,
                                  );
                            }
                          },
                          child: Text(
                            'cashier_collect_btn'.tr(),
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
