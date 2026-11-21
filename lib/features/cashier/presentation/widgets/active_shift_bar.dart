import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/data/models/cashier_shift_model.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/cashier/presentation/helpers/adaptive_shift_report_pdf_generator.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_cubit.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/domain/repo/settings_repo.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'dialogs/close_shift_dialog.dart';
import 'dialogs/open_shift_dialog.dart';
import 'dialogs/record_drawer_expense_dialog.dart';

class ActiveShiftBar extends StatelessWidget {
  final CashierShiftModel? activeShift;
  final VoidCallback? onRefresh;

  const ActiveShiftBar({
    super.key,
    required this.activeShift,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (activeShift == null) {
      return _buildNoActiveShiftBanner(context);
    }
    return _buildActiveShiftBanner(context, activeShift!);
  }

  Widget _buildNoActiveShiftBanner(BuildContext context) {
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lock_clock_rounded,
              color: colors.secondary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'cashier_no_active_shift'.tr(),
                  style: CustomAppFontStyle.bold16.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'cashier_open_shift_prompt'.tr(),
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CustomPushButton(
            height: 42,
            backgroundColor: colors.primary,
            borderRadius: BorderRadius.circular(10),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            onTap: () {
              final cashierCubit = context.read<CashierCubit>();
              showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: cashierCubit,
                  child: OpenShiftDialog(cashierCubit: cashierCubit),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_box_rounded, color: AppColors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'cashier_open_shift_btn'.tr(),
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveShiftBanner(BuildContext context, CashierShiftModel shift) {
    final colors = context.themeColors;
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a');
    final formattedTime =
        shift.openedAt != null ? dateFormat.format(shift.openedAt!) : '-';
    final expectedCashFormatted =
        Money(shift.expectedCashPiastres ?? 0).formatEgp();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 14,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Shift Identity and status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.point_of_sale_rounded,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'cashier_active_shift_title'.tr(),
                        style: CustomAppFontStyle.bold16.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xff007834).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'cashier_status_open'.tr(),
                          style: CustomAppFontStyle.semiBold12.copyWith(
                            color: const Color(0xff007834),
                          ),
                        ),
                      ),
                      if (shift.id != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '#${shift.id}',
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 14, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        shift.cashierName ?? 'كاشير',
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(Icons.access_time_rounded,
                          size: 14, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        formattedTime,
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Expected Cash & Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expected Cash Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: colors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'cashier_expected_cash'.tr(),
                      style: CustomAppFontStyle.regular11.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expectedCashFormatted,
                      style: CustomAppFontStyle.bold16.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Print Current Shift Button
              CustomPushButton(
                key: const Key('print_active_shift_btn'),
                height: 40,
                backgroundColor: colors.cardBackground,
                boxBorder: Border.all(color: colors.borderSubtle),
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                onTap: () async {
                  try {
                    CompanySettingsModel? settings;
                    try {
                      final res =
                          await getIt<SettingsRepo>().getCompanySettings();
                      settings =
                          res.getOrElse(() => const CompanySettingsModel());
                    } catch (_) {}
                    final bytes =
                        await AdaptiveShiftReportPdfGenerator.generate(
                      shift: shift,
                      settings: settings,
                    );
                    await Printing.layoutPdf(
                      onLayout: (format) async => bytes,
                    );
                  } catch (_) {}
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.print_outlined,
                        color: colors.textPrimary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'print'.tr(),
                      style: CustomAppFontStyle.medium13.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Record Expense Button
              CustomPushButton(
                height: 40,
                backgroundColor: colors.cardBackground,
                boxBorder: Border.all(color: colors.borderSubtle),
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                onTap: () {
                  final cashierCubit = context.read<CashierCubit>();
                  showDialog(
                    context: context,
                    builder: (_) => BlocProvider.value(
                      value: cashierCubit,
                      child: RecordDrawerExpenseDialog(
                        shiftId: shift.id!,
                        branchId: shift.branchId!,
                        cashierCubit: cashierCubit,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        color: colors.textPrimary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'cashier_record_movement_btn'.tr(),
                      style: CustomAppFontStyle.medium13.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Close Shift Button
              CustomPushButton(
                height: 40,
                backgroundColor: AppColors.red,
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onTap: () {
                  final cashierCubit = context.read<CashierCubit>();
                  showDialog(
                    context: context,
                    builder: (_) => BlocProvider.value(
                      value: cashierCubit,
                      child: CloseShiftDialog(
                        shift: shift,
                        cashierCubit: cashierCubit,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'cashier_close_shift_btn'.tr(),
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
