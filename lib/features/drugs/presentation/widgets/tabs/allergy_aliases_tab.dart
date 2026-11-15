import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/theme/app_colors.dart';
import '../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../manager/drugs_cubit.dart';
import '../../manager/drugs_state.dart';
import '../dialogs/edit_aliases_dialog.dart';

class AllergyAliasesTab extends StatelessWidget {
  final DrugsCubit cubit;
  final DrugsState state;

  const AllergyAliasesTab({
    super.key,
    required this.cubit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final allergyItems = state.allergyItems;
    final canManage = cubit.canManageCatalog;

    return ListView.separated(
      itemCount: allergyItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = allergyItems[index];
        final aliases = state.allergyAliasesMap[item.id] ?? item.aliases ?? [];

        return Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name ?? '',
                            style: CustomAppFontStyle.bold16.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.id ?? '',
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (canManage)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      onPressed: () {
                        EditAliasesDialog.show(
                          context: context,
                          cubit: cubit,
                          item: item,
                        );
                      },
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        'drugs_edit_aliases'.tr(),
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Aliases chips
              Text(
                '${'drugs_protected_aliases'.tr()} (${aliases.length}):',
                style: CustomAppFontStyle.semiBold12.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
              const SizedBox(height: 8),

              if (aliases.isEmpty)
                Text(
                  'drugs_no_aliases'.tr(),
                  style: CustomAppFontStyle.regular12.copyWith(
                    color: AppColors.gray,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: aliases.map((alias) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        alias,
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}
