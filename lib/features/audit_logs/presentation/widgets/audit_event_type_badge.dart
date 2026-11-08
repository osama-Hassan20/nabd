import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';

class AuditEventTypeBadge extends StatelessWidget {
  final String? eventType;

  const AuditEventTypeBadge({
    super.key,
    required this.eventType,
  });

  @override
  Widget build(BuildContext context) {
    final type = eventType ?? 'unknown';

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String labelKey;

    switch (type) {
      case 'login_success':
        bgColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFFA7F3D0);
        textColor = const Color(0xFF047857);
        icon = Icons.login_rounded;
        labelKey = 'audit_event_login_success';
        break;
      case 'login_failure':
        bgColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFFECACA);
        textColor = const Color(0xFFB91C1C);
        icon = Icons.gpp_bad_rounded;
        labelKey = 'audit_event_login_failure';
        break;
      case 'logout':
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFCBD5E1);
        textColor = const Color(0xFF475569);
        icon = Icons.logout_rounded;
        labelKey = 'audit_event_logout';
        break;
      case 'create_user':
      case 'update_user':
      case 'toggle_user_status':
      case 'delete_user':
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        textColor = const Color(0xFFB45309);
        icon = Icons.person_outline_rounded;
        labelKey = 'audit_event_$type';
        break;
      case 'update_role_permissions':
      case 'change_password':
      case 'reset_password':
        bgColor = const Color(0xFFFAF5FF);
        borderColor = const Color(0xFFE9D5FF);
        textColor = const Color(0xFF7E22CE);
        icon = Icons.security_rounded;
        labelKey = 'audit_event_$type';
        break;
      case 'create_branch':
      case 'update_branch':
      case 'toggle_branch_status':
      case 'set_main_branch':
      case 'copy_branch_settings':
        bgColor = const Color(0xFFEEF2FF);
        borderColor = const Color(0xFFC7D2FE);
        textColor = const Color(0xFF4338CA);
        icon = Icons.storefront_outlined;
        labelKey = 'audit_event_$type';
        break;
      case 'view_patient_profile':
        bgColor = const Color(0xFFECFEFF);
        borderColor = const Color(0xFFA5F3FC);
        textColor = const Color(0xFF0E7490);
        icon = Icons.visibility_outlined;
        labelKey = 'audit_event_view_patient_profile';
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFCBD5E1);
        textColor = const Color(0xFF475569);
        icon = Icons.info_outline_rounded;
        labelKey = type;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              labelKey.tr(),
              style: CustomAppFontStyle.semiBold12.copyWith(
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

