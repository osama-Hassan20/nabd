import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/features/specialty_records/domain/specialty_module_registry.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_state.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_active_medications_section.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_bookings_section.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_clinical_alerts_banner.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_consultations_history_section.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_details_shimmer.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_emr_tab_bar.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_lab_radiology_section.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_profile_card_section.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_stats_cards_section.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_surgical_history_section.dart';
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
                    // 1. Patient Profile Info Card
                    const SliverToBoxAdapter(
                      child: PatientProfileCardSection(),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),

                    // 2. High-Priority Clinical Alert Banner (Allergies, Chronic Diseases, Active Meds)
                    SliverToBoxAdapter(
                      child: PatientClinicalAlertsBanner(
                        patient: state.selectedPatient!,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // 3. Overall Patient Financial & Visit Statistics
                    const SliverToBoxAdapter(
                      child: PatientStatsCardsSection(),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // 4. Unified EMR Navigation Tabs Bar (الكشوفات والروشتات، الأدوية، التحاليل والأشعة، العمليات، المتابعات التخصصية، باقات العلاج، المواعيد)
                    SliverToBoxAdapter(
                      child: PatientEmrTabBar(
                        activeIndex: state.activeDetailsTab,
                        onTabSelected: (index) => cubit.changeDetailsTab(index),
                        consultationsCount: state.patientVisits.length,
                        activeMedsCount:
                            state.selectedPatient?.activeMedications?.length ?? 0,
                        labsCount:
                            state.selectedPatient?.labAndRadiology?.length ?? 0,
                        surgeriesCount:
                            state.selectedPatient?.surgicalHistory?.length ?? 0,
                        specialtyCount:
                            (state.selectedPatient?.eyeExams?.length ?? 0) +
                            (state.selectedPatient?.beforeAfterGallery?.length ?? 0),
                        treatmentPlansCount:
                            state.selectedPatient?.treatmentPlans?.length ?? 0,
                        bookingsCount: state.patientBookings.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // 5. Active Tab View Content
                    SliverToBoxAdapter(
                      child: _buildActiveTabContent(
                        state.activeDetailsTab,
                        state.selectedPatient!,
                      ),
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

  Widget _buildActiveTabContent(int activeTab, PatientModel patient) {
    return switch (activeTab) {
      0 => PatientConsultationsHistorySection(patient: patient),
      1 => PatientActiveMedicationsSection(patient: patient),
      2 => PatientLabRadiologySection(patient: patient),
      3 => const PatientSurgicalHistorySection(),
      4 => _PatientSpecialtyRegistryTab(patient: patient),
      5 => const PatientTreatmentPlansSection(),
      6 => const PatientBookingsSection(),
      _ => PatientConsultationsHistorySection(patient: patient),
    };
  }
}

class _PatientSpecialtyRegistryTab extends StatefulWidget {
  final PatientModel patient;
  const _PatientSpecialtyRegistryTab({required this.patient});

  @override
  State<_PatientSpecialtyRegistryTab> createState() =>
      _PatientSpecialtyRegistryTabState();
}

class _PatientSpecialtyRegistryTabState
    extends State<_PatientSpecialtyRegistryTab> {
  MedicalSpecialty _selected = MedicalSpecialty.generalPractice;

  @override
  Widget build(BuildContext context) {
    final module = SpecialtyModuleRegistry.forSpecialty(_selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MedicalSpecialty.values.map((spec) {
            return ChoiceChip(
              avatar: Icon(spec.icon, size: 16),
              label: Text(spec.labelKey.tr()),
              selected: _selected == spec,
              onSelected: (_) => setState(() => _selected = spec),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        module.buildPatientTab(widget.patient),
      ],
    );
  }
}
