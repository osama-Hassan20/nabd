import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/sliver_extentions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/error_page.dart';

import '../widgets/doctor_details_sections/doctor_bookings_section.dart';
import '../widgets/doctor_details_sections/doctor_details_shimmer.dart';
import '../widgets/doctor_details_sections/doctor_leaves_section.dart';
import '../widgets/doctor_details_sections/doctor_profile_card_section.dart';
import '../widgets/doctor_details_sections/doctor_schedule_card_section.dart';
import '../widgets/doctor_details_sections/doctor_stats_cards_section.dart';
import '../widgets/doctor_details_sections/doctor_today_schedule_section.dart';

class DoctorDetailsPage extends StatelessWidget {
  final String doctorId;

  const DoctorDetailsPage({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) =>
            getIt<DoctorsCubit>()..fetchDoctorDetails(doctorId),
        child: BlocBuilder<DoctorsCubit, DoctorsState>(
          builder: (context, state) {
            final cubit = context.read<DoctorsCubit>();

            return RefreshIndicator(
              onRefresh: () async => cubit.fetchDoctorDetails(doctorId),
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
                            onTap: () => context.go(AppRouter.doctors),
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
                                    'doctors'.tr(),
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
                            state.selectedDoctor?.name ??
                                'doctor_details'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (state.detailsStatus == RequestStatusEnum.loading)
                    const DoctorDetailsShimmer().toSliver()
                  else if (state.detailsStatus == RequestStatusEnum.failure)
                    ErrorPage(
                      errorMessage: state.errMessage ?? 'failed_to_load'.tr(),
                      onPressed: () =>
                          cubit.fetchDoctorDetails(doctorId),
                    ).toSliver()
                  else if (state.selectedDoctor != null) ...[
                    DoctorProfileCardSection(
                      doctor: state.selectedDoctor!,
                    ).toSliver(),
                    const SizedBox(height: 16).toSliver(),
                    DoctorScheduleCardSection(
                      doctor: state.selectedDoctor!,
                    ).toSliver(),
                    const SizedBox(height: 16).toSliver(),
                    const DoctorStatsCardsSection().toSliver(),
                    const SizedBox(height: 16).toSliver(),
                    const DoctorTodayScheduleSection().toSliver(),
                    const SizedBox(height: 16).toSliver(),
                    const DoctorBookingsSection().toSliver(),
                    const SizedBox(height: 16).toSliver(),
                    DoctorLeavesSection(doctorId: doctorId)
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

