import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/theme/app_colors.dart';
import '../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../../shared/widgets/custom_stack_selector.dart';
import '../../../data/models/drug_model.dart';
import '../../../data/models/enums/review_status_enum.dart';
import '../../manager/drugs_cubit.dart';

class ReviewDrugModal extends StatefulWidget {
  final DrugsCubit cubit;
  final DrugModel drug;

  const ReviewDrugModal({
    super.key,
    required this.cubit,
    required this.drug,
  });

  static Future<bool?> show({
    required BuildContext context,
    required DrugsCubit cubit,
    required DrugModel drug,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ReviewDrugModal(
        cubit: cubit,
        drug: drug,
      ),
    );
  }

  @override
  State<ReviewDrugModal> createState() => _ReviewDrugModalState();
}

class _ReviewDrugModalState extends State<ReviewDrugModal> {
  String? _selectedMergeTargetDrugId;
  late final TextEditingController _mergeTargetController;
  bool _isMerging = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _mergeTargetController = TextEditingController();
  }

  @override
  void dispose() {
    _mergeTargetController.dispose();
    super.dispose();
  }

  Future<void> _submitDecision(ReviewStatusEnum decision) async {
    setState(() => _isSubmitting = true);

    final success = await widget.cubit.reviewQuickAdd(
      drugId: widget.drug.id!,
      decision: decision,
      mergeTargetDrugId: _isMerging ? _selectedMergeTargetDrugId : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final drug = widget.drug;
    final otherDrugs = widget.cubit.state.drugs
        .where((d) => d.id != drug.id && d.reviewStatus == ReviewStatusEnum.approved)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'drugs_review_drug'.tr(),
                    style: CustomAppFontStyle.bold18.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close, color: AppColors.gray),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Drug info card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.pending_actions_rounded,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            drug.name ?? '',
                            style: CustomAppFontStyle.bold15.copyWith(
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (drug.scientificName != null &&
                        drug.scientificName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${'drugs_scientific_name'.tr()}: ${drug.scientificName}',
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: AppColors.gray71717A,
                        ),
                      ),
                    ],
                    if (drug.concentration != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${'drugs_concentration'.tr()}: ${drug.concentration}',
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: AppColors.gray71717A,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Merge toggle
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _isMerging,
                onChanged: (val) {
                  setState(() {
                    _isMerging = val ?? false;
                    if (!_isMerging) _selectedMergeTargetDrugId = null;
                  });
                },
                title: Text(
                  'drugs_review_merge'.tr(),
                  style: CustomAppFontStyle.medium14.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
              ),

              if (_isMerging) ...[
                const SizedBox(height: 8),
                CustomStackSelector<DrugModel>(
                  controller: _mergeTargetController,
                  header: 'drugs_trade_name'.tr(),
                  hintText: 'drugs_trade_name'.tr(),
                  list: otherDrugs,
                  itemAsString: (d) => d.name ?? d.id ?? '',
                  changeValue: (d) {
                    setState(() {
                      _selectedMergeTargetDrugId = d.id;
                      _mergeTargetController.text = d.name ?? d.id ?? '';
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 20),

              // Action Buttons
              if (_isMerging) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'cancel'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: AppColors.gray71717A,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CustomPushButton(
                      height: 38,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      backgroundColor: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(8),
                      isLoading: _isSubmitting,
                      onTap: _selectedMergeTargetDrugId != null
                          ? () => _submitDecision(ReviewStatusEnum.approved)
                          : null,
                      child: Center(
                        child: Text(
                          'drugs_review_merge'.tr(),
                          style: CustomAppFontStyle.bold13.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Reject
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitDecision(ReviewStatusEnum.rejected),
                      child: Text(
                        'drugs_review_reject'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Approve
                    CustomPushButton(
                      height: 38,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      backgroundColor: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(8),
                      isLoading: _isSubmitting,
                      onTap: () => _submitDecision(ReviewStatusEnum.approved),
                      child: Center(
                        child: Text(
                          'drugs_review_approve'.tr(),
                          style: CustomAppFontStyle.bold13.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
