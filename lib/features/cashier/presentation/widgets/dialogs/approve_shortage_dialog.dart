import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/data/models/cashier_shift_model.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_cubit.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_state.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class ApproveShortageDialog extends StatefulWidget {
  final CashierShiftModel shift;

  const ApproveShortageDialog({
    super.key,
    required this.shift,
  });

  @override
  State<ApproveShortageDialog> createState() => _ApproveShortageDialogState();
}

class _ApproveShortageDialogState extends State<ApproveShortageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>().state;
    final user = session.currentUser;

    final diffPiastres = widget.shift.cashDifferencePiastres ?? 0;
    final shortageMoney = Money(diffPiastres.abs()).formatEgp();

    return BlocConsumer<CashierCubit, CashierState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          CustomToast(
            context: context,
            header: state.errorMessage!.tr(),
          ).showErrorToast();
          context.read<CashierCubit>().clearMessages();
        } else if (state.successMessage != null) {
          CustomToast(
            context: context,
            header: state.successMessage!.tr(),
          ).showTopToast();
          context.read<CashierCubit>().clearMessages();
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
                                  color: const Color(0xffFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.verified_user_rounded,
                                  color: Color(0xffD97706),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'cashier_approve_shortage_dialog_title'.tr(),
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
                    const SizedBox(height: 18),

                    // Prompt text
                    Text(
                      'cashier_approve_shortage_prompt'.tr(),
                      style: CustomAppFontStyle.regular13.copyWith(
                        color: AppColors.gray71717A,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Shift Discrepancy Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.red.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${'cashier_shift_code'.tr()}: #${widget.shift.id}',
                                style: CustomAppFontStyle.bold13.copyWith(
                                  color: AppColors.darkText,
                                ),
                              ),
                              Text(
                                widget.shift.cashierName ?? 'كاشير',
                                style: CustomAppFontStyle.medium12.copyWith(
                                  color: AppColors.gray71717A,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'قيمة العجز المسجل:',
                                style: CustomAppFontStyle.medium13.copyWith(
                                  color: AppColors.darkText,
                                ),
                              ),
                              Text(
                                '-$shortageMoney',
                                style: CustomAppFontStyle.bold15.copyWith(
                                  color: AppColors.red,
                                ),
                              ),
                            ],
                          ),
                          if (widget.shift.shortageReason != null &&
                              widget.shift.shortageReason!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'توضيح الكاشير: ${widget.shift.shortageReason!}',
                                style: CustomAppFontStyle.regular12.copyWith(
                                  color: AppColors.gray71717A,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Reason Field
                    CustomTextFormField(
                      controller: _reasonController,
                      headerText: 'cashier_approval_notes_label'.tr(),
                      hintText: 'cashier_approval_notes_label'.tr(),
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
                          backgroundColor: const Color(0xffD97706),
                          borderRadius: BorderRadius.circular(10),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          isLoading: state.isSubmitting,
                          onTap: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              context.read<CashierCubit>().approveShortage(
                                    shiftId: widget.shift.id!,
                                    branchId: widget.shift.branchId!,
                                    cashierUserId: widget.shift.cashierUserId!,
                                    reason: _reasonController.text.trim(),
                                    approvedByUserId: user?.id,
                                  );
                            }
                          },
                          child: Text(
                            'cashier_approve_shortage_btn'.tr(),
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
