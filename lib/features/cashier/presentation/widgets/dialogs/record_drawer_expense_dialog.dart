import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/data/models/enums/cash_movement_type_enum.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_cubit.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_state.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class RecordDrawerExpenseDialog extends StatefulWidget {
  final String shiftId;
  final String branchId;
  final CashierCubit? cashierCubit;

  const RecordDrawerExpenseDialog({
    super.key,
    required this.shiftId,
    required this.branchId,
    this.cashierCubit,
  });

  @override
  State<RecordDrawerExpenseDialog> createState() =>
      _RecordDrawerExpenseDialogState();
}

class _RecordDrawerExpenseDialogState extends State<RecordDrawerExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  late final TextEditingController _typeController;
  final _reasonController = TextEditingController();
  final _recipientController = TextEditingController();

  CashMovementTypeEnum _selectedType = CashMovementTypeEnum.pettyExpense;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(
      text: _getMovementLabel(CashMovementTypeEnum.pettyExpense),
    );
  }

  String _getMovementLabel(CashMovementTypeEnum type) {
    switch (type) {
      case CashMovementTypeEnum.pettyExpense:
        return 'cashier_movement_petty_expense'.tr();
      case CashMovementTypeEnum.capitalInjection:
        return 'cashier_movement_capital_injection'.tr();
      case CashMovementTypeEnum.bankDeposit:
        return 'cashier_movement_bank_deposit'.tr();
      case CashMovementTypeEnum.ownerWithdrawal:
        return 'cashier_movement_owner_withdrawal'.tr();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _typeController.dispose();
    _reasonController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CashierCubit cubit;
    try {
      cubit = widget.cashierCubit ?? context.read<CashierCubit>();
    } catch (_) {
      cubit = getIt<CashierCubit>();
    }

    final session = context.read<SessionCubit>().state;
    final user = session.currentUser;

    return BlocConsumer<CashierCubit, CashierState>(
      bloc: cubit,
      listener: (context, state) {
        if (state.errorMessage != null) {
          CustomToast(
            context: context,
            header: state.errorMessage!.tr(),
          ).showErrorToast();
          cubit.clearMessages();
        } else if (state.successMessage != null) {
          CustomToast(
            context: context,
            header: state.successMessage!.tr(),
          ).showTopToast();
          cubit.clearMessages();
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
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
                                  color: const Color(0xffF59E0B)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Color(0xffD97706),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'cashier_expense_dialog_title'.tr(),
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

                    // Movement Type Selector
                    CustomStackSelector<CashMovementTypeEnum>(
                      controller: _typeController,
                      header: 'cashier_movement_type_label'.tr(),
                      list: CashMovementTypeEnum.values,
                      itemAsString: _getMovementLabel,
                      changeValue: (type) {
                        setState(() {
                          _selectedType = type;
                          _typeController.text = _getMovementLabel(type);
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Amount Field
                    CustomTextFormField(
                      controller: _amountController,
                      headerText: 'cashier_expense_amount_label'.tr(),
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

                    // Reason Field
                    CustomTextFormField(
                      controller: _reasonController,
                      headerText: 'cashier_expense_reason_label'.tr(),
                      hintText: 'cashier_expense_reason_label'.tr(),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'cashier_validation_reason_required'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Recipient Field
                    CustomTextFormField(
                      controller: _recipientController,
                      headerText: 'cashier_recipient_label'.tr(),
                      hintText: 'cashier_recipient_label'.tr(),
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
                          backgroundColor: const Color(0xffD97706),
                          borderRadius: BorderRadius.circular(10),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          isLoading: state.isSubmitting,
                          onTap: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              final money = Money.fromEgpString(
                                  _amountController.text.trim());
                              cubit.recordDrawerExpense(
                                clientRequestId:
                                    'req-exp-${CairoTimeHelper.now().millisecondsSinceEpoch}',
                                shiftId: widget.shiftId,
                                branchId: widget.branchId,
                                movementType: _selectedType.name,
                                amountPiastres: money.piastres,
                                reason: _reasonController.text.trim(),
                                recipientName:
                                    _recipientController.text.trim().isNotEmpty
                                        ? _recipientController.text.trim()
                                        : null,
                                performedByUserId: user?.id,
                              );
                            }
                          },
                          child: Text(
                            'save'.tr(),
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
