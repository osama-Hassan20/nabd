import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_cubit.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_state.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class OpenShiftDialog extends StatefulWidget {
  const OpenShiftDialog({super.key});

  @override
  State<OpenShiftDialog> createState() => _OpenShiftDialogState();
}

class _OpenShiftDialogState extends State<OpenShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _openingBalanceController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _openingBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>().state;
    final branchId = session.activeBranchId ?? 'branch_1';
    final user = session.currentUser;

    return BlocConsumer<CashierCubit, CashierState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          CustomToast(
            context: context,
            header: state.errorMessage!.tr(),
          ).showErrorToast();
          context.read<CashierCubit>().clearMessages();
        } else if (state.successMessage != null && state.activeShift != null) {
          CustomToast(
            context: context,
            header: state.successMessage!.tr(),
          ).showTopToast();
          context.read<CashierCubit>().clearMessages();
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
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
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.lock_open_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'cashier_open_dialog_title'.tr(),
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
                        icon: const Icon(Icons.close, color: AppColors.gray71717A),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Opening Balance Field
                  CustomTextFormField(
                    controller: _openingBalanceController,
                    headerText: 'cashier_opening_balance_label'.tr(),
                    hintText: 'cashier_opening_balance_hint'.tr(),
                    textInputType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
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
                  const SizedBox(height: 16),

                  // Opening Notes
                  CustomTextFormField(
                    controller: _notesController,
                    headerText: 'cashier_notes_label'.tr(),
                    hintText: 'cashier_notes_hint'.tr(),
                    maxLine: 3,
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
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
                        backgroundColor: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        isLoading: state.isSubmitting,
                        onTap: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final money = Money.fromEgpString(
                                _openingBalanceController.text.trim());
                            context.read<CashierCubit>().openShift(
                                  branchId: branchId,
                                  openingBalancePiastres: money.piastres,
                                  cashierUserId: user?.id,
                                  cashierName: user?.fullName,
                                );
                          }
                        },
                        child: Text(
                          'cashier_open_shift_btn'.tr(),
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
        );
      },
    );
  }
}
