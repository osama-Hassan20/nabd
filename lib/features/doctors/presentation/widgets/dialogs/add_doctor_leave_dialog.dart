import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class AddDoctorLeaveDialog extends StatefulWidget {
  final String doctorId;
  final bool isFullScreen;
  final DoctorsCubit doctorsCubit;

  const AddDoctorLeaveDialog({
    super.key,
    required this.doctorId,
    this.isFullScreen = false,
    required this.doctorsCubit,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String doctorId,
    DoctorsCubit? doctorsCubit,
  }) {
    DoctorsCubit? cubit = doctorsCubit;
    if (cubit == null) {
      try {
        cubit = context.read<DoctorsCubit>();
      } catch (_) {
        cubit = getIt<DoctorsCubit>();
      }
    }
    cubit.initLeaveForm(doctorId);

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        final child = BlocProvider.value(
          value: cubit!,
          child: AddDoctorLeaveDialog(
            doctorId: doctorId,
            isFullScreen: isMobile,
            doctorsCubit: cubit,
          ),
        );

        if (isMobile) {
          return Dialog.fullscreen(child: child);
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AddDoctorLeaveDialog> createState() => _AddDoctorLeaveDialogState();
}

class _AddDoctorLeaveDialogState extends State<AddDoctorLeaveDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DoctorsCubit, DoctorsState>(
      listenWhen: (prev, curr) =>
          prev.actionStatus != curr.actionStatus ||
          prev.successMessage != curr.successMessage ||
          prev.errMessage != curr.errMessage,
      listener: (context, state) {
        if (state.actionStatus == RequestStatusEnum.success) {
          CustomToast(
            context: context,
            header: (state.successMessage ?? 'leave_added_successfully').tr(),
          ).showTopToast();
          context.pop(true);
        } else if (state.actionStatus == RequestStatusEnum.failure) {
          final msg = state.errMessage != null
              ? state.errMessage!.tr()
              : 'error_occurred'.tr();
          CustomToast(
            context: context,
            header: msg,
          ).showErrorToast();
        }
      },
      builder: (context, state) {
        final form = state.leaveFormState;
        final cubit = context.read<DoctorsCubit>();
        final hasConflicts = form?.requiresConflictConfirmation == true &&
            (form?.conflictingBookingsCount ?? 0) > 0;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(widget.isFullScreen ? 0 : 16),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const Divider(height: 1, color: AppColors.grayE2E8F0),
                if (form == null)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (hasConflicts) ...[
                            _buildConflictAlert(
                              context,
                              cubit,
                              form.conflictingBookingsCount!,
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateSelector(
                                  context: context,
                                  label: 'start_date'.tr(),
                                  date: form.startDate,
                                  onTap: () => _pickStartDate(
                                    context,
                                    form.startDate,
                                    cubit,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDateSelector(
                                  context: context,
                                  label: 'end_date'.tr(),
                                  date: form.endDate,
                                  onTap: () => _pickEndDate(
                                    context,
                                    form.startDate,
                                    form.endDate,
                                    cubit,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            controller: _reasonController,
                            headerText: 'reason'.tr(),
                            hintText: 'leave_reason_hint'.tr(),
                            maxLine: 3,
                          ),
                          if (form.validationError != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              form.validationError!.tr(),
                              style: CustomAppFontStyle.regular12.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                const Divider(height: 1, color: AppColors.grayE2E8F0),
                _buildFooter(context, cubit, state, hasConflicts),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.yellowLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const CustomAssetImage(
              path: AppIcons.calendar,
              width: 18,
              height: 18,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'add_leave'.tr(),
            style: CustomAppFontStyle.semiBold16.copyWith(
              color: AppColors.darkText,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, color: AppColors.gray71717A),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictAlert(
    BuildContext context,
    DoctorsCubit cubit,
    int conflictingCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'active_bookings_conflict_alert'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'conflicting_bookings_warning'.tr(
              namedArgs: {'count': '$conflictingCount'},
            ),
            style: CustomAppFontStyle.regular13.copyWith(
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector({
    required BuildContext context,
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CustomAppFontStyle.medium13.copyWith(
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.grayf6,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grayE2E8F0),
            ),
            child: Row(
              children: [
                const CustomAssetImage(
                  path: AppIcons.calendar,
                  width: 16,
                  height: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    BookingTimeFormatter.formatCompactDate(date, context),
                    style: CustomAppFontStyle.medium14.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(
    BuildContext context,
    DoctorsCubit cubit,
    DoctorsState state,
    bool hasConflicts,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomPushButton(
            height: 42,
            width: 100,
            backgroundColor: AppColors.grayf2,
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.pop(),
            child: Text(
              'cancel'.tr(),
              style: CustomAppFontStyle.medium14.copyWith(
                color: AppColors.darkText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CustomPushButton(
            height: 42,
            backgroundColor: hasConflicts ? AppColors.error : AppColors.primary,
            isLoading: state.actionStatus == RequestStatusEnum.loading,
            borderRadius: BorderRadius.circular(8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () {
              cubit.updateLeaveReason(_reasonController.text.trim());
              cubit.saveLeave(force: hasConflicts);
            },
            child: Text(
              hasConflicts
                  ? 'confirm_leave_with_conflicts'.tr()
                  : 'save'.tr(),
              style: CustomAppFontStyle.semiBold14.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStartDate(
    BuildContext context,
    DateTime currentStart,
    DoctorsCubit cubit,
  ) async {
    final nowCairo = CairoTimeHelper.now();
    final today = DateTime(nowCairo.year, nowCairo.month, nowCairo.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: currentStart.isBefore(today) ? today : currentStart,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked != null) {
      cubit.updateLeaveStartDate(picked);
    }
  }

  Future<void> _pickEndDate(
    BuildContext context,
    DateTime currentStart,
    DateTime currentEnd,
    DoctorsCubit cubit,
  ) async {
    final firstAllowed = currentStart;

    final picked = await showDatePicker(
      context: context,
      initialDate: currentEnd.isBefore(firstAllowed) ? firstAllowed : currentEnd,
      firstDate: firstAllowed,
      lastDate: currentStart.add(const Duration(days: 365)),
    );

    if (picked != null) {
      cubit.updateLeaveEndDate(picked);
    }
  }
}
