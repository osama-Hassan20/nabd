import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/features/bookings/presentation/widgets/action_dialogs/change_booking_status_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/action_dialogs/delete_booking_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/action_dialogs/reassign_technician_dialog.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/remove_discount_params.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class BookingActionDialogs {
  /// Helper to resolve BookingsCubit safely
  static BookingsCubit _resolveCubit(
    BuildContext context,
    BookingsCubit? passedCubit,
  ) {
    if (passedCubit != null) return passedCubit;
    try {
      return context.read<BookingsCubit>();
    } catch (_) {
      return getIt<BookingsCubit>();
    }
  }

  /// 1. Change Status Dialog (100% Cubit-driven)
  static Future<bool?> showChangeStatusDialog({
    required BuildContext context,
    required BookingModel booking,
    BookingsCubit? bookingsCubit,
    Future<bool> Function(BookingStatusEnum status)? onConfirm,
  }) {
    final cubit = _resolveCubit(context, bookingsCubit);
    cubit.initChangeStatusDialog(
      booking.status ?? BookingStatusEnum.scheduled,
      booking: booking,
    );

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) => BlocProvider.value(
        value: cubit,
        child: BlocConsumer<BookingsCubit, BookingsState>(
          listenWhen: (prev, curr) => prev.actionStatus != curr.actionStatus,
          listener: (ctx, state) {
            if (state.actionStatus == RequestStatusEnum.success) {
              ctx.pop(true);
              CustomToast(
                context: ctx,
                header: (state.actionSuccessMessage ??
                        'status_updated_successfully')
                    .tr(),
              ).showTopToast();
            } else if (state.actionStatus == RequestStatusEnum.failure) {
              CustomToast(
                context: ctx,
                header: state.errMessage ?? 'error_occurred'.tr(),
              ).showErrorToast();
            }
          },
          builder: (ctx, state) => ChangeBookingStatusDialog(
            selectedStatus: state.dialogStatus ??
                booking.status ??
                BookingStatusEnum.scheduled,
            isLoading: state.actionStatus == RequestStatusEnum.loading,
            onSelectStatus: (status) => cubit.selectStatusToChange(status),
            postponeDate: state.dialogPostponeDate,
            postponeTime: state.dialogPostponeTime,
            postponeReason: state.dialogPostponeReason,
            onPickPostponeDate: cubit.updateDialogPostponeDate,
            onPickPostponeTime: cubit.updateDialogPostponeTime,
            onPostponeReasonChanged: cubit.updateDialogPostponeReason,
            cancelReason: state.dialogCancelReason,
            cancelledBy: state.dialogCancelledBy,
            onCancelReasonChanged: cubit.updateDialogCancelReason,
            onCancelledByChanged: cubit.updateDialogCancelledBy,
            onConfirm: () {
              final selected = state.dialogStatus ??
                  booking.status ??
                  BookingStatusEnum.scheduled;

              if (selected == BookingStatusEnum.postponed) {
                if (state.dialogPostponeDate == null) {
                  CustomToast(
                    context: ctx,
                    header: 'please_select_rescheduled_date'.tr(),
                  ).showErrorToast();
                  return;
                }
              }

              if (onConfirm != null) {
                onConfirm(selected);
              } else {
                DateTime? rescheduledTo;
                if (selected == BookingStatusEnum.postponed &&
                    state.dialogPostponeDate != null) {
                  final pDate = state.dialogPostponeDate!;
                  final pTime = state.dialogPostponeTime ?? '09:00';
                  final parts = pTime.split(':');
                  final hour = int.tryParse(parts.first) ?? 9;
                  final min =
                      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
                  rescheduledTo =
                      DateTime(pDate.year, pDate.month, pDate.day, hour, min);
                }

                cubit.changeBookingStatus(
                  booking.id ?? '',
                  selected,
                  rescheduledTo: rescheduledTo,
                  postponeReason: state.dialogPostponeReason,
                  cancelReason: state.dialogCancelReason,
                  cancelledBy: state.dialogCancelledBy,
                  cancelledAt: selected == BookingStatusEnum.cancelled
                      ? CairoTimeHelper.now()
                      : null,
                  arrivalTime: selected == BookingStatusEnum.waiting
                      ? (booking.arrivalTime ?? CairoTimeHelper.now())
                      : null,
                );
              }
            },
          ),
        ),
      ),
    );
  }

  /// 2. Reassign Technician Dialog (100% Cubit-driven)
  static Future<bool?> showReassignTechnicianDialog({
    required BuildContext context,
    required BookingModel booking,
    BookingsCubit? bookingsCubit,
    Future<bool> Function(
      List<String> technicianIds,
      List<String> technicianNames,
    )?
    onConfirm,
  }) {
    final cubit = _resolveCubit(context, bookingsCubit);
    final initialIds = booking.technicianIds.isNotEmpty
        ? booking.technicianIds
        : (booking.technicianId != null ? [booking.technicianId!] : <String>[]);

    cubit.initReassignTechniciansDialog(initialIds);

    final currentDocId = booking.technicianId ??
        (booking.technicianIds.isNotEmpty ? booking.technicianIds.first : null);

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) => BlocProvider.value(
        value: cubit,
        child: BlocConsumer<BookingsCubit, BookingsState>(
          listenWhen: (prev, curr) => prev.actionStatus != curr.actionStatus,
          listener: (ctx, state) {
            if (state.actionStatus == RequestStatusEnum.success) {
              ctx.pop(true);
              CustomToast(
                context: ctx,
                header: (state.actionSuccessMessage ??
                        'technician_reassigned_successfully')
                    .tr(),
              ).showTopToast();
            } else if (state.actionStatus == RequestStatusEnum.failure) {
              CustomToast(
                context: ctx,
                header: state.errMessage ?? 'error_occurred'.tr(),
              ).showErrorToast();
            }
          },
          builder: (ctx, state) => ReassignTechnicianDialog(
            technicians: state.technicians,
            selectedIds: state.dialogTechnicianIds,
            currentDoctorId: currentDocId,
            isLoading: state.actionStatus == RequestStatusEnum.loading,
            onToggleTechnician: (id) => cubit.toggleReassignTechnician(id),
            onConfirm: () {
              final selected = state.dialogTechnicianIds;
              if (selected.isEmpty) {
                CustomToast(
                  context: ctx,
                  header: 'select_at_least_one_technician'.tr(),
                ).showErrorToast();
                return;
              }

              final selectedIds = selected.toList();
              final selectedNames = state.technicians
                  .where((t) => selected.contains(t.id))
                  .map((t) => t.name)
                  .toList();

              if (onConfirm != null) {
                onConfirm(selectedIds, selectedNames);
              } else {
                cubit.reassignTechnicians(
                  booking.id ?? '',
                  selectedIds,
                  selectedNames,
                );
              }
            },
          ),
        ),
      ),
    );
  }

  /// 3. Delete Confirmation Dialog (100% Cubit-driven)
  static Future<bool?> showDeleteDialog({
    required BuildContext context,
    required BookingModel booking,
    BookingsCubit? bookingsCubit,
    Future<bool> Function()? onConfirm,
  }) {
    final cubit = _resolveCubit(context, bookingsCubit);

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) => BlocProvider.value(
        value: cubit,
        child: BlocConsumer<BookingsCubit, BookingsState>(
          listenWhen: (prev, curr) => prev.actionStatus != curr.actionStatus,
          listener: (ctx, state) {
            if (state.actionStatus == RequestStatusEnum.success) {
              ctx.pop(true);
              CustomToast(
                context: ctx,
                header: (state.actionSuccessMessage ??
                        'booking_deleted_successfully')
                    .tr(),
              ).showTopToast();
            } else if (state.actionStatus == RequestStatusEnum.failure) {
              CustomToast(
                context: ctx,
                header: state.errMessage ?? 'error_occurred'.tr(),
              ).showErrorToast();
            }
          },
          builder: (ctx, state) => DeleteBookingDialog(
            isLoading: state.actionStatus == RequestStatusEnum.loading,
            onDelete: () {
              if (onConfirm != null) {
                onConfirm();
              } else {
                cubit.deleteBooking(booking.id ?? '');
              }
            },
          ),
        ),
      ),
    );
  }

  /// 4. Remove Discount Dialog (100% Cubit-driven)
  static Future<bool?> showRemoveDiscountDialog({
    required BuildContext context,
    required BookingModel booking,
    BookingsCubit? bookingsCubit,
  }) {
    final cubit = _resolveCubit(context, bookingsCubit);
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) => BlocProvider.value(
        value: cubit,
        child: BlocConsumer<BookingsCubit, BookingsState>(
          listenWhen: (prev, curr) => prev.actionStatus != curr.actionStatus,
          listener: (ctx, state) {
            if (state.actionStatus == RequestStatusEnum.success) {
              Navigator.of(ctx).pop(true);
              CustomToast(
                context: ctx,
                header: 'disc_removed_success'.tr(),
              ).showTopToast();
            } else if (state.actionStatus == RequestStatusEnum.failure) {
              CustomToast(
                context: ctx,
                header: state.errMessage ?? 'error_occurred'.tr(),
              ).showErrorToast();
            }
          },
          builder: (ctx, state) {
            final colors = ctx.themeColors;
            final isLoading = state.actionStatus == RequestStatusEnum.loading;
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppColors.red1A,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.error,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'disc_remove_confirm_title'.tr(),
                                style: CustomAppFontStyle.bold16.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'disc_remove_confirm_body'.tr(),
                          style: CustomAppFontStyle.regular13.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomTextFormField(
                          controller: controller,
                          headerText: 'disc_remove_reason_label'.tr(),
                          hintText: 'disc_remove_reason_hint'.tr(),
                          maxLine: 2,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'disc_validation_reason_required'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.of(ctx).pop(false),
                              child: Text(
                                'cancel'.tr(),
                                style: CustomAppFontStyle.medium14.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                            CustomPushButton(
                              isLoading: isLoading,
                              backgroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                if (!formKey.currentState!.validate()) return;
                                cubit.removeDiscount(
                                  RemoveDiscountParams(
                                    bookingId: booking.id,
                                    reason: controller.text.trim(),
                                  ),
                                );
                              },
                              child: Text(
                                'disc_confirm_remove'.tr(),
                                style: CustomAppFontStyle.medium14.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
