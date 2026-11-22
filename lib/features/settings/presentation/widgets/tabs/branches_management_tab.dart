import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/branches/data/models/branch_model.dart';
import 'package:eyadty/features/branches/presentation/cubit/branches_cubit.dart';
import 'package:eyadty/features/branches/presentation/cubit/branches_state.dart';
import 'package:eyadty/features/branches/presentation/pages/dialogs/add_edit_branch_dialog.dart';
import 'package:eyadty/features/branches/presentation/pages/dialogs/copy_branch_settings_dialog.dart';
import 'package:eyadty/features/branches/presentation/pages/dialogs/toggle_branch_status_dialog.dart';
import 'package:eyadty/features/branches/presentation/widgets/branch_card.dart';
import 'package:eyadty/features/branches/presentation/widgets/branches_table.dart';
import 'package:eyadty/shared/widgets/custom_empty_widget.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_shimmer_container.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/error_page.dart';

class BranchesManagementTab extends StatelessWidget {
  const BranchesManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<BranchesCubit>()..loadBranches(),
      child: const _BranchesManagementView(),
    );
  }
}

class _BranchesManagementView extends StatefulWidget {
  const _BranchesManagementView();

  @override
  State<_BranchesManagementView> createState() => _BranchesManagementViewState();
}

class _BranchesManagementViewState extends State<_BranchesManagementView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BranchesCubit, BranchesState>(
      listener: (context, state) {
        if (state.errMessage != null && state.errMessage!.isNotEmpty) {
          CustomToast(
            context: context,
            header: state.errMessage!.tr(),
          ).showErrorToast();
        } else if (state.successMessage != null &&
            state.successMessage!.isNotEmpty) {
          CustomToast(
            context: context,
            header: state.successMessage!.tr(),
          ).showTopToast();
        }
      },
      builder: (context, state) {
        final cubit = context.read<BranchesCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header & Actions ──────────────────────────────────────────
            _buildHeader(context),
            const SizedBox(height: 16),

            // ─── Filter Bar ────────────────────────────────────────────────
            _buildFilterBar(context, cubit, state),
            const SizedBox(height: 16),

            // ─── Content ───────────────────────────────────────────────────
            Expanded(
              child: _buildContent(context, cubit, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Row(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'branches_management'.tr(),
                style: CustomAppFontStyle.bold20.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'branches_management_desc'.tr(),
                style: CustomAppFontStyle.regular12.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CustomPushButton(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          onTap: () => _openAddEditBranchDialog(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_business_rounded, size: 18, color: AppColors.white),
              const SizedBox(width: 6),
              Text(
                'add_branch'.tr(),
                style: CustomAppFontStyle.semiBold13.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    BranchesCubit cubit,
    BranchesState state,
  ) {
    final colors = context.themeColors;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search field
              Expanded(
                child: CustomTextFormField(
                  controller: _searchController,
                  hintText: 'search_branches_hint'.tr(),
                  prefixWidget: const Icon(Icons.search_rounded, size: 18, color: AppColors.gray71717A),
                  suffixWidget: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
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
              if (!isMobile) ...[
                const SizedBox(width: 14),
                _buildStatusFilters(cubit, state),
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _buildStatusFilters(cubit, state),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusFilters(BranchesCubit cubit, BranchesState state) {
    final filters = [
      {'key': 'all', 'label': 'all'.tr()},
      {'key': 'active', 'label': 'status_active'.tr()},
      {'key': 'inactive', 'label': 'status_inactive'.tr()},
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: filters.map((f) {
        final key = f['key']!;
        final label = f['label']!;
        final isSelected = state.activeFilter == key;

        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => cubit.setActiveFilter(key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.darkText : AppColors.fillDisableColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: CustomAppFontStyle.medium12.copyWith(
                  color: isSelected ? AppColors.white : AppColors.gray71717A,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BranchesCubit cubit,
    BranchesState state,
  ) {
    if (state.status == RequestStatusEnum.loading && state.branches.isEmpty) {
      return ListView.separated(
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => const CustomShimmerContainer(
          width: double.infinity,
          height: 60,
          borderRadius: 12,
        ),
      );
    }

    if (state.status == RequestStatusEnum.failure && state.branches.isEmpty) {
      return ErrorPage(
        onPressed: () => cubit.loadBranches(),
      );
    }

    final filtered = state.filteredBranches;

    if (filtered.isEmpty) {
      return CustomEmptyWidget(
        title: 'no_branches_found'.tr(),
        subtitle: Text(
          'no_branches_desc'.tr(),
          style: CustomAppFontStyle.regular13.copyWith(
            color: AppColors.gray71717A,
          ),
        ),
        enableButton: true,
        buttonTitle: 'add_branch'.tr(),
        onButtonPressed: () => _openAddEditBranchDialog(context),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 800;

    if (isWide) {
      final colors = context.themeColors;
      return Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: colors.isDark ? 0.35 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BranchesTable(
            branches: filtered,
            onEdit: (b) => _openAddEditBranchDialog(context, branch: b),
            onToggleStatus: (b) => _openToggleStatusDialog(context, branch: b),
            onSetMain: (b) => _setMainBranch(context, branch: b),
            onCopySettings: (b) => _openCopySettingsDialog(context, targetBranch: b, all: state.branches),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final b = filtered[index];
        return BranchCard(
          branch: b,
          onEdit: (b) => _openAddEditBranchDialog(context, branch: b),
          onToggleStatus: (b) => _openToggleStatusDialog(context, branch: b),
          onSetMain: (b) => _setMainBranch(context, branch: b),
          onCopySettings: (b) => _openCopySettingsDialog(context, targetBranch: b, all: state.branches),
        );
      },
    );
  }

  void _openAddEditBranchDialog(BuildContext context, {BranchModel? branch}) {
    final cubit = context.read<BranchesCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dContext) => BlocProvider.value(
        value: cubit,
        child: AddEditBranchDialog(branch: branch),
      ),
    );
  }

  void _openToggleStatusDialog(BuildContext context, {required BranchModel branch}) {
    final cubit = context.read<BranchesCubit>();
    showDialog(
      context: context,
      builder: (dContext) => BlocProvider.value(
        value: cubit,
        child: ToggleBranchStatusDialog(branch: branch),
      ),
    );
  }

  void _openCopySettingsDialog(
    BuildContext context, {
    required BranchModel targetBranch,
    required List<BranchModel> all,
  }) {
    final cubit = context.read<BranchesCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dContext) => BlocProvider.value(
        value: cubit,
        child: CopyBranchSettingsDialog(
          targetBranch: targetBranch,
          allBranches: all,
        ),
      ),
    );
  }

  void _setMainBranch(BuildContext context, {required BranchModel branch}) {
    final cubit = context.read<BranchesCubit>();
    final currentUserId = getIt.isRegistered<SessionCubit>()
        ? getIt<SessionCubit>().currentUser?.id ?? 'USER-OWNER'
        : 'USER-OWNER';

    cubit.setMainBranch(
      branchId: branch.id ?? '',
      currentUserId: currentUserId,
    );
  }
}
