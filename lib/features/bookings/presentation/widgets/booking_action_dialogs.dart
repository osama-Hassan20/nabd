import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purexo/core/dependency_injection/dependency_injection.dart';
import 'package:purexo/core/utils/enums/request_status_enum.dart';
import 'package:purexo/features/bookings/data/models/booking_model.dart';
import 'package:purexo/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:purexo/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:purexo/features/bookings/presentation/manager/bookings_state.dart';
import 'package:purexo/features/bookings/presentation/widgets/action_dialogs/change_booking_status_dialog.dart';
import 'package:purexo/features/bookings/presentation/widgets/action_dialogs/delete_booking_dialog.dart';
import 'package:purexo/features/bookings/presentation/widgets/action_dialogs/reassign_technician_dialog.dart';
import 'package:purexo/shared/widgets/custom_toast.dart';

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
            onConfirm: () {
              final selected = state.dialogStatus ??
                  booking.status ??
                  BookingStatusEnum.scheduled;
              if (onConfirm != null) {
                onConfirm(selected);
              } else {
                cubit.changeBookingStatus(
                  booking.id ?? '',
                  selected,
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
