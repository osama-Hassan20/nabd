import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/custom_stack_selector.dart';
import '../../data/models/enums/settlement_status_enum.dart';
import '../manager/hr_cubit.dart';
import '../manager/hr_state.dart';
import 'dialogs/calculate_settlement_draft_dialog.dart';
import 'dialogs/doctor_compensation_rule_dialog.dart';

class SettlementsFilterBar extends StatefulWidget {
  const SettlementsFilterBar({super.key});

  @override
  State<SettlementsFilterBar> createState() => _SettlementsFilterBarState();
}

class _SettlementsFilterBarState extends State<SettlementsFilterBar> {
  late final TextEditingController _statusController;

  @override
  void initState() {
    super.initState();
    _statusController = TextEditingController();
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  String _statusLabel(SettlementStatusEnum? s) {
    if (s == null) return 'hr_all_statuses'.tr();
    switch (s) {
      case SettlementStatusEnum.draft:
        return 'hr_status_draft'.tr();
      case SettlementStatusEnum.confirmed:
        return 'hr_status_confirmed'.tr();
      case SettlementStatusEnum.paid:
        return 'hr_status_paid'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HrCubit, HrState>(
      builder: (context, state) {
        final colors = context.themeColors;
        if (_statusController.text.isEmpty && state.filterSettlementStatus != null) {
          _statusController.text = _statusLabel(state.filterSettlementStatus);
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Doctor Filter
                SizedBox(
                  width: 180,
                  child: TextField(
                    key: const Key('filter_doctor'),
                    decoration: InputDecoration(
                      hintText: 'hr_filter_doctor'.tr(),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) {
                      context.read<HrCubit>().setDoctorFilter(val.isEmpty ? null : val);
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Status Filter Dropdown
                SizedBox(
                  width: 170,
                  child: CustomStackSelector<SettlementStatusEnum?>(
                    key: const Key('filter_status'),
                    controller: _statusController,
                    hintText: 'hr_filter_status'.tr(),
                    list: const [
                      null,
                      SettlementStatusEnum.draft,
                      SettlementStatusEnum.confirmed,
                      SettlementStatusEnum.paid,
                    ],
                    itemAsString: _statusLabel,
                    changeValue: (val) {
                      _statusController.text = _statusLabel(val);
                      context.read<HrCubit>().setStatusFilter(val);
                    },
                  ),
                ),

                const SizedBox(width: 32),

                // Calculate Draft Button
                ElevatedButton.icon(
                  key: const Key('btn_open_calculate_draft'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.calculate_outlined, size: 18),
                  label: Text('hr_action_calculate_draft'.tr(), style: CustomAppFontStyle.bold13),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: context.read<HrCubit>(),
                        child: const CalculateSettlementDraftDialog(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),

                // Manage Rules Button
                OutlinedButton.icon(
                  key: const Key('btn_open_compensation_rules'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.tune_outlined, size: 18),
                  label: Text('hr_action_manage_rules'.tr(), style: CustomAppFontStyle.bold13),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: context.read<HrCubit>(),
                        child: const DoctorCompensationRuleDialog(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
