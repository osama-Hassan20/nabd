import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../data/models/role_definition_model.dart';

class StaffRoleBadge extends StatelessWidget {
  final String roleId;
  final List<RoleDefinitionModel> roles;
  final bool isOwner;

  const StaffRoleBadge({
    super.key,
    required this.roleId,
    this.roles = const [],
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_rounded,
                size: 13, color: Color(0xFFD97706)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'clinic_owner'.tr(),
                style: CustomAppFontStyle.medium12.copyWith(
                  color: const Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final role = roles.firstWhere(
      (r) => r.id == roleId,
      orElse: () => RoleDefinitionModel(id: roleId, nameAr: roleId),
    );

    final (bg, border, text, dot) = _getColorsForRole(roleId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              role.nameAr ?? roleId,
              style: CustomAppFontStyle.medium12.copyWith(
                color: text,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color, Color) _getColorsForRole(String id) {
    switch (id) {
      case RoleIds.branchManager:
        return (
          const Color(0xFFFFFBEB),
          const Color(0xFFFDE68A),
          const Color(0xFFB45309),
          const Color(0xFFF59E0B),
        );
      case RoleIds.medicalDirector:
        return (
          const Color(0xFFFAF5FF),
          const Color(0xFFE9D5FF),
          const Color(0xFF7E22CE),
          const Color(0xFFA855F7),
        );
      case RoleIds.doctor:
        return (
          const Color(0xFFEFF6FF),
          const Color(0xFFBFDBFE),
          const Color(0xFF1D4ED8),
          const Color(0xFF3B82F6),
        );
      case RoleIds.nurse:
        return (
          const Color(0xFFF0FDFA),
          const Color(0xFF99F6E4),
          const Color(0xFF0F766E),
          const Color(0xFF14B8A6),
        );
      case RoleIds.reception:
        return (
          const Color(0xFFEEF2FF),
          const Color(0xFFC7D2FE),
          const Color(0xFF4338CA),
          const Color(0xFF6366F1),
        );
      case RoleIds.accountant:
        return (
          const Color(0xFFFFF1F2),
          const Color(0xFFFECDD3),
          const Color(0xFFBE123C),
          const Color(0xFFF43F5E),
        );
      case RoleIds.hr:
        return (
          const Color(0xFFECFDF5),
          const Color(0xFFA7F3D0),
          const Color(0xFF047857),
          const Color(0xFF10B981),
        );
      default:
        return (
          const Color(0xFFF3F4F6),
          const Color(0xFFE5E7EB),
          const Color(0xFF374151),
          const Color(0xFF6B7280),
        );
    }
  }
}
