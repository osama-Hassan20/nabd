import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/custom_push_container_button.dart';
import '../../data/models/visit_model.dart';
import '../helpers/effective_prescription_calculator.dart';
import '../manager/visits_cubit.dart';
import 'dialogs/apply_template_modal.dart';
import 'dialogs/drug_quick_add_modal.dart';
import 'prescription_item_row.dart';

class PrescriptionEditorPanel extends StatefulWidget {
  final VisitsCubit cubit;
  final VisitModel visit;
  final bool isReadOnly;
  final VoidCallback? onPrint;

  const PrescriptionEditorPanel({
    super.key,
    required this.cubit,
    required this.visit,
    this.isReadOnly = false,
    this.onPrint,
  });

  @override
  State<PrescriptionEditorPanel> createState() =>
      _PrescriptionEditorPanelState();
}

class _PrescriptionEditorPanelState extends State<PrescriptionEditorPanel> {
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    // If visit is finalized, calculate effective prescription (with addenda)
    final isFinalized = widget.visit.status?.name == 'finalized';
    final items = isFinalized
        ? EffectivePrescriptionCalculator.calculateEffectivePrescription(
            visit: widget.visit,
          )
        : (widget.cubit.state.formState.prescriptionItems ?? const []);

    final editingItem = widget.cubit.state.formState.editingItem;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Action Buttons
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.medication_outlined,
                    size: 22,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'rx_prescription_title'.tr(),
                    style: CustomAppFontStyle.bold16.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grayf2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${items.length}',
                      style: CustomAppFontStyle.semiBold12.copyWith(
                        color: AppColors.gray71717A,
                      ),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!widget.isReadOnly) ...[
                    // Add Drug Button
                    CustomPushButton(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      backgroundColor: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _isAdding = true;
                          widget.cubit.clearEditingPrescriptionItem();
                        });
                      },
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 16, color: AppColors.white),
                            const SizedBox(width: 4),
                            Text(
                              'rx_add_drug_btn'.tr(),
                              style: CustomAppFontStyle.semiBold12.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Apply Template Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      onPressed: () {
                        ApplyTemplateModal.show(
                          context: context,
                          cubit: widget.cubit,
                          doctorId: widget.visit.doctorId ?? '',
                        );
                      },
                      icon: const Icon(
                        Icons.bookmark_outline_rounded,
                        size: 16,
                        color: AppColors.darkText,
                      ),
                      label: Text(
                        'rx_apply_template_btn'.tr(),
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ),

                    // Quick Add Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: const BorderSide(color: Color(0xFFF59E0B)),
                      ),
                      onPressed: () {
                        DrugQuickAddModal.show(
                          context: context,
                          cubit: widget.cubit,
                          visitId: widget.visit.id ?? '',
                          doctorId: widget.visit.doctorId ?? '',
                        );
                      },
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      label: Text(
                        'rx_quick_add_btn'.tr(),
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],

                  // Print Rx Button
                  if (widget.onPrint != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                      ),
                      onPressed: widget.onPrint,
                      icon: const Icon(
                        Icons.print_outlined,
                        size: 16,
                        color: Color(0xFF0284C7),
                      ),
                      label: Text(
                        'rx_print_btn'.tr(),
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Inline Adding Row
          if (_isAdding) ...[
            PrescriptionItemRow(
              cubit: widget.cubit,
              visitId: widget.visit.id ?? '',
              patientId: widget.visit.patientId,
              branchId: widget.visit.branchId,
              onCancel: () {
                setState(() => _isAdding = false);
              },
            ),
            const SizedBox(height: 16),
          ],

          // Inline Editing Row
          if (editingItem != null && !_isAdding) ...[
            PrescriptionItemRow(
              cubit: widget.cubit,
              visitId: widget.visit.id ?? '',
              patientId: widget.visit.patientId,
              branchId: widget.visit.branchId,
              initialItem: editingItem,
              onCancel: () {
                widget.cubit.clearEditingPrescriptionItem();
              },
            ),
            const SizedBox(height: 16),
          ],

          // Medications List / Table
          if (items.isEmpty && !_isAdding)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.medication_outlined,
                    size: 32,
                    color: AppColors.gray,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'rx_no_items'.tr(),
                    style: CustomAppFontStyle.medium14.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ],
              ),
            )
          else if (items.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final isBeingEdited = editingItem?.id == item.id;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isBeingEdited
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isBeingEdited
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: CustomAppFontStyle.semiBold12.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.tradeName ?? '',
                              style: CustomAppFontStyle.bold14.copyWith(
                                color: AppColors.darkText,
                              ),
                            ),
                            if (item.scientificName != null &&
                                item.scientificName!.isNotEmpty)
                              Text(
                                item.scientificName!,
                                style: CustomAppFontStyle.regular12.copyWith(
                                  color: AppColors.gray71717A,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.dosage ?? '',
                          style: CustomAppFontStyle.medium13.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.frequency ?? '',
                          style: CustomAppFontStyle.medium13.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.duration ?? '',
                          style: CustomAppFontStyle.medium13.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      if (item.instructions != null &&
                          item.instructions!.isNotEmpty)
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.instructions!,
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: AppColors.gray71717A,
                            ),
                          ),
                        ),
                      if (!widget.isReadOnly) ...[
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _isAdding = false;
                              widget.cubit.setEditingPrescriptionItem(item);
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.error,
                          ),
                          onPressed: () {
                            if (item.id != null) {
                              widget.cubit.removePrescriptionItem(item.id!);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
