import '../../domain/helpers/money.dart';
import 'enums/shift_status_enum.dart';

class CashierShiftModel {
  final String? id;
  final String? branchId;
  final String? cashierUserId;
  final String? cashierName;
  final ShiftStatusEnum? status;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final DateTime? businessDate;
  final int? openingBalancePiastres;
  final int? actualCashCountPiastres;
  final int? expectedCashPiastres;
  final int? cashDifferencePiastres;
  final int? totalCashCollectedPiastres;
  final int? totalCardCollectedPiastres;
  final int? totalBankTransferPiastres;
  final int? totalExpensesPiastres;
  final int? totalRefundsPiastres;
  final int? totalCapitalInjectionsPiastres;
  final int? totalBankDepositsPiastres;
  final int? totalOwnerWithdrawalsPiastres;
  final String? closingNotes;
  final bool? isShortageApproved;
  final bool? isOwnerSelfApproved;
  final String? shortageApprovedByUserId;
  final DateTime? shortageApprovedAt;
  final String? shortageReason;
  final String? forceClosedByUserId;
  final String? forceCloseReason;
  final int? transactionCount;

  const CashierShiftModel({
    this.id,
    this.branchId,
    this.cashierUserId,
    this.cashierName,
    this.status,
    this.openedAt,
    this.closedAt,
    this.businessDate,
    this.openingBalancePiastres,
    this.actualCashCountPiastres,
    this.expectedCashPiastres,
    this.cashDifferencePiastres,
    this.totalCashCollectedPiastres,
    this.totalCardCollectedPiastres,
    this.totalBankTransferPiastres,
    this.totalExpensesPiastres,
    this.totalRefundsPiastres,
    this.totalCapitalInjectionsPiastres,
    this.totalBankDepositsPiastres,
    this.totalOwnerWithdrawalsPiastres,
    this.closingNotes,
    this.isShortageApproved,
    this.isOwnerSelfApproved,
    this.shortageApprovedByUserId,
    this.shortageApprovedAt,
    this.shortageReason,
    this.forceClosedByUserId,
    this.forceCloseReason,
    this.transactionCount,
  });

  bool get isOpen => status == ShiftStatusEnum.open;
  bool get isClosed => status == ShiftStatusEnum.closed;
  bool get isPendingApproval => status == ShiftStatusEnum.closedPendingApproval;
  bool get isForceClosed => status == ShiftStatusEnum.forceClosed;

  Money get openingBalanceMoney => Money(openingBalancePiastres ?? 0);
  Money get expectedCashMoney => Money(expectedCashPiastres ?? 0);
  Money get actualCashMoney => Money(actualCashCountPiastres ?? 0);
  Money get differenceMoney => Money(cashDifferencePiastres ?? 0);
  Money get totalCashMoney => Money(totalCashCollectedPiastres ?? 0);
  Money get totalCardMoney => Money(totalCardCollectedPiastres ?? 0);
  Money get totalBankMoney => Money(totalBankTransferPiastres ?? 0);
  Money get totalExpensesMoney => Money(totalExpensesPiastres ?? 0);
  Money get totalRefundsMoney => Money(totalRefundsPiastres ?? 0);

  bool get hasShortage => (cashDifferencePiastres ?? 0) < 0;
  bool get hasSurplus => (cashDifferencePiastres ?? 0) > 0;
  bool get isBalanced => (cashDifferencePiastres ?? 0) == 0;

