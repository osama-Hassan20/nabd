import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
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
  }

  @override
  void didUpdateWidget(covariant StaffUsersFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.searchQuery != _searchController.text) {
      _searchController.text = widget.state.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grayE2E8F0, width: 1),
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
    return CustomTextFormField(
      controller: _searchController,
      hintText: 'search_staff_users_hint'.tr(),
      prefixWidget: const Icon(
        Icons.search_rounded,
        color: AppColors.gray71717A,
        size: 20,
      ),
      suffixWidget: _searchController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18),
              color: AppColors.gray71717A,
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
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: widget.state.branchFilter,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.gray71717A, size: 20),
          style: CustomAppFontStyle.regular13.copyWith(
            color: AppColors.darkText,
          ),
          hint: Text(
            'all_branches'.tr(),
            style: CustomAppFontStyle.regular13.copyWith(
              color: AppColors.gray71717A,
            ),
          ),
          items: _branches.map((b) {
            return DropdownMenuItem<String?>(
              value: b.$1,
              child: Text(
                b.$2.tr(),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            widget.cubit.setBranchFilter(val);
          },
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    final items = <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?>(
        value: null,
        child: Text('all_roles'.tr()),
      ),
      ...widget.state.roles.map((r) {
        return DropdownMenuItem<String?>(
          value: r.id,
          child: Text(
            r.nameAr ?? r.id ?? '',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }),
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: widget.state.roleFilter,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.gray71717A, size: 20),
          style: CustomAppFontStyle.regular13.copyWith(
            color: AppColors.darkText,
          ),
          hint: Text(
            'all_roles'.tr(),
            style: CustomAppFontStyle.regular13.copyWith(
              color: AppColors.gray71717A,
            ),
          ),
          items: items,
          onChanged: (val) {
            widget.cubit.setRoleFilter(val);
          },
        ),
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabPill(
            filter: StaffUserStatusFilter.all,
            title: 'all'.tr(),
            count: widget.state.totalCount,
          ),
          const SizedBox(width: 4),
          _buildTabPill(
            filter: StaffUserStatusFilter.active,
            title: 'status_active'.tr(),
            count: widget.state.activeCount,
            activeColor: const Color(0xFF10B981),
          ),
          const SizedBox(width: 4),
          _buildTabPill(
            filter: StaffUserStatusFilter.inactive,
            title: 'status_inactive'.tr(),
            count: widget.state.inactiveCount,
            activeColor: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required StaffUserStatusFilter filter,
    required String title,
    required int count,
    Color? activeColor,
  }) {
    final isSelected = widget.state.statusFilter == filter;

    return InkWell(
      onTap: () => widget.cubit.setStatusFilter(filter),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: CustomAppFontStyle.semiBold13.copyWith(
                color: isSelected
                    ? (activeColor ?? AppColors.primary)
                    : AppColors.gray71717A,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? (activeColor ?? AppColors.primary).withValues(alpha: 0.12)
                    : AppColors.grayE2E8F0,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: CustomAppFontStyle.medium11.copyWith(
                  color: isSelected
                      ? (activeColor ?? AppColors.primary)
                      : AppColors.gray71717A,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
