import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_state.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_bookings_section.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_details_shimmer.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_profile_card_section.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_stats_cards_section.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_treatment_plans_section.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/error_page.dart';

class PatientDetailsPage extends StatelessWidget {
  final String patientId;

  const PatientDetailsPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) =>
            getIt<PatientsCubit>()..fetchPatientDetails(patientId),
        child: BlocBuilder<PatientsCubit, PatientsState>(
          builder: (context, state) {
            final cubit = context.read<PatientsCubit>();
            final colors = context.themeColors;

            return RefreshIndicator(
              onRefresh: () async => cubit.fetchPatientDetails(patientId),
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
                            onTap: () => context.go(AppRouter.patients),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colors.cardBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.borderSubtle),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomAssetImage(
                                    path: AppIcons.arrowForward,
                                    width: 14,
                                    height: 14,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'patients'.tr(),
                                    style: CustomAppFontStyle.medium13.copyWith(
                                      color: colors.primary,
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
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            state.selectedPatient?.name ??
                                'patient_details'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (state.detailsStatus == RequestStatusEnum.loading)
                    const SliverToBoxAdapter(child: PatientDetailsShimmer())
                  else if (state.detailsStatus == RequestStatusEnum.failure)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorPage(
                        errorMessage: state.detailsErrMessage ??
                            'failed_to_load'.tr(),
                        onPressed: () => cubit.fetchPatientDetails(patientId),
                      ),
                    )
                  else if (state.selectedPatient != null) ...[
                    const SliverToBoxAdapter(
                      child: PatientProfileCardSection(),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    const SliverToBoxAdapter(
                      child: PatientStatsCardsSection(),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    const SliverToBoxAdapter(
                      child: PatientTreatmentPlansSection(),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    const SliverToBoxAdapter(
                      child: PatientBookingsSection(),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
