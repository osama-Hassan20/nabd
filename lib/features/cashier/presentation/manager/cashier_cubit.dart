import '../../../../core/base/safe_cubit.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/cashier_shift_model.dart';
import '../../data/models/enums/shift_status_enum.dart';
import '../../domain/repo/cashier_repo.dart';
import '../../domain/use_cases/approve_shortage_use_case.dart';
import '../../domain/use_cases/close_shift_drawer_use_case.dart';
import '../../domain/use_cases/collect_payment_use_case.dart';
import '../../domain/use_cases/force_close_shift_use_case.dart';
import '../../domain/use_cases/get_active_shift_use_case.dart';
import '../../domain/use_cases/open_shift_drawer_use_case.dart';
import '../../domain/use_cases/record_drawer_expense_use_case.dart';
import '../../domain/use_cases/refund_payment_use_case.dart';
import 'cashier_state.dart';

class CashierCubit extends SafeCubit<CashierState> {
  final CashierRepo cashierRepo;
  final GetActiveShiftUseCase getActiveShiftUseCase;
  final OpenShiftDrawerUseCase openShiftDrawerUseCase;
  final CloseShiftDrawerUseCase closeShiftDrawerUseCase;
  final CollectPaymentUseCase collectPaymentUseCase;
  final RefundPaymentUseCase refundPaymentUseCase;
  final RecordDrawerExpenseUseCase recordDrawerExpenseUseCase;
  final ApproveShortageUseCase approveShortageUseCase;
  final ForceCloseShiftUseCase forceCloseShiftUseCase;

  CashierCubit({
    required this.cashierRepo,
    required this.getActiveShiftUseCase,
    required this.openShiftDrawerUseCase,
    required this.closeShiftDrawerUseCase,
    required this.collectPaymentUseCase,
    required this.refundPaymentUseCase,
    required this.recordDrawerExpenseUseCase,
    required this.approveShortageUseCase,
    required this.forceCloseShiftUseCase,
  }) : super(const CashierState());

  /// Initializes shift view and history for current branch and user.
  Future<void> init({
    required String branchId,
    required String userId,
  }) async {
    emit(state.copyWith(
      status: RequestStatusEnum.loading,
      currentBranchId: branchId,
      currentUserId: userId,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));

    await Future.wait([
      loadActiveShift(branchId: branchId, userId: userId),
      loadShiftHistory(branchId: branchId, cashierUserId: null),
    ]);

    emit(state.copyWith(status: RequestStatusEnum.success));
  }

  /// Automatically resets all state when switching branch or logging out.
  void reset() {
    emit(const CashierState());
  }

  /// Handles branch or user switch without dangling timers.
  Future<void> onBranchOrUserChanged({
    required String newBranchId,
    required String newUserId,
  }) async {
    reset();
    await init(branchId: newBranchId, userId: newUserId);
  }

