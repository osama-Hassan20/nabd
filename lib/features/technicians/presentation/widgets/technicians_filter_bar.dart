import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/technicians/data/models/enums/technician_status_enum.dart';
import 'package:purexo/features/technicians/presentation/cubit/technicians_cubit.dart';
import 'package:purexo/features/technicians/presentation/cubit/technicians_state.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:purexo/shared/widgets/custom_container.dart';
import 'package:purexo/shared/widgets/custom_push_container_button.dart';
import 'package:purexo/shared/widgets/custom_stack_selector.dart';
import 'package:purexo/shared/widgets/custom_text_field.dart';
import 'package:purexo/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'dialogs/add_edit_technician_dialog.dart';

class TechniciansFilterBar extends StatelessWidget {
  final VoidCallback? onAddNewTechnician;

  const TechniciansFilterBar({super.key, this.onAddNewTechnician});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TechniciansCubit>();

    return BlocBuilder<TechniciansCubit, TechniciansState>(
      buildWhen: (prev, curr) =>
          prev.selectedStatusFilter != curr.selectedStatusFilter,
      builder: (context, state) {
        return AdaptiveLayout(
          mobileLayout: (context) => _buildMobileLayout(context, cubit, state),
          tabletLayout: (context) => _buildTabletLayout(context, cubit, state),
          desktopLayout: (context) =>
              _buildDesktopLayout(context, cubit, state),
        );
      },
    );
  }

  // ─── Desktop Layout (width >= 1000) ──────────────────────────────────────────
  Widget _buildDesktopLayout(
    BuildContext context,
    TechniciansCubit cubit,
    TechniciansState state,
  ) {
    return CustomContainer(
      backGroundColor: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRaduis: 12,
      child: Row(
        children: [
          // Search Field (Flex 3)
          Expanded(flex: 3, child: _buildSearchField(cubit)),
          const SizedBox(width: 12),

          // Status Dropdown
          SizedBox(
            width: 190,
            child: _StatusDropdown(
              selectedStatus: state.selectedStatusFilter,
              onChanged: cubit.setStatusFilter,
            ),
          ),

          const SizedBox(width: 12),

          // Add New Technician Button
          _AddTechnicianButton(
            onTap: onAddNewTechnician ??
                () => AddEditTechnicianDialog.show(context: context),
            width: 170,
          ),
        ],
      ),
    );
  }

  // ─── Tablet Layout (700 < width < 1000) ──────────────────────────────────────
  Widget _buildTabletLayout(
    BuildContext context,
    TechniciansCubit cubit,
    TechniciansState state,
  ) {
    return CustomContainer(
      backGroundColor: AppColors.white,
      padding: const EdgeInsets.all(14),
      borderRaduis: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Search Field + Add Button
          Row(
            children: [
              Expanded(child: _buildSearchField(cubit)),
              const SizedBox(width: 12),
              _AddTechnicianButton(
                onTap: onAddNewTechnician ??
                    () => AddEditTechnicianDialog.show(context: context),
                width: 160,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Status Dropdown
          Row(
            children: [
              SizedBox(
                width: 220,
                child: _StatusDropdown(
                  selectedStatus: state.selectedStatusFilter,
                  onChanged: cubit.setStatusFilter,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Mobile Layout (width <= 700) ───────────────────────────────────────────
  Widget _buildMobileLayout(
    BuildContext context,
    TechniciansCubit cubit,
    TechniciansState state,
  ) {
    return CustomContainer(
      backGroundColor: AppColors.white,
      padding: const EdgeInsets.all(12),
      borderRaduis: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Field
          _buildSearchField(cubit),
          const SizedBox(height: 10),

          // Status Dropdown
          _StatusDropdown(
            selectedStatus: state.selectedStatusFilter,
            onChanged: cubit.setStatusFilter,
          ),
          const SizedBox(height: 10),

          // Add New Technician Button (Full Width on Mobile)
          _AddTechnicianButton(
            onTap: onAddNewTechnician ??
                () => AddEditTechnicianDialog.show(context: context),
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  // ─── Shared Search Field Widget ─────────────────────────────────────────────
  Widget _buildSearchField(TechniciansCubit cubit) {
    return CustomTextFormField(
      controller: cubit.searchController,
      hintText: 'search_technicians_hint'.tr(),
      prefixWidget: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: CustomAssetImage(
          path: AppIcons.search,
          width: 18,
          height: 18,
          color: AppColors.gray71717A,
        ),
      ),
      suffixWidget: cubit.searchController.text.isNotEmpty
          ? IconButton(
              icon: const CustomAssetImage(
                path: AppIcons.close,
                width: 14,
                height: 14,
                color: AppColors.gray71717A,
              ),
              onPressed: () {
                cubit.searchController.clear();
                cubit.fetchTechnicians(resetPage: true);
              },
            )
          : null,
    );
  }
}

class _StatusDropdown extends StatefulWidget {
  final TechnicianStatusEnum? selectedStatus;
  final ValueChanged<TechnicianStatusEnum?> onChanged;

  const _StatusDropdown({
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  State<_StatusDropdown> createState() => _StatusDropdownState();
}

class _StatusDropdownState extends State<_StatusDropdown> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.selectedStatus?.label ?? 'all_statuses'.tr(),
    );
  }

  @override
  void didUpdateWidget(_StatusDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedStatus != widget.selectedStatus) {
      _controller.text = widget.selectedStatus?.label ?? 'all_statuses'.tr();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = <TechnicianStatusEnum?>[null, ...TechnicianStatusEnum.values];
    return CustomStackSelector<TechnicianStatusEnum?>(
      controller: _controller,
      list: list,
      itemAsString: (s) => s?.label ?? 'all_statuses'.tr(),
      hintText: 'all_statuses'.tr(),
      changeValue: (s) => widget.onChanged(s),
    );
  }
}

class _AddTechnicianButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isFullWidth;
  final double? width;

  const _AddTechnicianButton({
    required this.onTap,
    this.isFullWidth = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPushButton(
      height: 48,
      width: isFullWidth ? double.infinity : (width ?? 170),
      backgroundColor: AppColors.secondary,
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CustomAssetImage(
            path: AppIcons.add,
            width: 16,
            height: 16,
            color: AppColors.white,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'add_technician'.tr(),
              style: CustomAppFontStyle.semiBold14.copyWith(
                color: AppColors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
