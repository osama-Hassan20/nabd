import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purexo/core/dependency_injection/dependency_injection.dart';
import 'package:purexo/core/routing/routes.dart';
import 'package:purexo/core/utils/enums/request_status_enum.dart';
import 'package:purexo/core/utils/extensions/sliver_extentions.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/technicians/presentation/cubit/technicians_cubit.dart';
import 'package:purexo/features/technicians/presentation/cubit/technicians_state.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:purexo/shared/widgets/error_page.dart';

import '../widgets/technician_details_sections/technician_bookings_section.dart';
import '../widgets/technician_details_sections/technician_details_shimmer.dart';
import '../widgets/technician_details_sections/technician_leaves_section.dart';
import '../widgets/technician_details_sections/technician_profile_card_section.dart';
import '../widgets/technician_details_sections/technician_stats_cards_section.dart';
import '../widgets/technician_details_sections/technician_today_schedule_section.dart';

class TechnicianDetailsPage extends StatelessWidget {
  final String technicianId;

  const TechnicianDetailsPage({super.key, required this.technicianId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) =>
            getIt<TechniciansCubit>()..fetchTechnicianDetails(technicianId),
        child: BlocBuilder<TechniciansCubit, TechniciansState>(
          builder: (context, state) {
            final cubit = context.read<TechniciansCubit>();

            return RefreshIndicator(
              onRefresh: () async => cubit.fetchTechnicianDetails(technicianId),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Top Navigation Back Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => context.go(AppRouter.technicians),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.grayE2E8F0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CustomAssetImage(
                                    path: AppIcons.arrowForward,
                                    width: 14,
                                    height: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'technicians'.tr(),
                                    style: CustomAppFontStyle.medium13.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '/',
                            style: CustomAppFontStyle.regular14.copyWith(
                              color: AppColors.gray71717A,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            state.selectedTechnician?.name ??
                                'technician_details'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (state.detailsStatus == RequestStatusEnum.loading)
                    const TechnicianDetailsShimmer().toSliver()
                  else if (state.detailsStatus == RequestStatusEnum.failure)
                    ErrorPage(
                      errorMessage: state.errMessage ?? 'failed_to_load'.tr(),
                      onPressed: () =>
                          cubit.fetchTechnicianDetails(technicianId),
                    ).toSliver()
                  else if (state.selectedTechnician != null) ...[
                    TechnicianProfileCardSection(
                      technician: state.selectedTechnician!,
                    ).toSliver(),
                    const SizedBox(height: 16).toSliver(),
                    const TechnicianStatsCardsSection().toSliver(),
                    const SizedBox(height: 16).toSliver(),
                    const TechnicianTodayScheduleSection().toSliver(),
                    const SizedBox(height: 16).toSliver(),
                    const TechnicianBookingsSection().toSliver(),
                    const SizedBox(height: 16).toSliver(),
                    TechnicianLeavesSection(technicianId: technicianId)
                        .toSliver(),
                    const SizedBox(height: 24).toSliver(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
