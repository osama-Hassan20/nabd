import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/audit_logs/presentation/widgets/audit_event_type_badge.dart';
import 'package:eyadty/features/users_management/data/models/security_audit_log_model.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

class AuditLogDetailsDialog extends StatelessWidget {
  final SecurityAuditLogModel log;

  const AuditLogDetailsDialog({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a', 'ar');
    final formattedDate = log.timestamp != null
        ? dateFormat.format(log.timestamp!)
        : '-';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: colors.isDark ? 0.35 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'audit_log_details_title'.tr(),
                          style: CustomAppFontStyle.bold16.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          log.id ?? '',
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.borderSubtle),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Event Badge & Time
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AuditEventTypeBadge(eventType: log.eventType),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formattedDate,
                              style: CustomAppFontStyle.medium12.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Grid Info
                    _buildInfoTile(
                      context: context,
                      label: 'table_actor'.tr(),
                      value: log.performedByUserName ?? log.performedByUserId ?? 'النظام الآلي',
                      subtitle: log.performedByUserId != null ? 'ID: ${log.performedByUserId}' : null,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),

                    if (log.targetUserName != null || log.targetUserId != null) ...[
                      _buildInfoTile(
                        context: context,
                        label: 'table_target'.tr(),
                        value: log.targetUserName ?? log.targetUserId ?? '-',
                        subtitle: log.targetUserId != null ? 'ID: ${log.targetUserId}' : null,
                        icon: Icons.person_pin_outlined,
                      ),
                      const SizedBox(height: 12),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            context: context,
                            label: 'table_branch'.tr(),
                            value: log.branchName ?? log.branchId ?? 'المنشأة العامة',
                            icon: Icons.storefront_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoTile(
                            context: context,
                            label: 'table_ip'.tr(),
                            value: log.ipAddress ?? '-',
                            icon: Icons.lan_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Details box
                    Text(
                      'table_details'.tr(),
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfaceLevel1,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: SelectableText(
                        log.details ?? '-',
                        style: CustomAppFontStyle.regular13.copyWith(
                          color: colors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: colors.borderSubtle),

            // Footer
            Padding(
              padding: const EdgeInsets.all(14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CustomPushButton(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  backgroundColor: colors.surfaceLevel1,
                  boxBorder: Border.all(color: colors.borderSubtle),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).pop(),
                  child: Center(
                    child: Text(
                      'cancel'.tr(),
                      style: CustomAppFontStyle.medium13.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required String label,
    required String value,
    String? subtitle,
    required IconData icon,
  }) {
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceLevel1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CustomAppFontStyle.regular11.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: CustomAppFontStyle.semiBold13.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: CustomAppFontStyle.regular10.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
