import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/cashier_shift_model.dart';
import '../../data/models/cashier_summary_metrics_model.dart';
import '../../data/models/payment_transaction_model.dart';
import '../../data/models/refund_transaction_model.dart';

class CashierState extends Equatable {
  final RequestStatusEnum status;
  final CashierShiftModel? activeShift;
  final List<CashierShiftModel> shiftHistory;
  final CashierShiftModel? selectedShift;
  final List<PaymentTransactionModel> shiftPayments;
  final CashierSummaryMetricsModel? summaryMetrics;
  final String? currentBranchId;
  final String? currentUserId;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final CashierShiftModel? lastClosedShift;
  final PaymentTransactionModel? lastPayment;
  final RefundTransactionModel? lastRefund;

  const CashierState({
    this.status = RequestStatusEnum.initial,
    this.activeShift,
    this.shiftHistory = const [],
    this.selectedShift,
    this.shiftPayments = const [],
    this.summaryMetrics,
    this.currentBranchId,
    this.currentUserId,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.lastClosedShift,
    this.lastPayment,
    this.lastRefund,
  });

  bool get hasActiveShift => activeShift != null;

  int get expectedCashPiastres => activeShift?.expectedCashPiastres ?? 0;

  CashierState copyWith({
    RequestStatusEnum? status,
    CashierShiftModel? activeShift,
    bool clearActiveShift = false,
    List<CashierShiftModel>? shiftHistory,
    CashierShiftModel? selectedShift,
    bool clearSelectedShift = false,
    List<PaymentTransactionModel>? shiftPayments,
    CashierSummaryMetricsModel? summaryMetrics,
    bool clearSummaryMetrics = false,
    String? currentBranchId,
    String? currentUserId,
    bool? isSubmitting,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    CashierShiftModel? lastClosedShift,
    bool clearLastClosedShift = false,
    PaymentTransactionModel? lastPayment,
    bool clearLastPayment = false,
    RefundTransactionModel? lastRefund,
    bool clearLastRefund = false,
  }) {
    return CashierState(
      status: status ?? this.status,
      activeShift: clearActiveShift ? null : (activeShift ?? this.activeShift),
      shiftHistory: shiftHistory ?? this.shiftHistory,
      selectedShift:
          clearSelectedShift ? null : (selectedShift ?? this.selectedShift),
      shiftPayments: shiftPayments ?? this.shiftPayments,
      summaryMetrics:
          clearSummaryMetrics ? null : (summaryMetrics ?? this.summaryMetrics),
      currentBranchId: currentBranchId ?? this.currentBranchId,
      currentUserId: currentUserId ?? this.currentUserId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      lastClosedShift: clearLastClosedShift
          ? null
          : (lastClosedShift ?? this.lastClosedShift),
      lastPayment: clearLastPayment ? null : (lastPayment ?? this.lastPayment),
      lastRefund: clearLastRefund ? null : (lastRefund ?? this.lastRefund),
    );
  }

  @override
  List<Object?> get props => [
        status,
        activeShift,
        shiftHistory,
        selectedShift,
        shiftPayments,
        summaryMetrics,
        currentBranchId,
        currentUserId,
        isSubmitting,
        errorMessage,
        successMessage,
        lastClosedShift,
        lastPayment,
        lastRefund,
      ];
}