  factory CashierShiftModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CashierShiftModel();
    return CashierShiftModel(
      id: json['id'] as String?,
      branchId: json['branchId'] as String?,
      cashierUserId: json['cashierUserId'] as String?,
      cashierName: json['cashierName'] as String?,
      status: ShiftStatusEnum.fromValue(json['status'] as String?),
      openedAt: json['openedAt'] != null
          ? DateTime.tryParse(json['openedAt'].toString())
          : null,
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'].toString())
          : null,
      businessDate: json['businessDate'] != null
          ? DateTime.tryParse(json['businessDate'].toString())
          : null,
      openingBalancePiastres: json['openingBalancePiastres'] as int?,
      actualCashCountPiastres: json['actualCashCountPiastres'] as int?,
      expectedCashPiastres: json['expectedCashPiastres'] as int?,
      cashDifferencePiastres: json['cashDifferencePiastres'] as int?,
      totalCashCollectedPiastres: json['totalCashCollectedPiastres'] as int?,
      totalCardCollectedPiastres: json['totalCardCollectedPiastres'] as int?,
      totalBankTransferPiastres: json['totalBankTransferPiastres'] as int?,
      totalExpensesPiastres: json['totalExpensesPiastres'] as int?,
      totalRefundsPiastres: json['totalRefundsPiastres'] as int?,
      totalCapitalInjectionsPiastres: json['totalCapitalInjectionsPiastres'] as int?,
      totalBankDepositsPiastres: json['totalBankDepositsPiastres'] as int?,
      totalOwnerWithdrawalsPiastres: json['totalOwnerWithdrawalsPiastres'] as int?,
      closingNotes: json['closingNotes'] as String?,
      isShortageApproved: json['isShortageApproved'] as bool?,
      isOwnerSelfApproved: json['isOwnerSelfApproved'] as bool?,
      shortageApprovedByUserId: json['shortageApprovedByUserId'] as String?,
      shortageApprovedAt: json['shortageApprovedAt'] != null
          ? DateTime.tryParse(json['shortageApprovedAt'].toString())
          : null,
      shortageReason: json['shortageReason'] as String?,
      forceClosedByUserId: json['forceClosedByUserId'] as String?,
      forceCloseReason: json['forceCloseReason'] as String?,
      transactionCount: json['transactionCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (branchId != null) 'branchId': branchId,
      if (cashierUserId != null) 'cashierUserId': cashierUserId,
      if (cashierName != null) 'cashierName': cashierName,
      if (status != null) 'status': status?.value,
      if (openedAt != null) 'openedAt': openedAt?.toIso8601String(),
      if (closedAt != null) 'closedAt': closedAt?.toIso8601String(),
      if (businessDate != null) 'businessDate': businessDate?.toIso8601String(),
      if (openingBalancePiastres != null)
        'openingBalancePiastres': openingBalancePiastres,
      if (actualCashCountPiastres != null)
        'actualCashCountPiastres': actualCashCountPiastres,
      if (expectedCashPiastres != null)
        'expectedCashPiastres': expectedCashPiastres,
      if (cashDifferencePiastres != null)
        'cashDifferencePiastres': cashDifferencePiastres,
      if (totalCashCollectedPiastres != null)
        'totalCashCollectedPiastres': totalCashCollectedPiastres,
      if (totalCardCollectedPiastres != null)
        'totalCardCollectedPiastres': totalCardCollectedPiastres,
      if (totalBankTransferPiastres != null)
        'totalBankTransferPiastres': totalBankTransferPiastres,
      if (totalExpensesPiastres != null)
        'totalExpensesPiastres': totalExpensesPiastres,
      if (totalRefundsPiastres != null)
        'totalRefundsPiastres': totalRefundsPiastres,
      if (totalCapitalInjectionsPiastres != null)
        'totalCapitalInjectionsPiastres': totalCapitalInjectionsPiastres,
      if (totalBankDepositsPiastres != null)
        'totalBankDepositsPiastres': totalBankDepositsPiastres,
      if (totalOwnerWithdrawalsPiastres != null)
        'totalOwnerWithdrawalsPiastres': totalOwnerWithdrawalsPiastres,
      if (closingNotes != null) 'closingNotes': closingNotes,
      if (isShortageApproved != null) 'isShortageApproved': isShortageApproved,
      if (isOwnerSelfApproved != null) 'isOwnerSelfApproved': isOwnerSelfApproved,
      if (shortageApprovedByUserId != null)
        'shortageApprovedByUserId': shortageApprovedByUserId,
      if (shortageApprovedAt != null)
        'shortageApprovedAt': shortageApprovedAt?.toIso8601String(),
      if (shortageReason != null) 'shortageReason': shortageReason,
      if (forceClosedByUserId != null)
        'forceClosedByUserId': forceClosedByUserId,
      if (forceCloseReason != null) 'forceCloseReason': forceCloseReason,
      if (transactionCount != null) 'transactionCount': transactionCount,
    };
  }

