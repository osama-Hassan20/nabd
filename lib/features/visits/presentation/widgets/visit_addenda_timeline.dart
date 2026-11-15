import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../data/models/enums/addendum_change_type_enum.dart';
import '../../data/models/visit_addendum_model.dart';

class VisitAddendaTimeline extends StatelessWidget {
  final List<VisitAddendumModel> addenda;

  const VisitAddendaTimeline({
    super.key,
    required this.addenda,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('yyyy/MM/dd - hh:mm a').format(dt);
  }

  String _getChangeTypeLabel(AddendumChangeTypeEnum? type) {
    switch (type) {
      case AddendumChangeTypeEnum.add:
        return 'addendum_action_add'.tr();
      case AddendumChangeTypeEnum.discontinue:
        return 'addendum_action_remove'.tr();
      case AddendumChangeTypeEnum.dose:
      case AddendumChangeTypeEnum.frequency:
      case AddendumChangeTypeEnum.duration:
      case AddendumChangeTypeEnum.instructions:
        return 'addendum_action_modify'.tr();
      case AddendumChangeTypeEnum.diagnosis:
        return 'visits_diagnosis'.tr();
      case null:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (addenda.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedAddenda = List<VisitAddendumModel>.from(addenda)
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_edu_rounded,
                size: 20,
                color: Color(0xFF0284C7),
              ),
              const SizedBox(width: 8),
              Text(
                'addendum_title'.tr(),
                style: CustomAppFontStyle.bold16.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${addenda.length}',
                  style: CustomAppFontStyle.semiBold12.copyWith(
                    color: const Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedAddenda.length,
            separatorBuilder: (_, _) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final addendum = sortedAddenda[index];
              final isDiagnosis =
                  addendum.changeType == AddendumChangeTypeEnum.diagnosis;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${addendum.id ?? '${index + 1}'}',
                              style: CustomAppFontStyle.semiBold12.copyWith(
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getChangeTypeLabel(addendum.changeType),
                              style: CustomAppFontStyle.medium12.copyWith(
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatDate(addendum.createdAt),
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: AppColors.gray71717A,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Reason
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${'addendum_reason_label'.tr()}: ',
                        style: CustomAppFontStyle.semiBold13.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          addendum.reason ?? '',
                          style: CustomAppFontStyle.regular13.copyWith(
                            color: AppColors.gray71717A,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Before / After details
                  const SizedBox(height: 8),
                  if (isDiagnosis) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (addendum.diagnosisBefore != null)
                            Text(
                              '${'addendum_before_snapshot'.tr()}: ${addendum.diagnosisBefore}',
                              style: CustomAppFontStyle.regular12.copyWith(
                                color: AppColors.gray71717A,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          if (addendum.diagnosisAfter != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${'addendum_after_snapshot'.tr()}: ${addendum.diagnosisAfter}',
                              style: CustomAppFontStyle.semiBold12.copyWith(
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else ...[
                    if (addendum.newItemSnapshot != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: Text(
                          '${addendum.newItemSnapshot?.tradeName ?? ''} - ${addendum.newItemSnapshot?.dosage ?? ''} (${addendum.newItemSnapshot?.frequency ?? ''})',
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
