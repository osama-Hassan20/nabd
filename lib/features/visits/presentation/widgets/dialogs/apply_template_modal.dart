import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../../core/utils/theme/app_colors.dart';
import '../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../../shared/widgets/custom_toast.dart';
import '../../../../drugs/data/models/drug_model.dart';
import '../../../../drugs/data/models/prescription_template_model.dart';
import '../../../../drugs/domain/use_cases/get_doctor_templates_use_case.dart';
import '../../../../drugs/domain/use_cases/get_drugs_catalog_use_case.dart';
import '../../manager/visits_cubit.dart';

class ApplyTemplateModal extends StatefulWidget {
  final VisitsCubit cubit;
  final String doctorId;

  const ApplyTemplateModal({
    super.key,
    required this.cubit,
    required this.doctorId,
  });

  static Future<void> show({
    required BuildContext context,
    required VisitsCubit cubit,
    required String doctorId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ApplyTemplateModal(
        cubit: cubit,
        doctorId: doctorId,
      ),
    );
  }

  @override
  State<ApplyTemplateModal> createState() => _ApplyTemplateModalState();
}

class _ApplyTemplateModalState extends State<ApplyTemplateModal> {
  List<PrescriptionTemplateModel> _templates = [];
  List<DrugModel> _catalog = [];
  bool _isLoading = true;
  String? _selectedTemplateId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final getTemplates = getIt<GetDoctorTemplatesUseCase>();
      final getCatalog = getIt<GetDrugsCatalogUseCase>();

      final resTemplates = await getTemplates(widget.doctorId);
      final resCatalog = await getCatalog(const GetDrugsParams(includeArchived: true));

      if (mounted) {
        setState(() {
          _templates = resTemplates.getOrElse(() => []);
          _catalog = resCatalog.getOrElse(() => []);
          if (_templates.isNotEmpty) {
            _selectedTemplateId = _templates.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onApply() {
    final selected = _templates
        .where((t) => t.id == _selectedTemplateId)
        .firstOrNull;
    if (selected == null) return;

    final skipped = widget.cubit.applyPrescriptionTemplate(
      selected,
      catalog: _catalog,
    );

    Navigator.of(context).pop();

    if (skipped > 0) {
      CustomToast(
        context: context,
        header: 'rx_template_skipped_archived'.tr(
          namedArgs: {'count': '$skipped'},
        ),
      ).showTopToast();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.bookmark_outline_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'rx_apply_template_btn'.tr(),
                        style: CustomAppFontStyle.bold18.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.gray),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _templates.isEmpty
                        ? Center(
                            child: Text(
                              'template_not_found'.tr(),
                              style: CustomAppFontStyle.medium14.copyWith(
                                color: AppColors.gray,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _templates.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final template = _templates[index];
                              final isSelected =
                                  template.id == _selectedTemplateId;
                              final itemsCount = template.items?.length ?? 0;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedTemplateId = template.id;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.05)
                                        : AppColors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFFE2E8F0),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.gray,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              template.name ?? '',
                                              style: CustomAppFontStyle.bold15
                                                  .copyWith(
                                                color: AppColors.darkText,
                                              ),
                                            ),
                                            if (template.description !=
                                                    null &&
                                                template.description!
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                template.description!,
                                                style: CustomAppFontStyle
                                                    .regular12
                                                    .copyWith(
                                                  color: AppColors.gray71717A,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.grayf2,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$itemsCount ${'items'.tr()}',
                                          style: CustomAppFontStyle.medium12
                                              .copyWith(
                                            color: AppColors.gray,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'cancel'.tr(),
                      style: CustomAppFontStyle.medium14.copyWith(
                        color: AppColors.gray71717A,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CustomPushButton(
                    height: 40,
                    width: 140,
                    backgroundColor: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    onTap: _selectedTemplateId != null ? _onApply : null,
                    child: Center(
                      child: Text(
                        'apply'.tr(),
                        style: CustomAppFontStyle.bold13.copyWith(
                          color: AppColors.white,
                        ),
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
}
