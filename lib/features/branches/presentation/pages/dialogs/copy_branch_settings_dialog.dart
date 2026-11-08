import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/branches/data/models/branch_model.dart';
import 'package:eyadty/features/branches/data/models/copy_branch_settings_param.dart';
import 'package:eyadty/features/branches/presentation/cubit/branches_cubit.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class CopyBranchSettingsDialog extends StatefulWidget {
  final BranchModel targetBranch;
  final List<BranchModel> allBranches;

  const CopyBranchSettingsDialog({
    super.key,
    required this.targetBranch,
    required this.allBranches,
  });

  @override
  State<CopyBranchSettingsDialog> createState() =>
      _CopyBranchSettingsDialogState();
}

class _CopyBranchSettingsDialogState extends State<CopyBranchSettingsDialog> {
  String? _selectedSourceBranchId;
  bool _copyWorkingHours = true;
  bool _copySpecialHolidays = true;
  bool _copyMedicalServices = true;
  bool _copyDoctorSchedules = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final eligible = widget.allBranches
        .where((b) => b.id != widget.targetBranch.id && b.isBranchActive)
        .toList();
    if (eligible.isNotEmpty) {
      _selectedSourceBranchId = eligible.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BranchesCubit>();
    final currentUserId = getIt.isRegistered<SessionCubit>()
        ? getIt<SessionCubit>().currentUser?.id ?? 'USER-OWNER'
        : 'USER-OWNER';

    final eligibleSources = widget.allBranches
        .where((b) => b.id != widget.targetBranch.id)
        .toList();

    final targetName = (widget.targetBranch.nameKey != null &&
            widget.targetBranch.nameKey!.isNotEmpty)
        ? widget.targetBranch.nameKey!.tr()
        : (widget.targetBranch.name ?? '');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.copy_rounded,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'copy_settings'.tr(),
                            style: CustomAppFontStyle.bold16.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${'target_branch'.tr()}: $targetName',
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: AppColors.gray71717A,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: AppColors.gray71717A),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.grayE2E8F0),

              // Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'source_branch'.tr(),
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Source Branch Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.grayE2E8F0),
                        color: AppColors.fillDisableColor.withValues(alpha: 0.2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSourceBranchId,
                          isExpanded: true,
                          hint: Text('select_branch'.tr(),
                              style: CustomAppFontStyle.regular13),
                          items: eligibleSources.map((b) {
                            final name = (b.nameKey != null &&
                                    b.nameKey!.isNotEmpty)
                                ? b.nameKey!.tr()
                                : (b.name ?? '');
                            return DropdownMenuItem<String>(
                              value: b.id,
                              child: Text(name,
                                  style: CustomAppFontStyle.medium13),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedSourceBranchId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'select_settings_to_copy'.tr(),
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Options Checkboxes
                    _buildCheckboxTile(
                      title: 'copy_working_hours'.tr(),
                      subtitle: 'copy_working_hours_desc'.tr(),
                      value: _copyWorkingHours,
                      onChanged: (val) =>
                          setState(() => _copyWorkingHours = val ?? false),
                    ),
                    const SizedBox(height: 8),
                    _buildCheckboxTile(
                      title: 'copy_special_holidays'.tr(),
                      subtitle: 'copy_special_holidays_desc'.tr(),
                      value: _copySpecialHolidays,
                      onChanged: (val) =>
                          setState(() => _copySpecialHolidays = val ?? false),
                    ),
                    const SizedBox(height: 8),
                    _buildCheckboxTile(
                      title: 'copy_services'.tr(),
                      subtitle: 'copy_services_desc'.tr(),
                      value: _copyMedicalServices,
                      onChanged: (val) =>
                          setState(() => _copyMedicalServices = val ?? false),
                    ),
                    const SizedBox(height: 8),
                    _buildCheckboxTile(
                      title: 'copy_schedules'.tr(),
                      subtitle: 'copy_schedules_desc'.tr(),
                      value: _copyDoctorSchedules,
                      onChanged: (val) =>
                          setState(() => _copyDoctorSchedules = val ?? false),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.grayE2E8F0),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomPushButton(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      backgroundColor: AppColors.fillDisableColor,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).pop(),
                      child: Center(
                        child: Text(
                          'cancel'.tr(),
                          style: CustomAppFontStyle.medium13.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CustomPushButton(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      backgroundColor: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(8),
                      isLoading: _isLoading,
                      onTap: () async {
                        if (_selectedSourceBranchId == null) {
                          CustomToast(
                            context: context,
                            header: 'please_select_source_branch'.tr(),
                          ).showErrorToast();
                          return;
                        }

                        if (!_copyWorkingHours &&
                            !_copySpecialHolidays &&
                            !_copyMedicalServices &&
                            !_copyDoctorSchedules) {
                          CustomToast(
                            context: context,
                            header: 'please_select_at_least_one_option'.tr(),
                          ).showErrorToast();
                          return;
                        }

                        setState(() => _isLoading = true);

                        final param = CopyBranchSettingsParam(
                          sourceBranchId: _selectedSourceBranchId,
                          targetBranchId: widget.targetBranch.id,
                          copyWorkingHours: _copyWorkingHours,
                          copySpecialHolidays: _copySpecialHolidays,
                          copyMedicalServices: _copyMedicalServices,
                          copyDoctorSchedules: _copyDoctorSchedules,
                        );

                        final ok = await cubit.copySettingsFromBranch(
                          param,
                          currentUserId: currentUserId,
                        );

                        if (!mounted) return;
                        setState(() => _isLoading = false);

                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Center(
                        child: Text(
                          'confirm_copy'.tr(),
                          style: CustomAppFontStyle.semiBold13.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFFEEF2FF)
            : AppColors.fillDisableColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? const Color(0xFFC7D2FE) : AppColors.grayE2E8F0,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: const Color(0xFF6366F1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: onChanged,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CustomAppFontStyle.semiBold13.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  subtitle,
                  style: CustomAppFontStyle.regular11.copyWith(
                    color: AppColors.gray71717A,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
