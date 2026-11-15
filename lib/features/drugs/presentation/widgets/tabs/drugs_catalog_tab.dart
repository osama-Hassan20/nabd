import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/theme/app_colors.dart';
import '../../../../../core/utils/theme/custom_app_font_styles.dart';
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

              // Filter row: Review status & Categories
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Status filters
                    _buildFilterChip(
                      label: 'drugs_filter_all'.tr(),
                      isSelected: state.reviewFilter == 'all',
                      onTap: () => cubit.setReviewFilter('all'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'drugs_filter_pending'.tr(),
                      isSelected: state.reviewFilter == 'pending',
                      badgeCount: state.drugs
                          .where((d) => d.reviewStatus == ReviewStatusEnum.pending)
                          .length,
                      onTap: () => cubit.setReviewFilter('pending'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'drugs_filter_approved'.tr(),
                      isSelected: state.reviewFilter == 'approved',
                      onTap: () => cubit.setReviewFilter('approved'),
                    ),

                    if (categories.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Container(
                        height: 24,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 16),

                      // Category chips
                      _buildFilterChip(
                        label: 'drugs_filter_all_categories'.tr(),
                        isSelected: state.selectedCategoryId == null,
                        onTap: () => cubit.setSelectedCategory(null),
                      ),
                      const SizedBox(width: 8),
                      ...categories.map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            label: c.nameAr ?? c.nameEn ?? c.id ?? '',
                            isSelected: state.selectedCategoryId == c.id,
                            onTap: () => cubit.setSelectedCategory(c.id),
                          ),
                        );
                      }),
                    ],
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
}
