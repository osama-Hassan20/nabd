import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';

import 'sync_status_dialog.dart';

class HeaderDataModeWidget extends StatelessWidget {
  const HeaderDataModeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<DataModeService>()) {
      return const SizedBox.shrink();
    }

    final dataModeService = getIt<DataModeService>();

    return StreamBuilder<DataModeState>(
      stream: dataModeService.stream,
      initialData: dataModeService.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? dataModeService.state;

        final Color statusColor;
        final String statusLabel;

        switch (state.mode) {
          case DataMode.online:
            statusColor = const Color(0xFF10B981);
            statusLabel = 'mode_online'.tr();
            break;
          case DataMode.offline:
            statusColor = const Color(0xFFEF4444);
            statusLabel = 'mode_offline'.tr();
            break;
          case DataMode.forcedLocal:
            statusColor = const Color(0xFFF59E0B);
            statusLabel = 'mode_forced_local'.tr();
            break;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Chip (Clickable to open Sync Details & Conflicts)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => SyncStatusDialog.show(context),
              child: Container(
                key: const Key('header_data_mode_chip'),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.isSyncInProgress) ...[
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ] else ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      statusLabel,
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: statusColor,
                      ),
                    ),
                    if (state.pendingOutboxCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${state.pendingOutboxCount} ${'pending_sync_operations'.tr()}',
                          style: CustomAppFontStyle.medium10.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Forced Local Mode Toggle Button
            Tooltip(
              message: 'toggle_local_mode_tooltip'.tr(),
              child: InkWell(
                key: const Key('header_forced_local_toggle_btn'),
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  dataModeService.setForcedLocal(!state.isForcedLocal);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: state.isForcedLocal
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : AppColors.grayE2E8F0.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: state.isForcedLocal
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                          : AppColors.grayE2E8F0,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      state.isForcedLocal
                          ? Icons.cloud_off_rounded
                          : Icons.cloud_queue_rounded,
                      size: 18,
                      color: state.isForcedLocal
                          ? const Color(0xFFD97706)
                          : AppColors.gray71717A,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
