import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'package:eyadty/features/settings/presentation/cubit/medical_services_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/medical_services_state.dart';
import 'add_edit_medical_service_dialog.dart';
import 'medical_service_card.dart';
import 'medical_services_filter_bar.dart';
import 'medical_services_shimmer.dart';
import 'medical_services_table.dart';

class MedicalServicesTab extends StatefulWidget {
  const MedicalServicesTab({super.key});

  @override
  State<MedicalServicesTab> createState() => _MedicalServicesTabState();
}

class _MedicalServicesTabState extends State<MedicalServicesTab> {
  late final MedicalServicesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<MedicalServicesCubit>()..loadServices();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<MedicalServicesCubit, MedicalServicesState>(
        builder: (context, state) {
          if (state.status == RequestStatusEnum.loading &&
              state.services.isEmpty) {
            return const MedicalServicesShimmer();
          }

          if (state.status == RequestStatusEnum.failure &&
              state.services.isEmpty) {
            return _buildErrorView();
          }

          final isMobile = AdaptiveLayout.isMobile(context);
          final filteredServices = state.filteredServices;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Filter Bar ─────────────────────────────────────────────
              MedicalServicesFilterBar(
                cubit: _cubit,
                state: state,
                onAddService: () {
                  AddEditMedicalServiceDialog.show(
                    context,
                    cubit: _cubit,
                  );
                },
              ),
              const SizedBox(height: 16),

              // ─── List or Table Content ──────────────────────────────────
              Expanded(
                child: filteredServices.isEmpty
                    ? _buildEmptyState()
                    : isMobile
                        ? ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: filteredServices.length,
                            itemBuilder: (context, index) {
                              return MedicalServiceCard(
                                service: filteredServices[index],
                                cubit: _cubit,
                              );
                            },
                          )
                        : SingleChildScrollView(
                            child: MedicalServicesTable(
                              services: filteredServices,
                              cubit: _cubit,
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLevel1,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const CustomAssetImage(
                path: AppIcons.service,
                color: AppColors.grayMid,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'no_medical_services'.tr(),
              style: CustomAppFontStyle.semiBold16.copyWith(
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'no_medical_services_desc'.tr(),
              textAlign: TextAlign.center,
              style: CustomAppFontStyle.regular13.copyWith(
                color: AppColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'failed_to_load'.tr(),
            style: CustomAppFontStyle.semiBold18.copyWith(
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          CustomPushButton(
            height: 42,
            width: 140,
            backgroundColor: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            onTap: () => _cubit.loadServices(),
            child: Center(
              child: Text(
                'retry'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
