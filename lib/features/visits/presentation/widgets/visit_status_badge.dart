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
    final (Color bgColor, Color dotColor, Color textColor, Color borderColor, String label) =
        switch (status) {
      VisitStatusEnum.triage => (
          const Color(0xFFFFFBEB), // Amber 50
          const Color(0xFFF59E0B), // Amber 500
          const Color(0xFFB45309), // Amber 700
          const Color(0xFFFDE68A), // Amber 200
          'visits_status_triage'.tr(),
        ),
      VisitStatusEnum.inProgress => (
          const Color(0xFFEFF6FF), // Blue 50
          const Color(0xFF3B82F6), // Blue 500
          const Color(0xFF1D4ED8), // Blue 700
          const Color(0xFFBFDBFE), // Blue 200
          'visits_status_in_progress'.tr(),
        ),
      VisitStatusEnum.finalized => (
          const Color(0xFFECFDF5), // Emerald 50
          const Color(0xFF10B981), // Emerald 500
          const Color(0xFF047857), // Emerald 700
          const Color(0xFFA7F3D0), // Emerald 200
          'visits_status_finalized'.tr(),
        ),
      null => (
          const Color(0xFFF1F5F9), // Slate 100
          const Color(0xFF94A3B8), // Slate 400
          const Color(0xFF475569), // Slate 600
          const Color(0xFFCBD5E1), // Slate 300
          'waiting'.tr(),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: CustomAppFontStyle.medium12.copyWith(color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

