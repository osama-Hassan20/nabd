import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/helpers/app_formatter_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/features/bookings/data/models/enums/discount_type_enum.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';

class BookingDiscountSection extends StatelessWidget {
  final TextEditingController discountTypeController;
  final TextEditingController discountValueController;
  final TextEditingController discountReasonController;

  const BookingDiscountSection({
    super.key,
    required this.discountTypeController,
    required this.discountValueController,
    required this.discountReasonController,
  });

  @override
  Widget build(BuildContext context) {
    final session = getIt.isRegistered<SessionCubit>()
        ? getIt<SessionCubit>()
        : null;
    final evaluator = getIt.isRegistered<PermissionEvaluator>()
        ? getIt<PermissionEvaluator>()
        : null;

    final user = session?.currentUser;
    final isOwner = user?.isOwner == true;

    final hasPerm = evaluator?.can(
          StaffPermissionEnum.applyBookingDiscount,
          branchId: session?.state.activeBranchId,
        ) ??
        isOwner;

    if (!hasPerm) return const SizedBox.shrink();

    final roles = session?.currentRoles ?? [];
    final branchAssignment = user?.branchAssignments
            ?.where((b) => b.branchId == session?.state.activeBranchId)
            .firstOrNull ??
        user?.branchAssignments?.firstOrNull;
    final userRoleIds = branchAssignment?.roleIds ?? [];
    final activeRoles =
        roles.where((r) => userRoleIds.contains(r.id)).toList();

    final canFree =
        isOwner || activeRoles.any((r) => r.canGrantFreeConsultation == true);
    final maxPct = isOwner
        ? 100
        : activeRoles
            .map((r) => r.maxDiscountPercent ?? 0)
            .fold<num>(0, (prev, val) => val > prev ? val : prev);

    final availableTypes = [
      DiscountTypeEnum.none,
      DiscountTypeEnum.percentage,
      DiscountTypeEnum.fixedAmount,
      if (canFree) DiscountTypeEnum.free,
    ];

    final cubit = context.watch<BookingsCubit>();
    final form = cubit.state.formState;
    final fee = form?.consultationFee ?? 0;
    final currentType = form?.discountType ?? DiscountTypeEnum.none;
    final discountAmount = form?.discountAmount ?? 0;
    final netAmount = form?.netAmount ?? fee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                size: 18,
                color: AppColors.primaryViolet,
              ),
              const SizedBox(width: 8),
              Text(
                'disc_section_title'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Discount Type Selector
          CustomStackSelector<DiscountTypeEnum>(
            controller: discountTypeController,
            header: 'disc_section_title'.tr(),
            hintText: 'disc_type_none'.tr(),
            list: availableTypes,
            itemAsString: (t) => t.localizedName,
            changeValue: (type) {
              discountTypeController.text = type.localizedName;
              if (type == DiscountTypeEnum.none) {
                discountValueController.text = '';
                discountReasonController.text = '';
                cubit.updateFormDiscount(
                  discountType: DiscountTypeEnum.none,
                  discountValue: 0,
                  discountReason: '',
                );
              } else if (type == DiscountTypeEnum.free) {
                discountValueController.text = '0';
                cubit.updateFormDiscount(
                  discountType: DiscountTypeEnum.free,
                  discountValue: 0,
                );
              } else {
                cubit.updateFormDiscount(discountType: type);
              }
            },
          ),
          const SizedBox(height: 14),

          // 2. Value Input if Percentage or Fixed
          if (currentType == DiscountTypeEnum.percentage) ...[
            CustomTextFormField(
              controller: discountValueController,
              headerText: 'disc_value_label'.tr(),
              hintText: 'disc_value_hint_pct'
                  .tr(namedArgs: {'max': '${isOwner ? 100 : maxPct}'}),
              textInputType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (val) {
                final numVal = num.tryParse(val ?? '') ?? 0;
                cubit.updateFormDiscount(discountValue: numVal);
              },
              validator: (val) {
                if (currentType != DiscountTypeEnum.percentage) return null;
                final numVal = num.tryParse(val ?? '') ?? 0;
                if (numVal < 0 || numVal > 100) {
                  return 'disc_validation_pct_range'.tr();
                }
                if (!isOwner && numVal > maxPct) {
                  return 'disc_validation_max_exceeded'
                      .tr(namedArgs: {'limit': '$maxPct'});
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
          ] else if (currentType == DiscountTypeEnum.fixedAmount) ...[
            CustomTextFormField(
              controller: discountValueController,
              headerText: 'disc_value_label'.tr(),
              hintText: 'disc_value_hint_fixed'.tr(
                namedArgs: {'max': AppFormatterHelper.formatCurrency(fee)},
              ),
              textInputType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (val) {
                final numVal = num.tryParse(val ?? '') ?? 0;
                cubit.updateFormDiscount(discountValue: numVal);
              },
              validator: (val) {
                if (currentType != DiscountTypeEnum.fixedAmount) return null;
                final numVal = num.tryParse(val ?? '') ?? 0;
                if (numVal < 0 || numVal > fee) {
                  return 'disc_validation_fixed_range'.tr();
                }
                if (!isOwner && fee > 0) {
                  final pct = (numVal / fee) * 100;
                  if (pct > maxPct) {
                    return 'disc_validation_max_exceeded'
                        .tr(namedArgs: {'limit': '$maxPct'});
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
          ],

          // 3. Reason Field (Required when discount is active)
          if (currentType != DiscountTypeEnum.none) ...[
            CustomTextFormField(
              controller: discountReasonController,
              headerText: currentType == DiscountTypeEnum.free
                  ? 'disc_reason_label'.tr()
                  : 'disc_reason_label'.tr(),
              hintText: 'disc_reason_hint'.tr(),
              onChanged: (val) {
                cubit.updateFormDiscount(discountReason: val?.trim() ?? '');
              },
              validator: (val) {
                if (currentType == DiscountTypeEnum.none) return null;
                if (val == null || val.trim().isEmpty) {
                  return currentType == DiscountTypeEnum.free
                      ? 'disc_validation_free_reason_required'.tr()
                      : 'disc_validation_reason_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
          ],

          // 4. Live Summary Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLevel1,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'disc_original_price'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray71717A,
                      ),
                    ),
                    Text(
                      AppFormatterHelper.formatCurrency(fee),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                if (currentType != DiscountTypeEnum.none) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'disc_discount_amount'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray71717A,
                        ),
                      ),
                      Text(
                        '- ${AppFormatterHelper.formatCurrency(discountAmount)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryViolet,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'disc_net_amount'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppFormatterHelper.formatCurrency(netAmount),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryViolet,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
