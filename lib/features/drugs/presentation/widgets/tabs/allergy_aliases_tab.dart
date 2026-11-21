import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/extensions/theme_mode_extensions.dart';
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
    final colors = context.themeColors;
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
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
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
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.id ?? '',
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: colors.textSecondary,
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
                        side: BorderSide(color: colors.borderSubtle),
                      ),
                      onPressed: () {
                        EditAliasesDialog.show(
                          context: context,
                          cubit: cubit,
                          item: item,
                        );
                      },
                      icon: Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                      label: Text(
                        'drugs_edit_aliases'.tr(),
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: colors.borderSubtle),
              const SizedBox(height: 12),

              // Aliases chips
              Text(
                '${'drugs_protected_aliases'.tr()} (${aliases.length}):',
                style: CustomAppFontStyle.semiBold12.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              if (aliases.isEmpty)
                Text(
                  'drugs_no_aliases'.tr(),
                  style: CustomAppFontStyle.regular12.copyWith(
                    color: colors.textSecondary,
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
                        color: colors.surfaceLevel1,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Text(
                        alias,
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: colors.textPrimary,
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
