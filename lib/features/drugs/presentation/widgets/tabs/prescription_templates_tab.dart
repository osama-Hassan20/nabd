import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/theme/app_colors.dart';
import '../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../manager/drugs_cubit.dart';
import '../../manager/drugs_state.dart';

class PrescriptionTemplatesTab extends StatelessWidget {
  final DrugsCubit cubit;
  final DrugsState state;

  const PrescriptionTemplatesTab({
    super.key,
    required this.cubit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final templates = state.templates;

    if (templates.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bookmark_border_rounded,
                size: 48,
                color: AppColors.gray,
              ),
              const SizedBox(height: 12),
              Text(
                'template_not_found'.tr(),
                style: CustomAppFontStyle.semiBold16.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: templates.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final template = templates[index];
        final items = template.items ?? [];

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
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bookmark_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name ?? '',
                            style: CustomAppFontStyle.bold16.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                          if (template.description != null &&
                              template.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              template.description!,
                              style: CustomAppFontStyle.regular12.copyWith(
                                color: AppColors.gray71717A,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.error,
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('drugs_delete_template_title'.tr()),
                          content:
                              Text('drugs_delete_template_confirm'.tr()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text('cancel'.tr()),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text('drugs_action_delete'.tr()),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && template.id != null) {
                        cubit.deleteTemplate(template.id!);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Items chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      '${item.drugName ?? ''} - ${item.dosage ?? ''} (${item.frequency ?? ''})',
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