  /// Loads the active shift for the user in the specified branch.
  Future<void> loadActiveShift({
    required String branchId,
    required String userId,
  }) async {
    final result = await getActiveShiftUseCase(
      branchId: branchId,
      cashierUserId: userId,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          errorMessage: failure.errMessage,
        ));
      },
      (shift) async {
        if (shift != null) {
          emit(state.copyWith(
            activeShift: shift,
            selectedShift: shift,
          ));
          await loadShiftDetails(shift.id ?? '');
        } else {
          emit(state.copyWith(
            clearActiveShift: true,
            clearSummaryMetrics: true,
            shiftPayments: const [],
          ));
        }
      },
    );
  }

  /// Loads shift history for the branch.
  Future<void> loadShiftHistory({
    required String branchId,
    String? cashierUserId,
  }) async {
    final result = await cashierRepo.getShiftHistory(
      branchId: branchId,
      cashierUserId: cashierUserId,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.errMessage));
      },
      (history) {
        emit(state.copyWith(shiftHistory: history));
      },
    );
  }

  /// Loads payment transactions and summary metrics for a given shift.
  Future<void> loadShiftDetails(String shiftId) async {
    if (shiftId.isEmpty) return;

    final metricsRes = await cashierRepo.getShiftMetrics(shiftId: shiftId);
    final paymentsRes = await cashierRepo.getPaymentsForShift(shiftId: shiftId);

    metricsRes.fold(
      (f) => emit(state.copyWith(errorMessage: f.errMessage)),
      (metrics) => emit(state.copyWith(summaryMetrics: metrics)),
    );

    paymentsRes.fold(
      (f) => emit(state.copyWith(errorMessage: f.errMessage)),
      (payments) => emit(state.copyWith(shiftPayments: payments)),
    );
  }

  /// Opens a new cashier shift drawer.
  Future<bool> openShift({
    required String branchId,
    required int openingBalancePiastres,
    String? cashierUserId,
    String? cashierName,
    String? suggestedOpeningBalanceDiffReason,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final result = await openShiftDrawerUseCase(
      branchId: branchId,
      openingBalancePiastres: openingBalancePiastres,
      cashierUserId: cashierUserId,
      cashierName: cashierName,
      suggestedOpeningBalanceDiffReason: suggestedOpeningBalanceDiffReason,
    );

    if (result.isRight()) {
      final shift = result.getOrElse(() => throw StateError(''));
      emit(state.copyWith(
        isSubmitting: false,
        activeShift: shift,
        selectedShift: shift,
        successMessage: 'cashier_shift_opened_success',
      ));
      await loadShiftHistory(
        branchId: branchId,
        cashierUserId: cashierUserId,
      );
      await loadShiftDetails(shift.id ?? '');
      return true;
    } else {
      final failure = result.swap().getOrElse(() => throw StateError(''));
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: failure.errMessage,
      ));
      return false;
    }
  }

  /// Closes the active shift drawer with actual counted cash.
  Future<bool> closeShift({
    required String shiftId,
    required int actualCashCountPiastres,
    String? closingNotes,
    String? shortageReason,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final result = await closeShiftDrawerUseCase(
      shiftId: shiftId,
      actualCashCountPiastres: actualCashCountPiastres,
      closingNotes: closingNotes,
      shortageReason: shortageReason,
    );

    if (result.isRight()) {
      final closedShift = result.getOrElse(() => throw StateError(''));
      emit(state.copyWith(
        isSubmitting: false,
        clearActiveShift: true,
        lastClosedShift: closedShift,
        selectedShift: closedShift,
        successMessage: closedShift.status == ShiftStatusEnum.closedPendingApproval
            ? 'cashier_shift_closed_pending_approval'
            : 'cashier_shift_closed_success',
      ));
      if (state.currentBranchId != null) {
        await loadShiftHistory(
          branchId: state.currentBranchId!,
          cashierUserId: null,
        );
      }
      return true;
    } else {
      final failure = result.swap().getOrElse(() => throw StateError(''));
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: failure.errMessage,
      ));
      return false;
    }
  }

  /// Collects payment for a booking and reconciles drawer.
  Future<bool> collectPayment({
    required String clientRequestId,
    required String shiftId,
    required String branchId,
    required String bookingId,
    required String patientId,
    required String patientName,
    required int amountPiastres,
    required String paymentMethod,
    String? cashierUserId,
    String? cashierName,
    String? referenceNumber,
    String? notes,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final result = await collectPaymentUseCase(
      clientRequestId: clientRequestId,
      shiftId: shiftId,
      branchId: branchId,
      bookingId: bookingId,
      patientId: patientId,
      patientName: patientName,
      amountPiastres: amountPiastres,
      paymentMethod: paymentMethod,
      cashierUserId: cashierUserId,
      cashierName: cashierName,
      referenceNumber: referenceNumber,
      notes: notes,
    );

    if (result.isRight()) {
      final payment = result.getOrElse(() => throw StateError(''));
      emit(state.copyWith(
        isSubmitting: false,
        lastPayment: payment,
        successMessage: 'cashier_payment_collected_success',
      ));
      if (state.currentBranchId != null && state.currentUserId != null) {
        await loadActiveShift(
          branchId: state.currentBranchId!,
          userId: state.currentUserId!,
        );
      }
      await loadShiftDetails(shiftId);
      return true;
    } else {
      final failure = result.swap().getOrElse(() => throw StateError(''));
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: failure.errMessage,
      ));
      return false;
    }
  }

  /// Refunds a payment and updates drawer / ledger.
  Future<bool> refundPayment({
    required String clientRequestId,
    required String originalPaymentId,
    required String shiftId,
    required String branchId,
    required String bookingId,
    required String patientId,
    required int refundAmountPiastres,
    required String refundMethod,
    required String reason,
    String? authorizedByUserId,
    String? authorizedByName,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final result = await refundPaymentUseCase(
      clientRequestId: clientRequestId,
      originalPaymentId: originalPaymentId,
      shiftId: shiftId,
      branchId: branchId,
      bookingId: bookingId,
      patientId: patientId,
      refundAmountPiastres: refundAmountPiastres,
      refundMethod: refundMethod,
      reason: reason,
      authorizedByUserId: authorizedByUserId,
      authorizedByName: authorizedByName,
    );

    if (result.isRight()) {
      final refund = result.getOrElse(() => throw StateError(''));
      emit(state.copyWith(
        isSubmitting: false,
        lastRefund: refund,
        successMessage: 'cashier_payment_refunded_success',
      ));
      if (state.currentBranchId != null && state.currentUserId != null) {
        await loadActiveShift(
          branchId: state.currentBranchId!,
          userId: state.currentUserId!,
        );
      }
      await loadShiftDetails(shiftId);
      return true;
    } else {
      final failure = result.swap().getOrElse(() => throw StateError(''));
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: failure.errMessage,
      ));
      return false;
    }
  }

  /// Records a petty expense or drawer movement.
  Future<bool> recordDrawerExpense({
    required String clientRequestId,
    required String shiftId,
    required String branchId,
    required String movementType,
    required int amountPiastres,
    required String reason,
    String? recipientName,
    String? performedByUserId,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final result = await recordDrawerExpenseUseCase(
      clientRequestId: clientRequestId,
      shiftId: shiftId,
      branchId: branchId,
      movementType: movementType,
      amountPiastres: amountPiastres,
      reason: reason,
      recipientName: recipientName,
      performedByUserId: performedByUserId,
    );

    if (result.isRight()) {
      emit(state.copyWith(
        isSubmitting: false,
        successMessage: 'cashier_movement_recorded_success',
      ));
      if (state.currentBranchId != null && state.currentUserId != null) {
        await loadActiveShift(
          branchId: state.currentBranchId!,
          userId: state.currentUserId!,
        );
      }
      await loadShiftDetails(shiftId);
      return true;
    } else {
      final failure = result.swap().getOrElse(() => throw StateError(''));
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: failure.errMessage,
      ));
      return false;
    }
  }

  /// Approves a shortage on a shift pending approval.
  Future<bool> approveShortage({
    required String shiftId,
    required String branchId,
    required String cashierUserId,
    required String reason,
    String? approvedByUserId,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final result = await approveShortageUseCase(
      shiftId: shiftId,
      branchId: branchId,
      cashierUserId: cashierUserId,
      reason: reason,
      approvedByUserId: approvedByUserId,
    );

    if (result.isRight()) {
      final approvedShift = result.getOrElse(() => throw StateError(''));
      emit(state.copyWith(
        isSubmitting: false,
        selectedShift: approvedShift,
        successMessage: 'cashier_shortage_approved_success',
      ));
      if (state.currentBranchId != null) {
        await loadShiftHistory(
          branchId: state.currentBranchId!,
          cashierUserId: null,
        );
      }
      return true;
    } else {
      final failure = result.swap().getOrElse(() => throw StateError(''));
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: failure.errMessage,
      ));
      return false;
    }
  }

  /// Force closes an overdue shift.
  Future<bool> forceCloseShift({
    required String shiftId,
    required String branchId,
    required String reason,
    String? performedByUserId,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));

    final result = await forceCloseShiftUseCase(
      shiftId: shiftId,
      branchId: branchId,
      reason: reason,
      performedByUserId: performedByUserId,
    );

    if (result.isRight()) {
      final closedShift = result.getOrElse(() => throw StateError(''));
      emit(state.copyWith(
        isSubmitting: false,
        selectedShift: closedShift,
        successMessage: 'cashier_shift_force_closed_success',
      ));
      if (state.activeShift?.id == shiftId) {
        emit(state.copyWith(clearActiveShift: true));
      }
      if (state.currentBranchId != null) {
        await loadShiftHistory(
          branchId: state.currentBranchId!,
          cashierUserId: null,
        );
      }
      return true;
    } else {
      final failure = result.swap().getOrElse(() => throw StateError(''));
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: failure.errMessage,
      ));
      return false;
    }
  }

  void selectShift(CashierShiftModel? shift) {
    emit(state.copyWith(selectedShift: shift, clearSelectedShift: shift == null));
    if (shift?.id != null) {
      loadShiftDetails(shift!.id!);
    }
  }

  void clearMessages() {
    emit(state.copyWith(
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));
  }
}
