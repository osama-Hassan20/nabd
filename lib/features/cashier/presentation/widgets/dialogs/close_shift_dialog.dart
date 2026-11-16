import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/data/models/cashier_shift_model.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_cubit.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_state.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class CloseShiftDialog extends StatefulWidget {
  final CashierShiftModel shift;
  final CashierCubit? cashierCubit;

  const CloseShiftDialog({
    super.key,
    required this.shift,
    this.cashierCubit,
  });

  @override
  State<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<CloseShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _actualCashController;
  final _closingNotesController = TextEditingController();
  final _shortageReasonController = TextEditingController();

  int _countedPiastres = 0;
  bool _hasShortage = false;

  @override
  void initState() {
    super.initState();
    final expectedEgp =
        (widget.shift.expectedCashPiastres ?? 0) / 100.0;
    _actualCashController =
        TextEditingController(text: expectedEgp.toStringAsFixed(2));
    _countedPiastres = widget.shift.expectedCashPiastres ?? 0;
    _actualCashController.addListener(_onCashCountChanged);
  }

  void _onCashCountChanged() {
    final parsedMoney =
        Money.fromEgpString(_actualCashController.text.trim());
    final expected = widget.shift.expectedCashPiastres ?? 0;
    final diff = parsedMoney.piastres - expected;

    if (mounted) {
      setState(() {
        _countedPiastres = parsedMoney.piastres;
        _hasShortage = diff < 0;
      });
    }
  }

  @override
  void dispose() {
    _actualCashController.removeListener(_onCashCountChanged);
    _actualCashController.dispose();
    _closingNotesController.dispose();
    _shortageReasonController.dispose();
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

    final expectedPiastres = widget.shift.expectedCashPiastres ?? 0;
    final diffPiastres = _countedPiastres - expectedPiastres;

    return BlocConsumer<CashierCubit, CashierState>(
      bloc: cubit,
      listener: (context, state) {
        if (state.errorMessage != null) {
          CustomToast(
            context: context,
            header: state.errorMessage!.tr(),
          ).showErrorToast();
          cubit.clearMessages();
        } else if (state.successMessage != null && state.activeShift == null) {
          CustomToast(
            context: context,
            header: state.successMessage!.tr(),
          ).showTopToast();
          cubit.clearMessages();
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 520,
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
                                  Icons.lock_clock_rounded,
                                  color: AppColors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'cashier_close_dialog_title'.tr(),
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

                    // Expected Cash Display Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'cashier_expected_cash'.tr(),
                              style: CustomAppFontStyle.medium13.copyWith(
                                color: AppColors.gray71717A,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            Money(expectedPiastres).formatEgp(),
                            style: CustomAppFontStyle.bold16.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Actual Counted Cash Input
                    CustomTextFormField(
                      controller: _actualCashController,
                      headerText: 'cashier_actual_cash_label'.tr(),
                      hintText: 'cashier_actual_cash_hint'.tr(),
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
                        if (parsed == null || parsed < 0) {
                          return 'cashier_validation_amount_required'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Discrepancy Indicator Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: diffPiastres < 0
                            ? AppColors.red.withValues(alpha: 0.08)
                            : diffPiastres > 0
                                ? const Color(0xff007834).withValues(alpha: 0.08)
                                : AppColors.grayf6,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: diffPiastres < 0
                              ? AppColors.red.withValues(alpha: 0.3)
                              : diffPiastres > 0
                                  ? const Color(0xff007834).withValues(alpha: 0.3)
                                  : AppColors.grayE2E8F0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            diffPiastres < 0
                                ? Icons.warning_amber_rounded
                                : diffPiastres > 0
                                    ? Icons.arrow_upward_rounded
                                    : Icons.check_circle_rounded,
                            size: 18,
                            color: diffPiastres < 0
                                ? AppColors.red
                                : diffPiastres > 0
                                    ? const Color(0xff007834)
                                    : AppColors.gray71717A,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              diffPiastres < 0
                                  ? '${'cashier_difference_label'.tr()}: -${Money(diffPiastres.abs()).formatEgp()} (${'cashier_shortage_warning'.tr()})'
                                  : diffPiastres > 0
                                      ? '${'cashier_difference_label'.tr()}: +${Money(diffPiastres).formatEgp()} (${'cashier_surplus_notice'.tr()})'
                                      : 'cashier_exact_match'.tr(),
                              style: CustomAppFontStyle.medium12.copyWith(
                                color: diffPiastres < 0
                                    ? AppColors.red
                                    : diffPiastres > 0
                                        ? const Color(0xff007834)
                                        : AppColors.darkText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_hasShortage) ...[
                      const SizedBox(height: 14),
                      CustomTextFormField(
                        controller: _shortageReasonController,
                        headerText: 'cashier_shortage_reason_label'.tr(),
                        hintText: 'cashier_shortage_reason_label'.tr(),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'cashier_validation_reason_required'.tr();
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 14),
                    CustomTextFormField(
                      controller: _closingNotesController,
                      headerText: 'cashier_closing_notes_label'.tr(),
                      hintText: 'cashier_closing_notes_label'.tr(),
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
                          backgroundColor: AppColors.red,
                          borderRadius: BorderRadius.circular(10),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          isLoading: state.isSubmitting,
                          onTap: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              cubit.closeShift(
                                shiftId: widget.shift.id!,
                                actualCashCountPiastres: _countedPiastres,
                                closingNotes:
                                    _closingNotesController.text.trim(),
                                shortageReason: _hasShortage
                                    ? _shortageReasonController.text.trim()
                                    : null,
                              );
                            }
                          },
                          child: Text(
                            'cashier_confirm_close'.tr(),
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
