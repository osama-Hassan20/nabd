import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'package:eyadty/features/settings/presentation/cubit/medical_services_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/medical_services_state.dart';

class MedicalServicesFilterBar extends StatelessWidget {
  final MedicalServicesCubit cubit;
  final MedicalServicesState state;
  final VoidCallback onAddService;

  const MedicalServicesFilterBar({
    super.key,
    required this.cubit,
    required this.state,
    required this.onAddService,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AdaptiveLayout.isMobile(context);
    final isAdmin = getIt<CurrentRoleProvider>().currentRole.canManageServices;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatusFilterChips()),
              if (isAdmin) ...[
                const SizedBox(width: 8),
                _buildAddButton(compact: true),
              ],
            ],
          ),
        ],
      );
    }

    return CustomContainer(
      backGroundColor: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.grayE2E8F0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatusFilterChips()),
                    if (isAdmin) ...[
                      const SizedBox(width: 12),
                      _buildAddButton(compact: constraints.maxWidth < 450),
                    ],
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              // Search Field
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildSearchField(),
                ),
              ),
              const SizedBox(width: 16),

              // Status Filter Tabs
              _buildStatusFilterChips(),

              if (isAdmin) ...[
                const SizedBox(width: 16),
                _buildAddButton(compact: false),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return CustomTextFormField(
      hintText: 'search_services_hint'.tr(),
      isDense: true,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      prefixWidget: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: CustomAssetImage(
          path: AppIcons.search,
          width: 18,
          height: 18,
          color: AppColors.grayMid,
        ),
      ),
      onChanged: (val) => cubit.search(val ?? ''),
    );
  }

  Widget _buildStatusFilterChips() {
    final current = state.statusFilter;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLevel1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterChip(
              key: 'all',
              label: 'service_status_all'.tr(),
              isSelected: current == 'all',
            ),
            const SizedBox(width: 4),
            _buildFilterChip(
              key: 'active',
              label: 'service_status_active'.tr(),
              isSelected: current == 'active',
            ),
            const SizedBox(width: 4),
            _buildFilterChip(
              key: 'inactive',
              label: 'service_status_inactive'.tr(),
              isSelected: current == 'inactive',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String key,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => cubit.setStatusFilter(key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: isSelected
              ? CustomAppFontStyle.semiBold13.copyWith(
                  color: AppColors.darkText,
                )
              : CustomAppFontStyle.regular13.copyWith(
                  color: AppColors.gray,
                ),
        ),
      ),
    );
  }

  Widget _buildAddButton({required bool compact}) {
    return CustomPushButton(
      height: 42,
      width: compact ? 42 : 140,
      backgroundColor: AppColors.primary,
      borderRadius: BorderRadius.circular(8),
      onTap: onAddService,
      child: Center(
        child: compact
            ? const Icon(Icons.add, color: AppColors.white, size: 20)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: AppColors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'add_medical_service'.tr(),
                    style: CustomAppFontStyle.medium14.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
