import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/features/bookings/presentation/widgets/action_dialogs/change_booking_status_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/action_dialogs/delete_booking_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/action_dialogs/reassign_technician_dialog.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
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
}
