import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/services/audit_logger.dart';
import '../../../../../core/utils/theme/app_colors.dart';
import '../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../drugs/data/models/drug_model.dart';
import '../../../../drugs/domain/helpers/drug_allergy_matcher.dart';

class AllergyWarningDialog extends StatelessWidget {
  final DrugModel drug;
  final AllergyMatchResult matchResult;
  final String visitId;
  final String? patientId;
  final String? branchId;
  final String? performedByUserId;
  final AuditLogger? auditLogger;

  const AllergyWarningDialog({
    super.key,
    required this.drug,
    required this.matchResult,
    required this.visitId,
    this.patientId,
    this.branchId,
    this.performedByUserId,
    this.auditLogger,
  });

  static Future<bool?> show({
    required BuildContext context,
    required DrugModel drug,
    required AllergyMatchResult matchResult,
    required String visitId,
    String? patientId,
    String? branchId,
    String? performedByUserId,
    AuditLogger? auditLogger,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AllergyWarningDialog(
        drug: drug,
        matchResult: matchResult,
        visitId: visitId,
        patientId: patientId,
        branchId: branchId,
        performedByUserId: performedByUserId,
        auditLogger: auditLogger,
      ),
    );
  }

  void _onProceed(BuildContext context) {
    // Log strictly formatted security audit event (identifiers & enums only, zero clinical text)
    if (auditLogger != null) {
      auditLogger!.log(
        eventType: 'rx_allergy_warning_acknowledged',
        performedByUserId: performedByUserId,
        branchId: branchId,
        details: jsonEncode({
          'visitId': visitId,
          'patientId': patientId,
          'drugId': drug.id,
          'allergyCatalogItemId': matchResult.catalogItemId,
          'matchSource': matchResult.matchSource ?? 'free_text',
        }),
      );
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
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
              // Header with warning icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFE11D48),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'rx_allergy_warning_title'.tr(),
                          style: CustomAppFontStyle.bold16.copyWith(
                            color: const Color(0xFF9F1239),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          drug.name ?? '',
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Allergy conflict explanation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Text(
                  'rx_allergy_warning_msg'.tr(namedArgs: {
                    'allergy': matchResult.matchedAllergy ?? '',
                  }),
                  style: CustomAppFontStyle.medium13.copyWith(
                    color: const Color(0xFF881337),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Clinical Disclaimer
              Text(
                'rx_allergy_disclaimer'.tr(),
                style: CustomAppFontStyle.regular12.copyWith(
                  color: AppColors.gray71717A,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
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
                  const SizedBox(width: 12),
                  CustomPushButton(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    backgroundColor: const Color(0xFFE11D48),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _onProceed(context),
                    child: Center(
                      child: Text(
                        'rx_allergy_proceed_btn'.tr(),
                        style: CustomAppFontStyle.bold13.copyWith(
                          color: AppColors.white,
                        ),
                        textAlign: TextAlign.center,
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
