import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/cubits/session_cubit.dart';
import '../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/custom_toast.dart';
import '../../data/models/consultation_queue_item_model.dart';
import '../manager/visits_cubit.dart';
import '../manager/visits_state.dart';
import '../widgets/adaptive_visits_view.dart';
import '../widgets/dialogs/record_vitals_dialog.dart';
import '../widgets/visits_filter_bar.dart';
import '../widgets/visits_shimmer.dart';

class VisitsPage extends StatefulWidget {
  final VisitsCubit? visitsCubit;

  const VisitsPage({
    super.key,
    this.visitsCubit,
  });

  @override
  State<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends State<VisitsPage> {
  late final VisitsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.visitsCubit ?? getIt<VisitsCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.loadDoctorQueue();
    });
  }

  void _handleStartConsultation(ConsultationQueueItemModel item) async {
    final visit = await _cubit.startConsultation(item);
    if (!mounted) return;
    if (visit != null && visit.id != null) {
      context.go('${AppRouter.visits}/${visit.id}');
    } else if (_cubit.state.errorMessage != null) {
      CustomToast(
        context: context,
        header: _cubit.state.errorMessage!.tr(),
      ).showTopToast();
    }
  }

  void _handleContinueConsultation(ConsultationQueueItemModel item) {
    final visitId = item.visit?.id ?? item.booking?.id ?? '';
    if (visitId.isNotEmpty) {
      context.go('${AppRouter.visits}/$visitId');
    }
  }

  void _handleViewConsultation(ConsultationQueueItemModel item) {
    final visitId = item.visit?.id ?? item.booking?.id ?? '';
    if (visitId.isNotEmpty) {
      context.go('${AppRouter.visits}/$visitId');
    }
  }

  void _handleRecordVitals(ConsultationQueueItemModel item) {
    RecordVitalsDialog.show(
      context: context,
      item: item,
      visitsCubit: _cubit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final sessionCubit = getIt.isRegistered<SessionCubit>()
        ? getIt<SessionCubit>()
        : (context.read<SessionCubit?>());

    final evaluator = sessionCubit?.permissionEvaluator ??
        _cubit.permissionEvaluator;

    final currentUser = evaluator.userProvider.currentUser;
    final isAdminOrOwner = currentUser?.isOwner == true ||
        (currentUser?.isPracticingDoctor != true);

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<VisitsCubit, VisitsState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: colors.scaffoldBackground,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Header: Title & Subtitle ─────────────────────
                    Text(
                      'visits_page_title'.tr(),
                      style: CustomAppFontStyle.bold24.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'visits_page_subtitle'.tr(),
                      style: CustomAppFontStyle.regular14.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Filter Bar ───────────────────────────────────
                    VisitsFilterBar(
                      cubit: _cubit,
                      state: state,
                      isAdminOrOwner: isAdminOrOwner,
                    ),
                    const SizedBox(height: 20),

                    // ─── Queue Body: Shimmer / Failure / Table ─────────
                    if (state.queueStatus == RequestStatusEnum.loading &&
                        state.queue.isEmpty) ...[
                      const VisitsShimmer(),
                    ] else if (state.queueStatus == RequestStatusEnum.failure &&
                        state.queue.isEmpty) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFEF4444),
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                (state.errorMessage ?? 'visits_load_error').tr(),
                                style: CustomAppFontStyle.medium14.copyWith(
                                  color: AppColors.gray,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => _cubit.loadDoctorQueue(),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: Text('retry'.tr()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      AdaptiveVisitsView(
                        items: state.queue,
                        evaluator: evaluator,
                        isLoading:
                            state.actionStatus == RequestStatusEnum.loading,
                        onStartConsultation: _handleStartConsultation,
                        onContinueConsultation: _handleContinueConsultation,
                        onRecordVitals: _handleRecordVitals,
                        onViewConsultation: _handleViewConsultation,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
