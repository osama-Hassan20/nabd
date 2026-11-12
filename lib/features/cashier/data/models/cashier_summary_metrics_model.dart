import '../../domain/helpers/money.dart';

class CashierSummaryMetricsModel {
  final int? openingBalancePiastres;
  final int? expectedCashPiastres;
  final int? actualCashPiastres;
  final int? differencePiastres;
  final int? cashCollectedPiastres;
  final int? cardCollectedPiastres;
  final int? bankTransferPiastres;
  final int? totalExpensesPiastres;
  final int? totalRefundsPiastres;
  final int? transactionsCount;

  const CashierSummaryMetricsModel({
    this.openingBalancePiastres,
    this.expectedCashPiastres,
    this.actualCashPiastres,
    this.differencePiastres,
    this.cashCollectedPiastres,
    this.cardCollectedPiastres,
    this.bankTransferPiastres,
    this.totalExpensesPiastres,
    this.totalRefundsPiastres,
    this.transactionsCount,
  });

  Money get openingBalanceMoney => Money(openingBalancePiastres ?? 0);
  Money get expectedCashMoney => Money(expectedCashPiastres ?? 0);
  Money get actualCashMoney => Money(actualCashPiastres ?? 0);
  Money get differenceMoney => Money(differencePiastres ?? 0);
  Money get cashCollectedMoney => Money(cashCollectedPiastres ?? 0);
  Money get cardCollectedMoney => Money(cardCollectedPiastres ?? 0);
  Money get bankTransferMoney => Money(bankTransferPiastres ?? 0);
  Money get totalExpensesMoney => Money(totalExpensesPiastres ?? 0);
  Money get totalRefundsMoney => Money(totalRefundsPiastres ?? 0);
  Money get grandTotalCollectedMoney =>
      Money((cashCollectedPiastres ?? 0) +
          (cardCollectedPiastres ?? 0) +
          (bankTransferPiastres ?? 0));

  factory CashierSummaryMetricsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CashierSummaryMetricsModel();
    return CashierSummaryMetricsModel(
      openingBalancePiastres: json['openingBalancePiastres'] as int?,
      expectedCashPiastres: json['expectedCashPiastres'] as int?,
      actualCashPiastres: json['actualCashPiastres'] as int?,
      differencePiastres: json['differencePiastres'] as int?,
      cashCollectedPiastres: json['cashCollectedPiastres'] as int?,
      cardCollectedPiastres: json['cardCollectedPiastres'] as int?,
      bankTransferPiastres: json['bankTransferPiastres'] as int?,
      totalExpensesPiastres: json['totalExpensesPiastres'] as int?,
      totalRefundsPiastres: json['totalRefundsPiastres'] as int?,
      transactionsCount: json['transactionsCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (openingBalancePiastres != null)
        'openingBalancePiastres': openingBalancePiastres,
      if (expectedCashPiastres != null)
        'expectedCashPiastres': expectedCashPiastres,
      if (actualCashPiastres != null)
        'actualCashPiastres': actualCashPiastres,
      if (differencePiastres != null) 'differencePiastres': differencePiastres,
      if (cashCollectedPiastres != null)
        'cashCollectedPiastres': cashCollectedPiastres,
      if (cardCollectedPiastres != null)
        'cardCollectedPiastres': cardCollectedPiastres,
      if (bankTransferPiastres != null)
        'bankTransferPiastres': bankTransferPiastres,
      if (totalExpensesPiastres != null)
        'totalExpensesPiastres': totalExpensesPiastres,
      if (totalRefundsPiastres != null)
        'totalRefundsPiastres': totalRefundsPiastres,
      if (transactionsCount != null) 'transactionsCount': transactionsCount,
    };
  }
}
