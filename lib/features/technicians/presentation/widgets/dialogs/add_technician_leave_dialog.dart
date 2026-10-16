import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/date_time_extentision.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/technicians/presentation/cubit/technicians_cubit.dart';
import 'package:eyadty/features/technicians/presentation/cubit/technicians_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class AddTechnicianLeaveDialog extends StatefulWidget {
  final String technicianId;
  final bool isFullScreen;
  final TechniciansCubit techniciansCubit;

  const AddTechnicianLeaveDialog({
    super.key,
    required this.technicianId,
    this.isFullScreen = false,
    required this.techniciansCubit,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String technicianId,
    TechniciansCubit? techniciansCubit,
  }) {
    TechniciansCubit? cubit = techniciansCubit;
    if (cubit == null) {
      try {
        cubit = context.read<TechniciansCubit>();
      } catch (_) {
        cubit = getIt<TechniciansCubit>();
      }
    }
    cubit.initLeaveForm(technicianId);

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        final child = BlocProvider.value(
          value: cubit!,
          child: AddTechnicianLeaveDialog(
            technicianId: technicianId,
            isFullScreen: isMobile,
            techniciansCubit: cubit,
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
  State<AddTechnicianLeaveDialog> createState() =>
      _AddTechnicianLeaveDialogState();
}

class _AddTechnicianLeaveDialogState extends State<AddTechnicianLeaveDialog> {
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

  Future<void> _pickStartDate(
    BuildContext context,
    DateTime currentStart,
    DateTime currentEnd,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      final updatedEnd = currentEnd.isBefore(picked) ? picked : currentEnd;
      widget.techniciansCubit.updateLeaveFormDates(
        startDate: picked,
        endDate: updatedEnd,
      );
    }
  }

  Future<void> _pickEndDate(
    BuildContext context,
    DateTime currentStart,
    DateTime currentEnd,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          currentEnd.isBefore(currentStart) ? currentStart : currentEnd,
      firstDate: currentStart,
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      widget.techniciansCubit.updateLeaveFormDates(
        startDate: currentStart,
        endDate: picked,
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final success = await widget.techniciansCubit.saveLeave(
      reason: _reasonController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      final msg = widget.techniciansCubit.state.successMessage ??
          'leave_added_successfully';
      CustomToast(context: context, header: msg.tr()).showTopToast();
      Navigator.of(context).pop(true);
    } else {
      final err = widget.techniciansCubit.state.errMessage;
      CustomToast(
        context: context,
        header: err != null ? err.tr() : 'failed_to_load'.tr(),
      ).showErrorToast();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TechniciansCubit, TechniciansState>(
      bloc: widget.techniciansCubit,
      builder: (context, state) {
        final isLoading = state.actionStatus == RequestStatusEnum.loading;
        final form = state.leaveFormState;
        final startDate = form?.startDate ?? DateTime.now();
        final endDate = form?.endDate ?? DateTime.now();

        final content = Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(widget.isFullScreen ? 0 : 16),
            border: widget.isFullScreen
                ? null
                : Border.all(color: AppColors.grayE2E8F0),
          ),
          child: Column(
            mainAxisSize:
                widget.isFullScreen ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateTile(
                                label: 'start_date'.tr(),
                                date: startDate,
                                onTap: () => _pickStartDate(
                                  context,
                                  startDate,
                                  endDate,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildDateTile(
                                label: 'end_date'.tr(),
                                date: endDate,
                                onTap: () => _pickEndDate(
                                  context,
                                  startDate,
                                  endDate,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          controller: _reasonController,
                          headerText: 'leave_reason'.tr(),
                          hintText: 'leave_reason_hint'.tr(),
                          isRequired: true,
                          maxLine: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'field_required'.tr();
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              _buildFooter(context, isLoading),
            ],
          ),
        );

        if (widget.isFullScreen) {
          return Scaffold(backgroundColor: AppColors.white, body: content);
        }

        return content;
      },
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CustomAppFontStyle.semiBold14.copyWith(
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.grayE2E8F0),
            ),
            child: Row(
              children: [
                const CustomAssetImage(
                  path: AppIcons.calendar,
                  width: 18,
                  height: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date.toCustomFormat(),
                    style: CustomAppFontStyle.medium14.copyWith(
                      color: AppColors.darkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const CustomAssetImage(
              path: AppIcons.cancelledBooking,
              width: 20,
              height: 20,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'add_leave'.tr(),
              style: CustomAppFontStyle.semiBold18.copyWith(
                color: AppColors.darkText,
              ),
            ),
          ),
          const CloseButton(),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: CustomPushButton(
              height: 44,
              backgroundColor: AppColors.grayf2,
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: Text(
                  'cancel'.tr(),
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.grayMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: CustomPushButton(
              height: 44,
              backgroundColor: AppColors.warning,
              isLoading: isLoading,
              borderRadius: BorderRadius.circular(8),
              onTap: isLoading ? null : _handleSubmit,
              child: Center(
                child: Text(
                  'save'.tr(),
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
