import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/conflict_record.dart';
import 'package:eyadty/core/offline/store/transactional_local_store.dart';
import 'package:eyadty/core/offline/sync/sync_engine.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

class SyncStatusDialog extends StatefulWidget {
  const SyncStatusDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const SyncStatusDialog(),
    );
  }

  @override
  State<SyncStatusDialog> createState() => _SyncStatusDialogState();
}

class _SyncStatusDialogState extends State<SyncStatusDialog> {
  List<ConflictRecord> _conflicts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConflicts();
  }

  Future<void> _loadConflicts() async {
    if (getIt.isRegistered<TransactionalLocalStore>()) {
      final conflicts =
          await getIt<TransactionalLocalStore>().getUnresolvedConflicts();
      if (mounted) {
        setState(() {
          _conflicts = conflicts;
        });
      }
    }
  }

  Future<void> _handleSyncNow() async {
    if (!getIt.isRegistered<SyncEngine>()) return;

    setState(() => _isLoading = true);
    await getIt<SyncEngine>().syncNow();
    await _loadConflicts();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeService = getIt.isRegistered<DataModeService>()
        ? getIt<DataModeService>()
        : null;
    final state = modeService?.state;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.grayE2E8F0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sync_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'sync_status_title'.tr(),
                      style: CustomAppFontStyle.bold16.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 18),

              // KPI / Status Overview
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      label: 'الوضع الحالي',
                      value: state != null
                          ? (state.isForcedLocal
                              ? 'mode_forced_local'.tr()
                              : (state.isServerReachable
                                  ? 'mode_online'.tr()
                                  : 'mode_offline'.tr()))
                          : 'غير متاح',
                      color: state?.mode == DataMode.online
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      label: 'العمليات المعلقة',
                      value: '${state?.pendingOutboxCount ?? 0}',
                      color: (state?.pendingOutboxCount ?? 0) > 0
                          ? const Color(0xFFD97706)
                          : const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      label: 'تعارضات بانتظار المراجعة',
                      value: '${_conflicts.length}',
                      color: _conflicts.isNotEmpty
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Conflicts List Section
              if (_conflicts.isNotEmpty) ...[
                Text(
                  'conflicts_detected'.tr(),
                  style: CustomAppFontStyle.bold14.copyWith(
                    color: const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _conflicts.length,
                    itemBuilder: (ctx, idx) {
                      final c = _conflicts[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تعارض في ${c.entityType} (${c.localId})',
                              style: CustomAppFontStyle.semiBold12.copyWith(
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'تم حفظ النسخة المحلية والخادم بأمان لحين المراجعة اليدوية.',
                              style: CustomAppFontStyle.regular12.copyWith(
                                color: const Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.grayE2E8F0.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'no_conflicts'.tr(),
                        style: CustomAppFontStyle.regular13.copyWith(
                          color: AppColors.gray71717A,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomPushButton(
                      height: 44,
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      isLoading: _isLoading,
                      onTap: _handleSyncNow,
                      child: Center(
                        child: Text(
                          'sync_now'.tr(),
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomPushButton(
                      height: 44,
                      radius: 12,
                      backgroundColor: AppColors.grayE2E8F0,
                      onTap: () => Navigator.of(context).pop(),
                      child: Center(
                        child: Text(
                          'close'.tr(),
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
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

  Widget _buildStatusCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: CustomAppFontStyle.regular10.copyWith(
              color: AppColors.gray71717A,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: CustomAppFontStyle.bold14.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
