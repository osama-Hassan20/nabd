import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/theme/app_colors.dart';
import '../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../data/models/enums/review_status_enum.dart';
import '../../manager/drugs_cubit.dart';
import '../../manager/drugs_state.dart';
import '../dialogs/add_drug_dialog.dart';
import '../dialogs/review_drug_modal.dart';

class DrugsCatalogTab extends StatelessWidget {
  final DrugsCubit cubit;
  final DrugsState state;

  const DrugsCatalogTab({
    super.key,
    required this.cubit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final filteredDrugs = state.filteredDrugs;
    final categories = state.categories;
    final canManage = cubit.canManageCatalog;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Search & Filters Bar ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      hintText: 'drugs_search_hint'.tr(),
                      prefixWidget: const Icon(Icons.search, color: AppColors.gray),
                      onChanged: (val) => cubit.setSearchQuery(val ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter row: Categories only (All + Categories + Add Category Button)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // All categories chip
                    _buildFilterChip(
                      label: 'drugs_filter_all_categories'.tr(),
                      isSelected: state.selectedCategoryId == null,
                      onTap: () => cubit.setSelectedCategory(null),
                    ),
                    const SizedBox(width: 8),

                    // Category chips
                    ...categories.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildFilterChip(
                          label: c.nameAr ?? c.nameEn ?? c.id ?? '',
                          isSelected: state.selectedCategoryId == c.id,
                          onTap: () => cubit.setSelectedCategory(c.id),
                        ),
                      );
                    }),

                    // Add new category button at the end
                    _buildAddCategoryChip(context, cubit),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Drugs Table ───────────────────────────────────────────────────
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: filteredDrugs.isEmpty
                ? Center(
                    child: Text(
                      'drugs_not_found'.tr(),
                      style: CustomAppFontStyle.medium14.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredDrugs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final drug = filteredDrugs[index];
                      final isPending =
                          drug.reviewStatus == ReviewStatusEnum.pending;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        title: Row(
                          children: [
                            Text(
                              drug.name ?? '',
                              style: CustomAppFontStyle.bold15.copyWith(
                                color: AppColors.darkText,
                              ),
                            ),
                            if (drug.concentration != null &&
                                drug.concentration!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  drug.concentration!,
                                  style: CustomAppFontStyle.regular12.copyWith(
                                    color: AppColors.gray71717A,
                                  ),
                                ),
                              ),
                            ],
                            if (isPending) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFFCD34D),
                                  ),
                                ),
                                child: Text(
                                  'drugs_quick_added_badge'.tr(),
                                  style: CustomAppFontStyle.bold11.copyWith(
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (drug.scientificName != null &&
                                drug.scientificName!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${'drugs_scientific_name'.tr()}: ${drug.scientificName}',
                                style: CustomAppFontStyle.regular12.copyWith(
                                  color: AppColors.gray71717A,
                                ),
                              ),
                            ],
                            if (drug.defaultDosage != null ||
                                drug.defaultFrequency != null ||
                                drug.defaultDuration != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${drug.defaultDosage ?? ''} • ${drug.defaultFrequency ?? ''} • ${drug.defaultDuration ?? ''}',
                                style: CustomAppFontStyle.regular11.copyWith(
                                  color: AppColors.gray,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Review button for pending
                            if (isPending && canManage) ...[
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                                onPressed: () {
                                  ReviewDrugModal.show(
                                    context: context,
                                    cubit: cubit,
                                    drug: drug,
                                  );
                                },
                                icon: const Icon(
                                  Icons.rate_review_outlined,
                                  size: 16,
                                  color: Color(0xFFD97706),
                                ),
                                label: Text(
                                  'drugs_review_drug'.tr(),
                                  style: CustomAppFontStyle.bold12.copyWith(
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            // Edit action
                            if (canManage) ...[
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                tooltip: 'drugs_edit_drug'.tr(),
                                onPressed: () {
                                  AddDrugDialog.show(
                                    context: context,
                                    cubit: cubit,
                                    initialDrug: drug,
                                  );
                                },
                              ),

                              // Archive action
                              IconButton(
                                icon: const Icon(
                                  Icons.archive_outlined,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                tooltip: 'drugs_archive_drug'.tr(),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text('drugs_archive_drug'.tr()),
                                      content: Text('drugs_archive_confirm'.tr()),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: Text('cancel'.tr()),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.error,
                                          ),
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: Text('drugs_archive_drug'.tr()),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true && drug.id != null) {
                                    cubit.archiveDrug(drug.id!);
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: CustomAppFontStyle.semiBold12.copyWith(
                color: isSelected ? AppColors.white : AppColors.darkText,
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.white : const Color(0xFFFCD34D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: CustomAppFontStyle.bold11.copyWith(
                    color: isSelected ? AppColors.primary : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryChip(BuildContext context, DrugsCubit cubit) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showAddCategoryDialog(context, cubit),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'إضافة تصنيف',
              style: CustomAppFontStyle.semiBold12.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, DrugsCubit cubit) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'إضافة تصنيف دوائي جديد',
          style: CustomAppFontStyle.bold16.copyWith(color: AppColors.darkText),
        ),
        content: SizedBox(
          width: 380,
          child: CustomTextFormField(
            controller: controller,
            headerText: 'اسم التصنيف',
            hintText: 'مثال: أدوية العيون، أدوية الجلدية...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('cancel'.tr(),
                style: const TextStyle(color: AppColors.gray71717A)),
          ),
          CustomPushButton(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            backgroundColor: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                cubit.addCategory(text);
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text(
              'إضافة',
              style: CustomAppFontStyle.bold13.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
