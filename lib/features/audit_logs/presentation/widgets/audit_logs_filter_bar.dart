import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../shared/widgets/custom_stack_selector.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_toast.dart';
import '../cubit/audit_logs_cubit.dart';
import '../cubit/audit_logs_state.dart';

class AuditLogsFilterBar extends StatefulWidget {
  final AuditLogsCubit cubit;
  final AuditLogsState state;

  const AuditLogsFilterBar({
    super.key,
    required this.cubit,
    required this.state,
  });

  @override
  State<AuditLogsFilterBar> createState() => _AuditLogsFilterBarState();
}

class _AuditLogsFilterBarState extends State<AuditLogsFilterBar> {
  late final TextEditingController _searchController;
  late final TextEditingController _eventTypeController;
  late final TextEditingController _branchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
    _eventTypeController = TextEditingController();
    _branchController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant AuditLogsFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.searchQuery != _searchController.text &&
        widget.state.searchQuery.isEmpty) {
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _eventTypeController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = widget.cubit;
    final state = widget.state;

    final eventTypes = [
      {'key': 'all', 'label': 'filter_all_events'.tr()},
      {'key': 'login_success', 'label': 'audit_event_login_success'.tr()},
      {'key': 'login_failure', 'label': 'audit_event_login_failure'.tr()},
      {'key': 'logout', 'label': 'audit_event_logout'.tr()},
      {'key': 'create_user', 'label': 'audit_event_create_user'.tr()},
      {'key': 'update_user', 'label': 'audit_event_update_user'.tr()},
      {'key': 'toggle_user_status', 'label': 'audit_event_toggle_user_status'.tr()},
      {'key': 'delete_user', 'label': 'audit_event_delete_user'.tr()},
      {'key': 'update_role_permissions', 'label': 'audit_event_update_role_permissions'.tr()},
      {'key': 'create_branch', 'label': 'audit_event_create_branch'.tr()},
      {'key': 'update_branch', 'label': 'audit_event_update_branch'.tr()},
      {'key': 'toggle_branch_status', 'label': 'audit_event_toggle_branch_status'.tr()},
      {'key': 'set_main_branch', 'label': 'audit_event_set_main_branch'.tr()},
      {'key': 'copy_branch_settings', 'label': 'audit_event_copy_branch_settings'.tr()},
      {'key': 'view_patient_profile', 'label': 'audit_event_view_patient_profile'.tr()},
    ];

    final branches = [
      {'key': 'all', 'label': 'filter_all_branches'.tr()},
      {'key': 'branch_1', 'label': 'الفرع الرئيسي (المعادي)'},
      {'key': 'branch_2', 'label': 'فرع الجيزة (المهندسين)'},
      {'key': 'branch_3', 'label': 'فرع الإسكندرية (سموحة)'},
    ];

    final hasActiveFilters = state.searchQuery.isNotEmpty ||
        state.selectedEventType != 'all' ||
        state.selectedBranchId != 'all' ||
        state.startDate != null ||
        state.endDate != null;

    final colors = context.themeColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Search & Controls
          Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                  controller: _searchController,
                  hintText: 'search_audit_logs_hint'.tr(),
                  prefixWidget: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  suffixWidget: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, size: 16, color: colors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            cubit.setSearchQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                  onChanged: (val) {
                    cubit.setSearchQuery(val ?? '');
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Export Button
              CustomPushButton(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: colors.surfaceLevel1,
                borderRadius: BorderRadius.circular(8),
                boxBorder: Border.all(color: colors.borderSubtle),
                onTap: () async {
                  final ok = await cubit.exportLogs();
                  if (ok && context.mounted) {
                    CustomToast(
                      context: context,
                      header: 'export_success_toast'.tr(),
                    ).showTopToast();
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_rounded, size: 16, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'export_audit_logs'.tr(),
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              if (hasActiveFilters) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'مسح التصفية',
                  icon: Icon(Icons.filter_alt_off_rounded, size: 18, color: colors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    cubit.clearFilters();
                    setState(() {});
                  },
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Selectors (EventType, Branch, DateRange)
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Event Type Dropdown
              SizedBox(
                width: 170,
                child: CustomStackSelector<Map<String, String>>(
                  controller: _eventTypeController,
                  list: eventTypes,
                  itemAsString: (item) => item['label'] ?? '',
                  changeValue: (item) {
                    if (item['key'] != null) {
                      _eventTypeController.text = item['label'] ?? '';
                      cubit.setEventTypeFilter(item['key']!);
                    }
                  },
                ),
              ),

              // Branch Dropdown
              SizedBox(
                width: 170,
                child: CustomStackSelector<Map<String, String>>(
                  controller: _branchController,
                  list: branches,
                  itemAsString: (item) => item['label'] ?? '',
                  changeValue: (item) {
                    if (item['key'] != null) {
                      _branchController.text = item['label'] ?? '';
                      cubit.setBranchFilter(item['key']!);
                    }
                  },
                ),
              ),

              // Date Range Picker Button
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final now = CairoTimeHelper.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 2),
                    lastDate: DateTime(now.year + 1),
                    initialDateRange: state.startDate != null && state.endDate != null
                        ? DateTimeRange(start: state.startDate!, end: state.endDate!)
                        : null,
                  );
                  if (picked != null) {
                    cubit.setDateRangeFilter(picked.start, picked.end);
                  }
                },
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: (state.startDate != null || state.endDate != null)
                        ? colors.primary.withValues(alpha: 0.12)
                        : colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (state.startDate != null || state.endDate != null)
                          ? colors.primary
                          : colors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 16,
                        color: (state.startDate != null || state.endDate != null)
                            ? colors.primary
                            : colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.startDate != null && state.endDate != null
                            ? '${DateFormat('MM/dd').format(state.startDate!)} - ${DateFormat('MM/dd').format(state.endDate!)}'
                            : 'filter_date_range'.tr(),
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: (state.startDate != null || state.endDate != null)
                              ? colors.primary
                              : colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
