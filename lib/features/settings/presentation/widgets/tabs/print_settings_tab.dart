import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/enums/print_format_enum.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_state.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class PrintSettingsTab extends StatefulWidget {
  final SettingsCubit? settingsCubit;

  const PrintSettingsTab({super.key, this.settingsCubit});

  @override
  State<PrintSettingsTab> createState() => _PrintSettingsTabState();
}

class _PrintSettingsTabState extends State<PrintSettingsTab> {
  PrintFormat _receiptFormat = PrintFormat.a4;
  PrintFormat _shiftReportFormat = PrintFormat.a4;
  PrintFormat _prescriptionFormat = PrintFormat.a4;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final cubit = widget.settingsCubit;
    if (cubit != null && cubit.state.settings != null) {
      _applySettings(cubit.state.settings!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      try {
        final cubit = widget.settingsCubit ?? context.read<SettingsCubit>();
        if (cubit.state.settings != null) {
          _applySettings(cubit.state.settings!);
        }
      } catch (_) {
        // Fallback for isolated widget tests without BlocProvider in ancestry
      }
    }
  }

  void _applySettings(CompanySettingsModel settings) {
    _receiptFormat = settings.effectiveReceiptPrintFormat;
    _shiftReportFormat = settings.effectiveShiftReportPrintFormat;
    _prescriptionFormat = settings.effectivePrescriptionPrintFormat;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      bloc: widget.settingsCubit,
      listenWhen: (prev, curr) =>
          (!_initialized && curr.settings != null) ||
          prev.actionStatus != curr.actionStatus,
      listener: (context, state) {
        if (!_initialized && state.settings != null) {
          setState(() {
            _applySettings(state.settings!);
          });
        }
        if (state.actionStatus == RequestStatusEnum.success) {
          if (state.settings != null) {
            setState(() {
              _applySettings(state.settings!);
            });
          }
          CustomToast(
            context: context,
            header: 'print_settings_saved_success'.tr(),
          ).showTopToast();
        } else if (state.actionStatus == RequestStatusEnum.failure) {
          CustomToast(
            context: context,
            header: (state.errMessage ?? 'error_occurred').tr(),
            type: ToastificationType.error,
          ).showTopToast();
        }
      },
      builder: (context, state) {
        final colors = context.themeColors;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'print_settings_title'.tr(),
                style: CustomAppFontStyle.bold20.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'print_settings_desc'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // 1. Payment Receipt Card
              _buildDocumentFormatCard(
                docKey: 'receipt',
                title: 'print_doc_receipt'.tr(),
                desc: 'print_doc_receipt_desc'.tr(),
                icon: Icons.receipt_long_outlined,
                currentFormat: _receiptFormat,
                onChanged: (f) => setState(() => _receiptFormat = f),
                colors: colors,
              ),
              const SizedBox(height: 16),

              // 2. Shift Report Card
              _buildDocumentFormatCard(
                docKey: 'shift',
                title: 'print_doc_shift_report'.tr(),
                desc: 'print_doc_shift_report_desc'.tr(),
                icon: Icons.summarize_outlined,
                currentFormat: _shiftReportFormat,
                onChanged: (f) => setState(() => _shiftReportFormat = f),
                colors: colors,
              ),
              const SizedBox(height: 16),

              // 3. Prescription Card
              _buildDocumentFormatCard(
                docKey: 'prescription',
                title: 'print_doc_prescription'.tr(),
                desc: 'print_doc_prescription_desc'.tr(),
                icon: Icons.medication_outlined,
                currentFormat: _prescriptionFormat,
                onChanged: (f) => setState(() => _prescriptionFormat = f),
                colors: colors,
              ),
              const SizedBox(height: 28),

              // Save Action Button
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: CustomPushButton(
                  key: const Key('print_settings_save_btn'),
                  height: 44,
                  backgroundColor: colors.primary,
                  borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  isLoading: state.actionStatus == RequestStatusEnum.loading,
                  onTap: () {
                    final cubit =
                        widget.settingsCubit ?? context.read<SettingsCubit>();
                    cubit.updatePrintSettings(
                      receiptPrintFormat: _receiptFormat.name,
                      shiftReportPrintFormat: _shiftReportFormat.name,
                      prescriptionPrintFormat: _prescriptionFormat.name,
                    );
                  },
                  child: Text(
                    'save'.tr(),
                    style: CustomAppFontStyle.semiBold14.copyWith(
                      color: Colors.white,
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
    required String docKey,
    required String title,
    required String desc,
    required IconData icon,
    required PrintFormat currentFormat,
    required ValueChanged<PrintFormat> onChanged,
    required dynamic colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CustomAppFontStyle.bold16.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildFormatOption(
                  key: Key('format_${docKey}_a4'),
                  format: PrintFormat.a4,
                  label: 'print_format_a4'.tr(),
                  desc: 'print_format_a4_desc'.tr(),
                  isSelected: currentFormat == PrintFormat.a4,
                  onSelect: () => onChanged(PrintFormat.a4),
                  colors: colors,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildFormatOption(
                  key: Key('format_${docKey}_thermal80'),
                  format: PrintFormat.thermal80,
                  label: 'print_format_thermal80'.tr(),
                  desc: 'print_format_thermal80_desc'.tr(),
                  isSelected: currentFormat == PrintFormat.thermal80,
                  onSelect: () => onChanged(PrintFormat.thermal80),
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption({
    Key? key,
    required PrintFormat format,
    required String label,
    required String desc,
    required bool isSelected,
    required VoidCallback onSelect,
    required dynamic colors,
  }) {
    return InkWell(
      key: key,
      onTap: onSelect,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryLight
              : colors.surfaceLevel1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colors.primary : colors.borderSubtle,
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
              color: isSelected ? colors.primary : colors.textSecondary,
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
                      color: isSelected ? colors.primary : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: CustomAppFontStyle.regular11.copyWith(
                      color: colors.textSecondary,
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
