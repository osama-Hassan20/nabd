import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import '../../../data/models/consultation_queue_item_model.dart';
import '../../manager/visits_cubit.dart';
import '../../manager/visits_state.dart';
import '../patient_allergy_banner.dart';
import '../vitals_input_panel.dart';

class RecordVitalsDialog extends StatelessWidget {
  final ConsultationQueueItemModel item;
  final VisitsCubit? visitsCubit;

  const RecordVitalsDialog({
    super.key,
    required this.item,
    this.visitsCubit,
  });

  static Future<bool?> show({
    required BuildContext context,
    required ConsultationQueueItemModel item,
    VisitsCubit? visitsCubit,
  }) {
    final cubit = visitsCubit ??
        (context.read<VisitsCubit?>() ?? getIt<VisitsCubit>());

    cubit.initRecordVitals(item);

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) => BlocProvider.value(
        value: cubit,
        child: RecordVitalsDialog(
          item: item,
          visitsCubit: cubit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = visitsCubit ?? context.read<VisitsCubit>();
    final booking = item.booking;
    final patientName = booking?.patientName ?? '—';
    final queueNumber = booking?.queueNumber != null
        ? '#${booking!.queueNumber}'
        : '—';
    final doctorName = booking?.doctorName ?? '—';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: BlocConsumer<VisitsCubit, VisitsState>(
          bloc: cubit,
          listenWhen: (prev, curr) => prev.actionStatus != curr.actionStatus,
          listener: (ctx, state) {
            if (state.actionStatus == RequestStatusEnum.success) {
              ctx.pop(true);
              CustomToast(
                context: ctx,
                header: 'visits_vitals_saved'.tr(),
              ).showTopToast();
            } else if (state.actionStatus == RequestStatusEnum.failure) {
              final errKey = state.errorMessage ?? 'visits_vitals_error';
              CustomToast(
                context: ctx,
                header: errKey.tr(),
              ).showTopToast();
            }
          },
          builder: (ctx, state) {
            final isLoading = state.actionStatus == RequestStatusEnum.loading;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Dialog Header ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.monitor_heart_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'visits_record_vitals'.tr(),
                              style: CustomAppFontStyle.bold16.copyWith(
                                color: AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$patientName ($queueNumber) — $doctorName',
                              style: CustomAppFontStyle.medium12.copyWith(
                                color: AppColors.gray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => ctx.pop(false),
                        icon: const Icon(Icons.close, size: 20),
                        color: AppColors.gray,
                        tooltip: 'cancel'.tr(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // ─── Scrollable Form Content ───────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Patient Allergies Banner
                        PatientAllergyBanner(
                          allergies: state.patientAllergies,
                        ),
                        if (state.patientAllergies.isNotEmpty)
                          const SizedBox(height: 16),

                        // Vitals Input Fields (Cubit-driven)
                        VitalsInputPanel(
                          vitals: state.formState.vitals,
                          onVitalsChanged: (newVitals) {
                            cubit.updateVitals(newVitals);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // ─── Actions Footer ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoading ? null : () => ctx.pop(false),
                        child: Text(
                          'cancel'.tr(),
                          style: CustomAppFontStyle.medium14.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CustomPushButton(
                        isLoading: isLoading,
                        onTap: isLoading
                            ? null
                            : () => cubit.saveRecordedVitals(item),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        backgroundColor: AppColors.primary,
                        child: Text(
                          'visits_save_draft'.tr(),
                          style: CustomAppFontStyle.bold14.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
