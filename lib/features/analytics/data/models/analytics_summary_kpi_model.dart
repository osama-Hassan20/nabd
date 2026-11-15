import 'package:equatable/equatable.dart';

class AnalyticsSummaryKpiModel extends Equatable {
  final int? totalRevenuePiastres;
  final int? netProfitPiastres;
  final int? totalVisitsCount;
  final int? completedVisitsCount;
  final int? cancelledVisitsCount;
  final int? noShowVisitsCount;
  final int? totalBookingsCount;
  final int? averageWaitTimeMinutes;
  final int? averageConsultationMinutes;
  final int? outstandingDebtsPiastres;
  final int? totalDoctorPayoutsPiastres;
  final int? totalStaffPayrollPiastres;
  final double? patientReturnRatePercent;
  final double? revenueGrowthRatePercent;
  final double? visitsGrowthRatePercent;

  const AnalyticsSummaryKpiModel({
    this.totalRevenuePiastres,
    this.netProfitPiastres,
    this.totalVisitsCount,
    this.completedVisitsCount,
    this.cancelledVisitsCount,
    this.noShowVisitsCount,
    this.totalBookingsCount,
    this.averageWaitTimeMinutes,
    this.averageConsultationMinutes,
    this.outstandingDebtsPiastres,
    this.totalDoctorPayoutsPiastres,
    this.totalStaffPayrollPiastres,
    this.patientReturnRatePercent,
    this.revenueGrowthRatePercent,
    this.visitsGrowthRatePercent,
  });

  AnalyticsSummaryKpiModel copyWith({
    int? totalRevenuePiastres,
    int? netProfitPiastres,
    int? totalVisitsCount,
    int? completedVisitsCount,
    int? cancelledVisitsCount,
    int? noShowVisitsCount,
    int? totalBookingsCount,
    int? averageWaitTimeMinutes,
    int? averageConsultationMinutes,
    int? outstandingDebtsPiastres,
    int? totalDoctorPayoutsPiastres,
    int? totalStaffPayrollPiastres,
    double? patientReturnRatePercent,
    double? revenueGrowthRatePercent,
    double? visitsGrowthRatePercent,
  }) {
    return AnalyticsSummaryKpiModel(
      totalRevenuePiastres: totalRevenuePiastres ?? this.totalRevenuePiastres,
      netProfitPiastres: netProfitPiastres ?? this.netProfitPiastres,
      totalVisitsCount: totalVisitsCount ?? this.totalVisitsCount,
      completedVisitsCount: completedVisitsCount ?? this.completedVisitsCount,
      cancelledVisitsCount: cancelledVisitsCount ?? this.cancelledVisitsCount,
      noShowVisitsCount: noShowVisitsCount ?? this.noShowVisitsCount,
      totalBookingsCount: totalBookingsCount ?? this.totalBookingsCount,
      averageWaitTimeMinutes: averageWaitTimeMinutes ?? this.averageWaitTimeMinutes,
      averageConsultationMinutes: averageConsultationMinutes ?? this.averageConsultationMinutes,
      outstandingDebtsPiastres: outstandingDebtsPiastres ?? this.outstandingDebtsPiastres,
      totalDoctorPayoutsPiastres: totalDoctorPayoutsPiastres ?? this.totalDoctorPayoutsPiastres,
      totalStaffPayrollPiastres: totalStaffPayrollPiastres ?? this.totalStaffPayrollPiastres,
      patientReturnRatePercent: patientReturnRatePercent ?? this.patientReturnRatePercent,
      revenueGrowthRatePercent: revenueGrowthRatePercent ?? this.revenueGrowthRatePercent,
      visitsGrowthRatePercent: visitsGrowthRatePercent ?? this.visitsGrowthRatePercent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalRevenuePiastres': totalRevenuePiastres,
      'netProfitPiastres': netProfitPiastres,
      'totalVisitsCount': totalVisitsCount,
      'completedVisitsCount': completedVisitsCount,
      'cancelledVisitsCount': cancelledVisitsCount,
      'noShowVisitsCount': noShowVisitsCount,
      'totalBookingsCount': totalBookingsCount,
      'averageWaitTimeMinutes': averageWaitTimeMinutes,
      'averageConsultationMinutes': averageConsultationMinutes,
      'outstandingDebtsPiastres': outstandingDebtsPiastres,
      'totalDoctorPayoutsPiastres': totalDoctorPayoutsPiastres,
      'totalStaffPayrollPiastres': totalStaffPayrollPiastres,
      'patientReturnRatePercent': patientReturnRatePercent,
      'revenueGrowthRatePercent': revenueGrowthRatePercent,
      'visitsGrowthRatePercent': visitsGrowthRatePercent,
    };
  }

  factory AnalyticsSummaryKpiModel.fromMap(Map<String, dynamic> map) {
    return AnalyticsSummaryKpiModel(
      totalRevenuePiastres: (map['totalRevenuePiastres'] as num?)?.toInt(),
      netProfitPiastres: (map['netProfitPiastres'] as num?)?.toInt(),
      totalVisitsCount: (map['totalVisitsCount'] as num?)?.toInt(),
      completedVisitsCount: (map['completedVisitsCount'] as num?)?.toInt(),
      cancelledVisitsCount: (map['cancelledVisitsCount'] as num?)?.toInt(),
      noShowVisitsCount: (map['noShowVisitsCount'] as num?)?.toInt(),
      totalBookingsCount: (map['totalBookingsCount'] as num?)?.toInt(),
      averageWaitTimeMinutes: (map['averageWaitTimeMinutes'] as num?)?.toInt(),
      averageConsultationMinutes: (map['averageConsultationMinutes'] as num?)?.toInt(),
      outstandingDebtsPiastres: (map['outstandingDebtsPiastres'] as num?)?.toInt(),
      totalDoctorPayoutsPiastres: (map['totalDoctorPayoutsPiastres'] as num?)?.toInt(),
      totalStaffPayrollPiastres: (map['totalStaffPayrollPiastres'] as num?)?.toInt(),
      patientReturnRatePercent: (map['patientReturnRatePercent'] as num?)?.toDouble(),
      revenueGrowthRatePercent: (map['revenueGrowthRatePercent'] as num?)?.toDouble(),
      visitsGrowthRatePercent: (map['visitsGrowthRatePercent'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        totalRevenuePiastres,
        netProfitPiastres,
        totalVisitsCount,
        completedVisitsCount,
        cancelledVisitsCount,
        noShowVisitsCount,
        totalBookingsCount,
        averageWaitTimeMinutes,
        averageConsultationMinutes,
        outstandingDebtsPiastres,
        totalDoctorPayoutsPiastres,
        totalStaffPayrollPiastres,
        patientReturnRatePercent,
        revenueGrowthRatePercent,
        visitsGrowthRatePercent,
      ];
}
