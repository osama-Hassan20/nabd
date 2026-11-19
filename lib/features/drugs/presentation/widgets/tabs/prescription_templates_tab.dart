import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/theme/app_colors.dart';
import '../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../data/models/prescription_template_model.dart';
import '../../manager/drugs_cubit.dart';
import '../../manager/drugs_state.dart';
import '../dialogs/add_edit_prescription_template_dialog.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Top Action Bar ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grayE2E8F0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bookmarks_outlined,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'الوصفات الطبية المحفوظة (${templates.length})',
                    style: CustomAppFontStyle.bold14.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• نماذج جاهزة لتسريع كتابة الروشتة',
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ],
              ),
              CustomPushButton(
                height: 38,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                backgroundColor: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  AddEditPrescriptionTemplateDialog.show(
                    context: context,
                    cubit: cubit,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'إضافة وصفة جاهزة',
                      style: CustomAppFontStyle.bold13.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Templates List or Empty State ────────────────────────────────
        Expanded(
          child: templates.isEmpty
              ? Center(
                  child: Container(
                    width: 440,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grayE2E8F0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bookmark_add_outlined,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد وصفات طبية جاهزة بعد',
                          style: CustomAppFontStyle.bold16.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'قم بإنشاء بروتوكول علاجي جاهز (مثل: علاج مغص معوي، نزلة برد) لإضافته بنقرة واحدة في الروشتة.',
                          style: CustomAppFontStyle.regular13.copyWith(
                            color: AppColors.gray71717A,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        CustomPushButton(
                          height: 40,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          backgroundColor: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            AddEditPrescriptionTemplateDialog.show(
                              context: context,
                              cubit: cubit,
                            );
                          },
                          child: Text(
                            'إنشاء أول وصفة جاهزة الآن',
                            style: CustomAppFontStyle.bold13.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: templates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    final items = template.items ?? [];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.grayE2E8F0),
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
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.bookmark_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        template.name ?? '',
                                        style:
                                            CustomAppFontStyle.bold15.copyWith(
                                          color: AppColors.darkText,
                                        ),
                                      ),
                                      if (template.description != null &&
                                          template.description!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          template.description!,
                                          style: CustomAppFontStyle.regular12
                                              .copyWith(
                                            color: AppColors.gray71717A,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Edit template
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18, color: AppColors.primary),
                                    tooltip: 'تعديل الوصفة',
                                    onPressed: () {
                                      AddEditPrescriptionTemplateDialog.show(
                                        context: context,
                                        cubit: cubit,
                                        template: template,
                                      );
                                    },
                                  ),
                                  // Delete template
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                    tooltip: 'حذف',
                                    onPressed: () =>
                                        _confirmDelete(context, template),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppColors.grayF1F5F9),
                          const SizedBox(height: 12),

                          // Drugs Included Tags
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
                                  color: AppColors.grayF8FAFC,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: AppColors.grayE2E8F0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.medication_outlined,
                                        size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      item.drugName ?? '',
                                      style:
                                          CustomAppFontStyle.semiBold12.copyWith(
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${item.dosage ?? ''} (${item.frequency ?? ''})'
                                      '${item.instructions != null ? ' - ${item.instructions}' : ''}',
                                      style:
                                          CustomAppFontStyle.regular11.copyWith(
                                        color: AppColors.gray71717A,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, PrescriptionTemplateModel template) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'حذف الوصفة الجاهزة',
          style: CustomAppFontStyle.bold16.copyWith(color: AppColors.error),
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف «${template.name}»؟ لن يتم التأثير على الروشتات السابقة للمرضى.',
          style: CustomAppFontStyle.regular14.copyWith(color: AppColors.darkText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr(),
                style: const TextStyle(color: AppColors.gray71717A)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (template.id != null) {
                cubit.deleteTemplate(template.id!);
              }
            },
            child: Text('delete'.tr(),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
