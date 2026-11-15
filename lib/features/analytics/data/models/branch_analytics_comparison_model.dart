import 'package:equatable/equatable.dart';

class BranchAnalyticsComparisonModel extends Equatable {
  final String? branchId;
  final String? branchName;
  final int? totalRevenuePiastres;
  final int? visitsCount;
  final double? occupancyRatePercent;
  final double? shareOfTotalRevenuePercent;

  const BranchAnalyticsComparisonModel({
    this.branchId,
    this.branchName,
    this.totalRevenuePiastres,
    this.visitsCount,
    this.occupancyRatePercent,
    this.shareOfTotalRevenuePercent,
  });

  BranchAnalyticsComparisonModel copyWith({
    String? branchId,
    String? branchName,
    int? totalRevenuePiastres,
    int? visitsCount,
    double? occupancyRatePercent,
    double? shareOfTotalRevenuePercent,
  }) {
    return BranchAnalyticsComparisonModel(
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      totalRevenuePiastres: totalRevenuePiastres ?? this.totalRevenuePiastres,
      visitsCount: visitsCount ?? this.visitsCount,
      occupancyRatePercent: occupancyRatePercent ?? this.occupancyRatePercent,
      shareOfTotalRevenuePercent: shareOfTotalRevenuePercent ?? this.shareOfTotalRevenuePercent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'branchName': branchName,
      'totalRevenuePiastres': totalRevenuePiastres,
      'visitsCount': visitsCount,
      'occupancyRatePercent': occupancyRatePercent,
      'shareOfTotalRevenuePercent': shareOfTotalRevenuePercent,
    };
  }

  factory BranchAnalyticsComparisonModel.fromMap(Map<String, dynamic> map) {
    return BranchAnalyticsComparisonModel(
      branchId: map['branchId'] as String?,
      branchName: map['branchName'] as String?,
      totalRevenuePiastres: (map['totalRevenuePiastres'] as num?)?.toInt(),
      visitsCount: (map['visitsCount'] as num?)?.toInt(),
      occupancyRatePercent: (map['occupancyRatePercent'] as num?)?.toDouble(),
      shareOfTotalRevenuePercent: (map['shareOfTotalRevenuePercent'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        branchId,
        branchName,
        totalRevenuePiastres,
        visitsCount,
        occupancyRatePercent,
        shareOfTotalRevenuePercent,
      ];
}
