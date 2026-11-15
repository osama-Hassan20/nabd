import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/theme/app_colors.dart';
import '../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../data/models/drug_import_preview_model.dart';
import '../../../domain/helpers/drug_csv_import_engine.dart';
import '../../manager/drugs_cubit.dart';

class ImportDrugsDialog extends StatefulWidget {
  final DrugsCubit cubit;

  const ImportDrugsDialog({
    super.key,
    required this.cubit,
  });

  static Future<bool?> show({
    required BuildContext context,
    required DrugsCubit cubit,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ImportDrugsDialog(cubit: cubit),
    );
  }

  @override
  State<ImportDrugsDialog> createState() => _ImportDrugsDialogState();
}

class _ImportDrugsDialogState extends State<ImportDrugsDialog> {
  late final TextEditingController _contentController;
  DrugImportPreviewModel? _preview;
  String? _parseError;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged(String text) {
    if (text.trim().isEmpty) {
      setState(() {
        _preview = null;
        _parseError = null;
      });
      return;
    }

    final res = DrugCsvImportEngine.parseCsvString(
      text,
      existingDrugs: widget.cubit.state.drugs,
    );

    res.fold(
      (failure) {
        setState(() {
          _parseError = failure.errMessage;
          _preview = null;
        });
      },
      (preview) {
        setState(() {
          _preview = preview;
          _parseError = null;
        });
      },
    );
  }

  Future<void> _onImport() async {
    final preview = _preview;
    if (preview == null || preview.validCount == 0) return;

    setState(() => _isImporting = true);

    final skippedCount = preview.invalidCount + preview.duplicateCount;
    final success = await widget.cubit.importDrugs(
      drugsToImport: preview.validRows ?? [],
      skippedCount: skippedCount,
    );

    if (mounted) {
      setState(() => _isImporting = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.file_upload_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'drugs_import_title'.tr(),
                        style: CustomAppFontStyle.bold18.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.gray),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ─── Content Input Area ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextFormField(
                        headerText: 'drugs_import_paste_title'.tr(),
                        hintText: 'drugs_import_paste_hint'.tr(),
                        controller: _contentController,
                        maxLine: 6,
                        minLine: 4,
                        onChanged: (val) => _onContentChanged(val ?? ''),
                      ),

                      if (_parseError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFDC2626),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _parseError!.tr(),
                                  style: CustomAppFontStyle.medium12.copyWith(
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ─── Preview Cards ──────────────────────────────────────
                      if (preview != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'drugs_import_preview'.tr(),
                          style: CustomAppFontStyle.bold14.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricBadge(
                                label: 'drugs_import_valid_rows'.tr(),
                                count: preview.validCount,
                                color: const Color(0xFF10B981),
                                bg: const Color(0xFFECFDF5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricBadge(
                                label: 'drugs_import_invalid_rows'.tr(),
                                count: preview.invalidCount,
                                color: const Color(0xFFEF4444),
                                bg: const Color(0xFFFEF2F2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricBadge(
                                label: 'drugs_import_duplicate_rows'.tr(),
                                count: preview.duplicateCount,
                                color: const Color(0xFFF59E0B),
                                bg: const Color(0xFFFFFBEB),
                              ),
                            ),
                          ],
                        ),

                        // First 5 preview rows
                        if (preview.previewRows != null &&
                            preview.previewRows!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: preview.previewRows!.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final drug = preview.previewRows![idx];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    drug.name ?? '',
                                    style: CustomAppFontStyle.medium13.copyWith(
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                  subtitle: drug.scientificName != null
                                      ? Text(
                                          drug.scientificName!,
                                          style: CustomAppFontStyle.regular11.copyWith(
                                            color: AppColors.gray,
                                          ),
                                        )
                                      : null,
                                  trailing: drug.concentration != null
                                      ? Text(
                                          drug.concentration!,
                                          style: CustomAppFontStyle.regular11.copyWith(
                                            color: AppColors.gray71717A,
                                          ),
                                        )
                                      : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ─── Actions ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomPushButton(
                    border: const BorderSide(color: Color(0xFFCBD5E1)),
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: AppColors.white,
                    onTap: () => Navigator.of(context).pop(false),
                    child: Text(
                      'cancel'.tr(),
                      style: CustomAppFontStyle.medium14.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CustomPushButton(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: (preview != null && preview.validCount > 0)
                        ? AppColors.primary
                        : AppColors.gray,
                    isLoading: _isImporting,
                    onTap: (preview != null && preview.validCount > 0 && !_isImporting)
                        ? _onImport
                        : null,
                    child: Text(
                      'drugs_import_confirm_valid_only'.tr(),
                      style: CustomAppFontStyle.bold14.copyWith(
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
  }

  Widget _buildMetricBadge({
    required String label,
    required int count,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: CustomAppFontStyle.bold18.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: CustomAppFontStyle.regular11.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
