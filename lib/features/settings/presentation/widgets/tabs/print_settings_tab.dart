import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/settings/data/models/enums/print_format_enum.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_state.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class PrintSettingsTab extends StatefulWidget {
  const PrintSettingsTab({super.key});

  @override
  State<PrintSettingsTab> createState() => _PrintSettingsTabState();
}

class _PrintSettingsTabState extends State<PrintSettingsTab> {
  PrintFormat _receiptFormat = PrintFormat.a4;
  PrintFormat _shiftReportFormat = PrintFormat.a4;
  PrintFormat _prescriptionFormat = PrintFormat.a4;
  bool _initialized = false;

  void _syncFromSettings(SettingsState state) {
    if (state.settings != null && !_initialized) {
      _receiptFormat = state.settings!.effectiveReceiptPrintFormat;
      _shiftReportFormat = state.settings!.effectiveShiftReportPrintFormat;
      _prescriptionFormat = state.settings!.effectivePrescriptionPrintFormat;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state.actionStatus == RequestStatusEnum.success) {
          CustomToast(
            context: context,
            header: 'print_settings_saved_success'.tr(),
          ).showTopToast();
        } else if (state.actionStatus == RequestStatusEnum.failure) {
          CustomToast(
            context: context,
            header: (state.errMessage ?? 'error').tr(),
            type: ToastificationType.error,
          ).showTopToast();
        }
      },
      builder: (context, state) {
        _syncFromSettings(state);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'print_settings_title'.tr(),
                style: CustomAppFontStyle.bold20.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'print_settings_desc'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
              const SizedBox(height: 24),

              // 1. Payment Receipt Card
              _buildDocumentFormatCard(
                title: 'print_doc_receipt'.tr(),
                desc: 'print_doc_receipt_desc'.tr(),
                icon: Icons.receipt_long_outlined,
                currentFormat: _receiptFormat,
                onChanged: (f) => setState(() => _receiptFormat = f),
              ),
              const SizedBox(height: 16),

              // 2. Shift Report Card
              _buildDocumentFormatCard(
                title: 'print_doc_shift_report'.tr(),
                desc: 'print_doc_shift_report_desc'.tr(),
                icon: Icons.summarize_outlined,
                currentFormat: _shiftReportFormat,
                onChanged: (f) => setState(() => _shiftReportFormat = f),
              ),
              const SizedBox(height: 16),

              // 3. Prescription Card
              _buildDocumentFormatCard(
                title: 'print_doc_prescription'.tr(),
                desc: 'print_doc_prescription_desc'.tr(),
                icon: Icons.medication_outlined,
                currentFormat: _prescriptionFormat,
                onChanged: (f) => setState(() => _prescriptionFormat = f),
              ),
              const SizedBox(height: 28),

              // Save Action Button
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: CustomPushButton(
                  height: 44,
                  backgroundColor: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  isLoading: state.actionStatus == RequestStatusEnum.loading,
                  onTap: () {
                    context.read<SettingsCubit>().updatePrintSettings(
                          receiptPrintFormat: _receiptFormat.name,
                          shiftReportPrintFormat: _shiftReportFormat.name,
                          prescriptionPrintFormat: _prescriptionFormat.name,
                        );
                  },
                  child: Text(
                    'save'.tr(),
                    style: CustomAppFontStyle.semiBold14.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentFormatCard({
    required String title,
    required String desc,
    required IconData icon,
    required PrintFormat currentFormat,
    required ValueChanged<PrintFormat> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CustomAppFontStyle.bold16.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: AppColors.gray71717A,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.grayE2E8F0),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildFormatOption(
                  format: PrintFormat.a4,
                  label: 'print_format_a4'.tr(),
                  desc: 'print_format_a4_desc'.tr(),
                  isSelected: currentFormat == PrintFormat.a4,
                  onSelect: () => onChanged(PrintFormat.a4),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildFormatOption(
                  format: PrintFormat.thermal80,
                  label: 'print_format_thermal80'.tr(),
                  desc: 'print_format_thermal80_desc'.tr(),
                  isSelected: currentFormat == PrintFormat.thermal80,
                  onSelect: () => onChanged(PrintFormat.thermal80),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption({
    required PrintFormat format,
    required String label,
    required String desc,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grayE2E8F0,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.gray71717A,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: CustomAppFontStyle.semiBold14.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: CustomAppFontStyle.regular11.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

