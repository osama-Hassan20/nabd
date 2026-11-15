import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_state.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'dialogs/add_ledger_entry_dialog.dart';
import 'employee_ledger_table.dart';

class EmployeeLedgerTab extends StatefulWidget {
  const EmployeeLedgerTab({super.key});

  @override
  State<EmployeeLedgerTab> createState() => _EmployeeLedgerTabState();
}

class _EmployeeLedgerTabState extends State<EmployeeLedgerTab> {
  late TextEditingController _employeeIdController;

  @override
  void initState() {
    super.initState();
    _employeeIdController = TextEditingController();
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HrCubit, HrState>(
      builder: (context, state) {
        final evaluator = context.read<HrCubit>().permissionEvaluator;
        final user = state.currentUser;

        // RBAC: manageEmployeeLedger or Owner
        final hasAccess = user?.isOwner == true ||
            (evaluator != null &&
                evaluator.can(
                  StaffPermissionEnum.manageEmployeeLedger,
                  branchId: state.currentBranchId,
                ));

        if (!hasAccess) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 56, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'hr_unauthorized_ledger'.tr(),
                    style: CustomAppFontStyle.bold16.copyWith(color: AppColors.darkText),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Controls Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grayE2E8F0),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Employee Search / Input
                      SizedBox(
                        width: 220,
                        child: CustomTextFormField(
                          key: const Key('field_ledger_employee_id'),
                          controller: _employeeIdController,
                          hintText: 'hr_employee_id_hint'.tr(),
                          onChanged: (val) {
                            final text = val?.trim() ?? '';
                            if (text.isNotEmpty) {
                              context.read<HrCubit>().loadEmployeeLedger(text);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Outstanding Advances Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLevel1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.grayE2E8F0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              '${'hr_outstanding_advances_label'.tr()}: ',
                              style: CustomAppFontStyle.regular13.copyWith(color: AppColors.gray71717A),
                            ),
                            Text(
                              Money.fromPiastres(state.outstandingAdvancesPiastres).formatEgp(),
                              key: const Key('text_outstanding_advances'),
                              style: CustomAppFontStyle.bold14.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Add Ledger Entry Button
                      ElevatedButton.icon(
                        key: const Key('btn_open_add_ledger_entry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text('hr_add_advance_btn'.tr(), style: CustomAppFontStyle.bold13),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => BlocProvider.value(
                              value: context.read<HrCubit>(),
                              child: AddLedgerEntryDialog(
                                initialEmployeeId: _employeeIdController.text.trim().isNotEmpty
                                    ? _employeeIdController.text.trim()
                                    : state.selectedEmployeeId,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Ledger Table
              EmployeeLedgerTable(entries: state.ledgerEntries),
            ],
          ),
        );
      },
    );
  }
}
