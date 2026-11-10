import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../shared/widgets/custom_toast.dart';
import '../../../../shared/widgets/responsive_helper/adaptive_layout.dart';
import '../../data/models/enums/visit_status_enum.dart';
import '../manager/visits_cubit.dart';
import '../manager/visits_state.dart';
import '../widgets/consultation_notes_panel.dart';
import '../widgets/dialogs/finalize_visit_dialog.dart';
import '../widgets/patient_allergy_banner.dart';
import '../widgets/vitals_input_panel.dart';

class DoctorConsultationScreen extends StatefulWidget {
  final String visitId;
  final VisitsCubit? cubit;

  const DoctorConsultationScreen({
    super.key,
    required this.visitId,
    this.cubit,
  });

  @override
  State<DoctorConsultationScreen> createState() =>
      _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
  late final VisitsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ?? getIt<VisitsCubit>();
    _cubit.loadActiveVisit(widget.visitId);
  }

  @override
  void dispose() {
    _cubit.flushDraftOnExit();
    super.dispose();
  }

  void _onSaveDraft() async {
    final success = await _cubit.saveDraft();
    if (success && mounted) {
      CustomToast(
        context: context,
        header: 'visits_draft_saved'.tr(),
      ).showTopToast();
    }
  }

  void _onFinalizeVisit(VisitsState state) async {
    final chiefComplaint = state.formState.chiefComplaint?.trim();
    final diagnosis = state.formState.diagnosis?.trim();

    if (chiefComplaint == null ||
        chiefComplaint.isEmpty ||
        diagnosis == null ||
        diagnosis.isEmpty) {
      if (mounted) {
        CustomToast(
          context: context,
          header: 'visits_finalize_missing_fields'.tr(),
        ).showTopToast();
      }
      return;
    }

    final confirmed = await FinalizeVisitDialog.show(context: context);
    if (confirmed == true && mounted) {
      final success = await _cubit.finalizeVisit();
      if (success && mounted) {
        CustomToast(
          context: context,
          header: 'visits_finalize_success'.tr(),
        ).showTopToast();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<VisitsCubit, VisitsState>(
        bloc: _cubit,
        listenWhen: (prev, curr) =>
            prev.actionStatus != curr.actionStatus ||
            prev.errorMessage != curr.errorMessage,
        listener: (context, state) {
          if (state.actionStatus == RequestStatusEnum.failure &&
              state.errorMessage != null) {
            CustomToast(
              context: context,
              header: state.errorMessage!.tr(),
            ).showTopToast();
          }
        },
        builder: (context, state) {
          final visit = state.activeVisit;
          final isFinalized = visit?.status == VisitStatusEnum.finalized;
          final isActionLoading =
              state.actionStatus == RequestStatusEnum.loading;

          PermissionEvaluator evaluator;
          try {
            evaluator = getIt<PermissionEvaluator>();
          } catch (_) {
            evaluator = _cubit.permissionEvaluator;
          }

          final canRecordVitals = evaluator.can(
            StaffPermissionEnum.recordVitals,
            branchId: visit?.branchId,
          );

          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) {
              _cubit.flushDraftOnExit();
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: SafeArea(
                child: Column(
                  children: [
                    // Top App Bar / Header
                    _buildHeader(
                      context,
                      state,
                      isFinalized,
                      isActionLoading,
                    ),

                    // Main Content
                    Expanded(
                      child: _buildBody(
                        context,
                        state,
                        isFinalized,
                        canRecordVitals,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    VisitsState state,
    bool isFinalized,
    bool isActionLoading,
  ) {
    final visit = state.activeVisit;
    final patientName = visit?.patientName;
    final isDesktop = AdaptiveLayout.isDesktop(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _cubit.flushDraftOnExit();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                try {
                  context.go(AppRouter.visits);
                } catch (_) {}
              }
            },
            icon: const Icon(Icons.arrow_back),
            color: AppColors.darkText,
            tooltip: 'back'.tr(),
          ),
          const SizedBox(width: 8),

          // Title & Patient Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        patientName != null && patientName.isNotEmpty
                            ? '${'visits_consultation_details_title'.tr()} — $patientName'
                            : '${'visits_consultation_details_title'.tr()} (${widget.visitId})',
                        style: CustomAppFontStyle.bold18.copyWith(
                          color: AppColors.darkText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFinalized) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grayf2,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'visits_status_finalized'.tr(),
                          style: CustomAppFontStyle.semiBold12.copyWith(
                            color: AppColors.gray71717A,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Auto-save Indicator
                if (!isFinalized && state.canEditDiagnosis) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (state.isAutoSaving) ...[
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'saving'.tr(),
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ] else if (state.formState.lastSavedAt != null &&
                          !state.formState.isDirty) ...[
                        const Icon(
                          Icons.cloud_done_outlined,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${'visits_auto_saved'.tr()} (${DateFormat('hh:mm a').format(state.formState.lastSavedAt!)})',
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Header Action Buttons
          if (!isFinalized && state.canEditDiagnosis) ...[
            if (isDesktop) ...[
              CustomPushButton(
                height: 38,
                width: 120,
                backgroundColor: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: const BorderSide(color: Color(0xFFE2E8F0)),
                isLoading: isActionLoading,
                onTap: _onSaveDraft,
                child: Center(
                  child: Text(
                    'visits_save_draft'.tr(),
                    style: CustomAppFontStyle.medium13.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            CustomPushButton(
              height: 38,
              width: 130,
              backgroundColor: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              isLoading: isActionLoading,
              onTap: () => _onFinalizeVisit(state),
              child: Center(
                child: Text(
                  'visits_finalize_visit'.tr(),
                  style: CustomAppFontStyle.semiBold13.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    VisitsState state,
    bool isFinalized,
    bool canRecordVitals,
  ) {
    if (state.activeVisitStatus == RequestStatusEnum.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.activeVisitStatus == RequestStatusEnum.failure) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage?.tr() ?? 'visits_load_error'.tr(),
                textAlign: TextAlign.center,
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 16),
              CustomPushButton(
                height: 36,
                width: 100,
                backgroundColor: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                onTap: () => _cubit.loadActiveVisit(widget.visitId),
                child: Center(
                  child: Text(
                    'refresh'.tr(),
                    style: CustomAppFontStyle.medium13.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isDesktop = AdaptiveLayout.isDesktop(context);

    final allergyWidget = PatientAllergyBanner(
      allergies: state.patientAllergies,
    );

    final chronicDiseasesWidget = (state.canViewNotes &&
            state.patientChronicDiseases.isNotEmpty)
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Blue 50
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFBFDBFE), // Blue 200
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.healing_outlined,
                      color: Color(0xFF1D4ED8), // Blue 700
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'visits_chronic_diseases_title'.tr(),
                      style: CustomAppFontStyle.bold14.copyWith(
                        color: const Color(0xFF1E40AF), // Blue 800
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: state.patientChronicDiseases.map((disease) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE), // Blue 100
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF93C5FD), // Blue 300
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        disease,
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: const Color(0xFF1E3A8A), // Blue 900
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final vitalsSection = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Icon(
                Icons.monitor_heart_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              Text(
                'visits_vitals_title'.tr(),
                style: CustomAppFontStyle.bold16.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              if (isFinalized || !canRecordVitals)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grayf2,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'visits_finalized_read_only'.tr(),
                    style: CustomAppFontStyle.medium12.copyWith(
                      color: AppColors.gray,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          VitalsInputPanel(
            vitals: state.formState.vitals,
            isReadOnly: isFinalized || !canRecordVitals,
            onVitalsChanged: (v) => _cubit.updateVitals(v),
          ),
        ],
      ),
    );

    final lockedBanner = isFinalized
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB), // Amber 50
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFDE68A), // Amber 200
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: Color(0xFFB45309), // Amber 700
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'visits_locked_notice'.tr(),
                    style: CustomAppFontStyle.semiBold14.copyWith(
                      color: const Color(0xFF92400E), // Amber 800
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final clinicalNotesSection = state.canViewNotes
        ? ConsultationNotesPanel(
            formState: state.formState,
            isReadOnly: isFinalized || !state.canEditDiagnosis,
            onChiefComplaintChanged: (val) =>
                _cubit.updateChiefComplaint(val),
            onMedicalHistoryChanged: (val) =>
                _cubit.updateMedicalHistory(val),
            onPhysicalExamChanged: (val) =>
                _cubit.updatePhysicalExam(val),
            onDiagnosisChanged: (val) => _cubit.updateDiagnosis(val),
            onTreatmentPlanChanged: (val) =>
                _cubit.updateTreatmentPlan(val),
            onFollowUpNotesChanged: (val) =>
                _cubit.updateFollowUpNotes(val),
            onFollowUpDaysChanged: (val) =>
                _cubit.updateFollowUpDays(val),
          )
        : const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isFinalized) ...[
            lockedBanner,
            const SizedBox(height: 16),
          ],
          if (state.patientAllergies.isNotEmpty) ...[
            allergyWidget,
            const SizedBox(height: 16),
          ],
          if (state.canViewNotes && state.patientChronicDiseases.isNotEmpty) ...[
            chronicDiseasesWidget,
            const SizedBox(height: 16),
          ],
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Right Column in RTL / Left in LTR: Vitals
                Expanded(
                  flex: 2,
                  child: vitalsSection,
                ),
                const SizedBox(width: 20),
                // Left Column in RTL / Right in LTR: Clinical Notes
                if (state.canViewNotes)
                  Expanded(
                    flex: 3,
                    child: clinicalNotesSection,
                  ),
              ],
            )
          else ...[
            vitalsSection,
            if (state.canViewNotes) ...[
              const SizedBox(height: 16),
              clinicalNotesSection,
            ],
          ],
        ],
      ),
    );
  }
}