  CashierShiftModel copyWith({
    String? id,
    String? branchId,
    String? cashierUserId,
    String? cashierName,
    ShiftStatusEnum? status,
    DateTime? openedAt,
    DateTime? closedAt,
    DateTime? businessDate,
    int? openingBalancePiastres,
    int? actualCashCountPiastres,
    int? expectedCashPiastres,
    int? cashDifferencePiastres,
    int? totalCashCollectedPiastres,
    int? totalCardCollectedPiastres,
    int? totalBankTransferPiastres,
    int? totalExpensesPiastres,
    int? totalRefundsPiastres,
    int? totalCapitalInjectionsPiastres,
    int? totalBankDepositsPiastres,
    int? totalOwnerWithdrawalsPiastres,
    String? closingNotes,
    bool? isShortageApproved,
    bool? isOwnerSelfApproved,
    String? shortageApprovedByUserId,
    DateTime? shortageApprovedAt,
    String? shortageReason,
    String? forceClosedByUserId,
    String? forceCloseReason,
    int? transactionCount,
  }) {
    return CashierShiftModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      cashierUserId: cashierUserId ?? this.cashierUserId,
      cashierName: cashierName ?? this.cashierName,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      businessDate: businessDate ?? this.businessDate,
      openingBalancePiastres:
          openingBalancePiastres ?? this.openingBalancePiastres,
      actualCashCountPiastres:
          actualCashCountPiastres ?? this.actualCashCountPiastres,
      expectedCashPiastres:
          expectedCashPiastres ?? this.expectedCashPiastres,
      cashDifferencePiastres:
          cashDifferencePiastres ?? this.cashDifferencePiastres,
      totalCashCollectedPiastres:
          totalCashCollectedPiastres ?? this.totalCashCollectedPiastres,
      totalCardCollectedPiastres:
          totalCardCollectedPiastres ?? this.totalCardCollectedPiastres,
      totalBankTransferPiastres:
          totalBankTransferPiastres ?? this.totalBankTransferPiastres,
      totalExpensesPiastres:
          totalExpensesPiastres ?? this.totalExpensesPiastres,
      totalRefundsPiastres:
          totalRefundsPiastres ?? this.totalRefundsPiastres,
      totalCapitalInjectionsPiastres:
          totalCapitalInjectionsPiastres ?? this.totalCapitalInjectionsPiastres,
      totalBankDepositsPiastres:
          totalBankDepositsPiastres ?? this.totalBankDepositsPiastres,
      totalOwnerWithdrawalsPiastres:
          totalOwnerWithdrawalsPiastres ?? this.totalOwnerWithdrawalsPiastres,
      closingNotes: closingNotes ?? this.closingNotes,
      isShortageApproved: isShortageApproved ?? this.isShortageApproved,
      isOwnerSelfApproved: isOwnerSelfApproved ?? this.isOwnerSelfApproved,
      shortageApprovedByUserId:
          shortageApprovedByUserId ?? this.shortageApprovedByUserId,
      shortageApprovedAt: shortageApprovedAt ?? this.shortageApprovedAt,
      shortageReason: shortageReason ?? this.shortageReason,
      forceClosedByUserId: forceClosedByUserId ?? this.forceClosedByUserId,
      forceCloseReason: forceCloseReason ?? this.forceCloseReason,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }
}
