import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/custom_stack_selector.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../cubit/staff_users_cubit.dart';
import '../cubit/staff_users_state.dart';

class StaffUsersFilterBar extends StatefulWidget {
  final StaffUsersCubit cubit;
  final StaffUsersState state;

  const StaffUsersFilterBar({
    super.key,
    required this.cubit,
    required this.state,
  });

  @override
  State<StaffUsersFilterBar> createState() => _StaffUsersFilterBarState();
}

class _StaffUsersFilterBarState extends State<StaffUsersFilterBar> {
  late final TextEditingController _searchController;
  late final TextEditingController _branchController;
  late final TextEditingController _roleController;

  static const List<(String?, String)> _branches = [
    (null, 'all_branches'),
    ('branch_1', 'branch_main'),
    ('branch_2', 'branch_second'),
    ('branch_3', 'branch_third'),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
    _branchController = TextEditingController(text: _getBranchLabel(widget.state.branchFilter));
    _roleController = TextEditingController(text: _getRoleLabel(widget.state.roleFilter));
  }

  @override
  void didUpdateWidget(covariant StaffUsersFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.searchQuery != _searchController.text) {
      _searchController.text = widget.state.searchQuery;
    }
    if (widget.state.branchFilter != oldWidget.state.branchFilter) {
      _branchController.text = _getBranchLabel(widget.state.branchFilter);
    }
    if (widget.state.roleFilter != oldWidget.state.roleFilter ||
        widget.state.roles != oldWidget.state.roles) {
      _roleController.text = _getRoleLabel(widget.state.roleFilter);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _branchController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  String _getBranchLabel(String? branchId) {
    final match = _branches.where((b) => b.$1 == branchId);
    if (match.isNotEmpty) return match.first.$2.tr();
    return 'all_branches'.tr();
  }

  String _getRoleLabel(String? roleId) {
    if (roleId == null) return 'all_roles'.tr();
    final match = widget.state.roles.where((r) => r.id == roleId);
    if (match.isNotEmpty) return match.first.nameAr ?? match.first.id ?? '';
    return 'all_roles'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final colors = context.themeColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildSearchField(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildBranchDropdown(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildRoleDropdown(),
                ),
                const SizedBox(width: 16),
                _buildStatusTabs(),
              ],
            )
          else ...[
            _buildSearchField(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildBranchDropdown()),
                const SizedBox(width: 10),
                Expanded(child: _buildRoleDropdown()),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusTabs(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final colors = context.themeColors;
    return CustomTextFormField(
      key: const Key('input_search_staff_users'),
      controller: _searchController,
      hintText: 'search_staff_users_hint'.tr(),
      prefixWidget: Icon(
        Icons.search_rounded,
        color: colors.textSecondary,
        size: 20,
      ),
      suffixWidget: _searchController.text.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.clear_rounded, size: 18, color: colors.textSecondary),
              color: colors.textSecondary,
              onPressed: () {
                _searchController.clear();
                widget.cubit.setSearchQuery('');
              },
            )
          : null,
      onChanged: (val) {
        widget.cubit.setSearchQuery(val ?? '');
      },
    );
  }

  Widget _buildBranchDropdown() {
    return CustomStackSelector<(String?, String)>(
      controller: _branchController,
      hintText: 'all_branches'.tr(),
      list: _branches,
      itemAsString: (b) => b.$2.tr(),
      changeValue: (b) {
        setState(() {
          _branchController.text = b.$2.tr();
        });
        widget.cubit.setBranchFilter(b.$1);
      },
    );
  }

  Widget _buildRoleDropdown() {
    final roleList = <(String?, String)>[
      (null, 'all_roles'.tr()),
      ...widget.state.roles.map((r) => (r.id, r.nameAr ?? r.id ?? '')),
    ];

    return CustomStackSelector<(String?, String)>(
      controller: _roleController,
      hintText: 'all_roles'.tr(),
      list: roleList,
      itemAsString: (r) => r.$2,
      changeValue: (r) {
        setState(() {
          _roleController.text = r.$2;
        });
        widget.cubit.setRoleFilter(r.$1);
      },
    );
  }

  Widget _buildStatusTabs() {
    final colors = context.themeColors;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceLevel1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusTabItem(
            title: 'status_all'.tr(),
            isSelected: widget.state.statusFilter == StaffUserStatusFilter.all,
            onTap: () => widget.cubit.setStatusFilter(StaffUserStatusFilter.all),
          ),
          _buildStatusTabItem(
            title: 'status_active'.tr(),
            isSelected: widget.state.statusFilter == StaffUserStatusFilter.active,
            onTap: () => widget.cubit.setStatusFilter(StaffUserStatusFilter.active),
          ),
          _buildStatusTabItem(
            title: 'status_inactive'.tr(),
            isSelected: widget.state.statusFilter == StaffUserStatusFilter.inactive,
            onTap: () => widget.cubit.setStatusFilter(StaffUserStatusFilter.inactive),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.themeColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: CustomAppFontStyle.medium13.copyWith(
            color: isSelected ? colors.primary : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
