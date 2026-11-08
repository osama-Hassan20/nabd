import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
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
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: AppColors.primary,
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
                            color: AppColors.darkText,
                          ),
                        ),
                        Text(
                          log.id ?? '',
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: AppColors.gray71717A,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.grayE2E8F0),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Event Badge & Time
                    Row(
                      children: [
                        AuditEventTypeBadge(eventType: log.eventType),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: AppColors.gray71717A,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formattedDate,
                              style: CustomAppFontStyle.medium12.copyWith(
                                color: AppColors.gray71717A,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Grid Info
                    _buildInfoTile(
                      label: 'table_actor'.tr(),
                      value: log.performedByUserName ?? log.performedByUserId ?? 'النظام الآلي',
                      subtitle: log.performedByUserId != null ? 'ID: ${log.performedByUserId}' : null,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),

                    if (log.targetUserName != null || log.targetUserId != null) ...[
                      _buildInfoTile(
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
                            label: 'table_branch'.tr(),
                            value: log.branchName ?? log.branchId ?? 'المنشأة العامة',
                            icon: Icons.storefront_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoTile(
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
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.fillDisableColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.grayE2E8F0),
                      ),
                      child: SelectableText(
                        log.details ?? '-',
                        style: CustomAppFontStyle.regular13.copyWith(
                          color: AppColors.darkText,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: AppColors.grayE2E8F0),

            // Footer
            Padding(
              padding: const EdgeInsets.all(14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CustomPushButton(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  backgroundColor: AppColors.fillDisableColor,
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).pop(),
                  child: Center(
                    child: Text(
                      'cancel'.tr(),
                      style: CustomAppFontStyle.medium13.copyWith(
                        color: AppColors.darkText,
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
    required String label,
    required String value,
    String? subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fillDisableColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CustomAppFontStyle.regular11.copyWith(
                    color: AppColors.gray71717A,
                  ),
                ),
                Text(
                  value,
                  style: CustomAppFontStyle.semiBold13.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: CustomAppFontStyle.regular10.copyWith(
                      color: AppColors.gray71717A,
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
