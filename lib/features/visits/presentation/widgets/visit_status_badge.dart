import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../data/models/enums/visit_status_enum.dart';

class VisitStatusBadge extends StatelessWidget {
  final VisitStatusEnum? status;

  const VisitStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final (
      Color bgColor,
      IconData icon,
      Color textColor,
      Color borderColor,
      String fullLabel,
    ) = switch (status) {
      VisitStatusEnum.triage => (
          const Color(0xFFFFFBEB),
          Icons.monitor_heart_outlined,
          const Color(0xFFB45309),
          const Color(0xFFFDE68A),
          'visits_status_triage'.tr(),
        ),
      VisitStatusEnum.inProgress => (
          const Color(0xFFEFF6FF),
          Icons.medical_services_outlined,
          const Color(0xFF1D4ED8),
          const Color(0xFFBFDBFE),
          'visits_status_in_progress'.tr(),
        ),
      VisitStatusEnum.finalized => (
          const Color(0xFFECFDF5),
          Icons.check_circle_outline,
          const Color(0xFF047857),
          const Color(0xFFA7F3D0),
          'visits_status_finalized'.tr(),
        ),
      null => (
          const Color(0xFFF1F5F9),
          Icons.schedule_outlined,
          const Color(0xFF475569),
          const Color(0xFFCBD5E1),
          'waiting'.tr(),
        ),
    };

    return Tooltip(
      message: fullLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: borderColor,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
            Text(
              fullLabel,
              style: CustomAppFontStyle.medium12.copyWith(color: textColor),
              maxLines: 1,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}
