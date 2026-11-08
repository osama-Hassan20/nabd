import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/users_management/data/models/security_audit_log_model.dart';
import '../pages/dialogs/audit_log_details_dialog.dart';
import 'audit_event_type_badge.dart';

class AuditLogsTable extends StatelessWidget {
  final List<SecurityAuditLogModel> logs;

  const AuditLogsTable({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a', 'ar');

    final headers = [
      'table_timestamp'.tr(),
      'table_event_type'.tr(),
      'table_actor'.tr(),
      'table_target'.tr(),
      'table_branch'.tr(),
      'table_details'.tr(),
      'table_ip'.tr(),
      'actions'.tr(),
    ];

    final columnWidths = const <int, TableColumnWidth>{
      0: FixedColumnWidth(160),
      1: FixedColumnWidth(170),
      2: FixedColumnWidth(160),
      3: FixedColumnWidth(150),
      4: FixedColumnWidth(140),
      5: FlexColumnWidth(2.5),
      6: FixedColumnWidth(120),
      7: FixedColumnWidth(70),
    };

    final rows = logs.map((log) {
      final formattedTime = log.timestamp != null
          ? dateFormat.format(log.timestamp!)
          : '-';

      return [
        // 0: Timestamp
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded, size: 14, color: AppColors.gray71717A),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                formattedTime,
                style: CustomAppFontStyle.regular12.copyWith(
                  color: AppColors.darkText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // 1: Event Type Badge
        Align(
          alignment: Alignment.centerRight,
          child: AuditEventTypeBadge(eventType: log.eventType),
        ),

        // 2: Actor
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              log.performedByUserName ?? log.performedByUserId ?? 'النظام',
              style: CustomAppFontStyle.semiBold12.copyWith(
                color: AppColors.darkText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (log.performedByUserId != null)
              Text(
                log.performedByUserId!,
                style: CustomAppFontStyle.regular10.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
          ],
        ),

        // 3: Target
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              log.targetUserName ?? log.targetUserId ?? '-',
              style: CustomAppFontStyle.medium12.copyWith(
                color: AppColors.darkText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (log.targetUserId != null && log.targetUserName != null)
              Text(
                log.targetUserId!,
                style: CustomAppFontStyle.regular10.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
          ],
        ),

        // 4: Branch
        Text(
          log.branchName ?? log.branchId ?? 'المنشأة',
          style: CustomAppFontStyle.regular12.copyWith(
            color: AppColors.gray71717A,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // 5: Details
        Text(
          log.details ?? '-',
          style: CustomAppFontStyle.regular12.copyWith(
            color: AppColors.darkText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // 6: IP
        Text(
          log.ipAddress ?? '-',
          style: CustomAppFontStyle.medium12.copyWith(
            color: AppColors.gray71717A,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // 7: Actions
        IconButton(
          icon: const Icon(
            Icons.remove_red_eye_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          tooltip: 'view_details'.tr(),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AuditLogDetailsDialog(log: log),
            );
          },
        ),
      ];
    }).toList();

    return CustomTable(
      headers: headers,
      columnWidths: columnWidths,
      rows: rows,
    );
  }
}
