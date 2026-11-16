import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/features/analytics/data/models/analytics_summary_kpi_model.dart';
import 'package:eyadty/features/analytics/data/models/branch_analytics_comparison_model.dart';
import 'package:eyadty/features/analytics/data/models/doctor_performance_metric_model.dart';
import 'package:eyadty/features/analytics/data/models/enums/analytics_tab_enum.dart';
import 'package:eyadty/features/analytics/data/models/enums/analytics_time_range_enum.dart';
import 'package:eyadty/features/analytics/data/models/hourly_traffic_metric_model.dart';
import 'package:eyadty/features/analytics/data/models/revenue_trend_point_model.dart';
import 'package:eyadty/features/analytics/data/models/service_revenue_distribution_model.dart';

void main() {
  group('Analytics Models & Enums Tests (Plan F-07 M-1)', () {
    // -------------------------------------------------------------------------
    // 1. Enums
    // -------------------------------------------------------------------------
    test('1. AnalyticsTimeRangeEnum contains all expected values', () {
      expect(AnalyticsTimeRangeEnum.values.length, 5);
      expect(AnalyticsTimeRangeEnum.values, contains(AnalyticsTimeRangeEnum.today));
      expect(AnalyticsTimeRangeEnum.values, contains(AnalyticsTimeRangeEnum.thisWeek));
      expect(AnalyticsTimeRangeEnum.values, contains(AnalyticsTimeRangeEnum.thisMonth));
      expect(AnalyticsTimeRangeEnum.values, contains(AnalyticsTimeRangeEnum.lastMonth));
      expect(AnalyticsTimeRangeEnum.values, contains(AnalyticsTimeRangeEnum.custom));
    });

    test('2. AnalyticsTabEnum contains all 4 analytical viewpoints', () {
      expect(AnalyticsTabEnum.values.length, 4);
      expect(AnalyticsTabEnum.values, contains(AnalyticsTabEnum.executive));
      expect(AnalyticsTabEnum.values, contains(AnalyticsTabEnum.financial));
      expect(AnalyticsTabEnum.values, contains(AnalyticsTabEnum.clinical));
      expect(AnalyticsTabEnum.values, contains(AnalyticsTabEnum.doctors));
    });

    // -------------------------------------------------------------------------
    // 2. AnalyticsSummaryKpiModel
    // -------------------------------------------------------------------------
    test('3. AnalyticsSummaryKpiModel supports 100% nullable construction with zero required', () {
      const model = AnalyticsSummaryKpiModel();
      expect(model.totalRevenuePiastres, isNull);
      expect(model.netProfitPiastres, isNull);
      expect(model.totalVisitsCount, isNull);
      expect(model.completedVisitsCount, isNull);
      expect(model.cancelledVisitsCount, isNull);
      expect(model.noShowVisitsCount, isNull);
      expect(model.totalBookingsCount, isNull);
      expect(model.averageWaitTimeMinutes, isNull);
      expect(model.averageConsultationMinutes, isNull);
      expect(model.outstandingDebtsPiastres, isNull);
      expect(model.totalDoctorPayoutsPiastres, isNull);
      expect(model.totalStaffPayrollPiastres, isNull);
      expect(model.patientReturnRatePercent, isNull);
      expect(model.revenueGrowthRatePercent, isNull);
      expect(model.visitsGrowthRatePercent, isNull);
    });

    test('4. AnalyticsSummaryKpiModel serialization round-trip toMap and fromMap', () {
      const model = AnalyticsSummaryKpiModel(
        totalRevenuePiastres: 12500000,
        netProfitPiastres: 5800000,
        totalVisitsCount: 350,
        completedVisitsCount: 310,
        cancelledVisitsCount: 25,
        noShowVisitsCount: 15,
        totalBookingsCount: 380,
        averageWaitTimeMinutes: 18,
        averageConsultationMinutes: 22,
        outstandingDebtsPiastres: 450000,
        totalDoctorPayoutsPiastres: 4200000,
        totalStaffPayrollPiastres: 2500000,
        patientReturnRatePercent: 42.5,
        revenueGrowthRatePercent: 12.8,
        visitsGrowthRatePercent: 8.5,
      );

      final map = model.toMap();
      final reconstructed = AnalyticsSummaryKpiModel.fromMap(map);

      expect(reconstructed, equals(model));
      expect(reconstructed.totalRevenuePiastres, 12500000);
      expect(reconstructed.netProfitPiastres, 5800000);
      expect(reconstructed.patientReturnRatePercent, 42.5);
    });

    test('5. AnalyticsSummaryKpiModel copyWith works immutably', () {
      const original = AnalyticsSummaryKpiModel(
        totalRevenuePiastres: 1000,
        totalVisitsCount: 10,
      );

      final updated = original.copyWith(
        totalRevenuePiastres: 2000,
        completedVisitsCount: 9,
      );

      expect(updated.totalRevenuePiastres, 2000);
      expect(updated.totalVisitsCount, 10);
      expect(updated.completedVisitsCount, 9);
      expect(original.totalRevenuePiastres, 1000);
    });

    test('6. AnalyticsSummaryKpiModel equality and props check', () {
      const a = AnalyticsSummaryKpiModel(totalRevenuePiastres: 5000);
      const b = AnalyticsSummaryKpiModel(totalRevenuePiastres: 5000);
      const c = AnalyticsSummaryKpiModel(totalRevenuePiastres: 6000);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.props, contains(5000));
    });

    // -------------------------------------------------------------------------
    // 3. RevenueTrendPointModel
    // -------------------------------------------------------------------------
    test('7. RevenueTrendPointModel supports nullable fields and default construction', () {
      const point = RevenueTrendPointModel();
      expect(point.label, isNull);
      expect(point.date, isNull);
      expect(point.revenuePiastres, isNull);
      expect(point.visitsCount, isNull);
      expect(point.doctorSharePiastres, isNull);
      expect(point.netProfitPiastres, isNull);
    });

    test('8. RevenueTrendPointModel serialization round-trip', () {
      final date = DateTime(2026, 11, 15);
      final point = RevenueTrendPointModel(
        label: '15 Nov',
        date: date,
        revenuePiastres: 750000,
        visitsCount: 22,
        doctorSharePiastres: 300000,
        netProfitPiastres: 450000,
      );

      final map = point.toMap();
      final reconstructed = RevenueTrendPointModel.fromMap(map);

      expect(reconstructed.label, '15 Nov');
      expect(reconstructed.revenuePiastres, 750000);
      expect(reconstructed.visitsCount, 22);
      expect(reconstructed.netProfitPiastres, 450000);
      expect(reconstructed.date, equals(date));
    });

    test('9. RevenueTrendPointModel copyWith', () {
      const original = RevenueTrendPointModel(label: 'Day 1', revenuePiastres: 100);
      final updated = original.copyWith(revenuePiastres: 200);

      expect(updated.label, 'Day 1');
      expect(updated.revenuePiastres, 200);
    });

    test('10. RevenueTrendPointModel equality', () {
      const a = RevenueTrendPointModel(label: 'W1', revenuePiastres: 500);
      const b = RevenueTrendPointModel(label: 'W1', revenuePiastres: 500);
      expect(a, equals(b));
    });

    // -------------------------------------------------------------------------
    // 4. BranchAnalyticsComparisonModel
    // -------------------------------------------------------------------------
    test('11. BranchAnalyticsComparisonModel supports nullable defaults', () {
      const model = BranchAnalyticsComparisonModel();
      expect(model.branchId, isNull);
      expect(model.branchName, isNull);
      expect(model.totalRevenuePiastres, isNull);
      expect(model.visitsCount, isNull);
      expect(model.occupancyRatePercent, isNull);
      expect(model.shareOfTotalRevenuePercent, isNull);
    });

    test('12. BranchAnalyticsComparisonModel serialization round-trip', () {
      const model = BranchAnalyticsComparisonModel(
        branchId: 'branch_1',
        branchName: 'الفرع الرئيسي - المعادي',
        totalRevenuePiastres: 8000000,
        visitsCount: 180,
        occupancyRatePercent: 88.5,
        shareOfTotalRevenuePercent: 55.2,
      );

      final map = model.toMap();
      final reconstructed = BranchAnalyticsComparisonModel.fromMap(map);

      expect(reconstructed, equals(model));
      expect(reconstructed.branchName, 'الفرع الرئيسي - المعادي');
      expect(reconstructed.shareOfTotalRevenuePercent, 55.2);
    });

    test('13. BranchAnalyticsComparisonModel copyWith and equality', () {
      const m1 = BranchAnalyticsComparisonModel(branchId: 'b1', totalRevenuePiastres: 1000);
      final m2 = m1.copyWith(totalRevenuePiastres: 2000);
      expect(m2.branchId, 'b1');
      expect(m2.totalRevenuePiastres, 2000);
      expect(m1 == m2, isFalse);
    });

    // -------------------------------------------------------------------------
    // 5. DoctorPerformanceMetricModel
    // -------------------------------------------------------------------------
    test('14. DoctorPerformanceMetricModel supports nullable fields', () {
      const model = DoctorPerformanceMetricModel();
      expect(model.doctorId, isNull);
      expect(model.doctorName, isNull);
      expect(model.specialty, isNull);
      expect(model.visitsCount, isNull);
      expect(model.revenueGeneratedPiastres, isNull);
      expect(model.doctorCommissionPiastres, isNull);
      expect(model.clinicSharePiastres, isNull);
      expect(model.avgConsultationDurationMinutes, isNull);
      expect(model.patientSatisfactionRating, isNull);
    });

    test('15. DoctorPerformanceMetricModel serialization round-trip', () {
      const model = DoctorPerformanceMetricModel(
        doctorId: 'DOC-01',
        doctorName: 'د. سامي الجوهري',
        specialty: 'جلدية وتجميل',
        visitsCount: 45,
        revenueGeneratedPiastres: 3500000,
        doctorCommissionPiastres: 1750000,
        clinicSharePiastres: 1750000,
        avgConsultationDurationMinutes: 20,
        patientSatisfactionRating: 4.8,
      );

      final map = model.toMap();
      final reconstructed = DoctorPerformanceMetricModel.fromMap(map);

      expect(reconstructed, equals(model));
      expect(reconstructed.doctorId, 'DOC-01');
      expect(reconstructed.patientSatisfactionRating, 4.8);
    });

    test('16. DoctorPerformanceMetricModel copyWith works accurately', () {
      const orig = DoctorPerformanceMetricModel(doctorId: 'DOC-01', visitsCount: 10);
      final mod = orig.copyWith(visitsCount: 15);
      expect(mod.doctorId, 'DOC-01');
      expect(mod.visitsCount, 15);
    });

    // -------------------------------------------------------------------------
    // 6. HourlyTrafficMetricModel
    // -------------------------------------------------------------------------
    test('17. HourlyTrafficMetricModel handles nulls and serialization', () {
      const model = HourlyTrafficMetricModel(
        hour: 14,
        dayOfWeek: 2,
        visitsCount: 18,
        occupancyLevel: 'peak',
      );

      final map = model.toMap();
      final reconstructed = HourlyTrafficMetricModel.fromMap(map);

      expect(reconstructed, equals(model));
      expect(reconstructed.hour, 14);
      expect(reconstructed.occupancyLevel, 'peak');
    });

    test('18. HourlyTrafficMetricModel copyWith and props', () {
      const orig = HourlyTrafficMetricModel(hour: 10, visitsCount: 5);
      final mod = orig.copyWith(visitsCount: 12);
      expect(mod.hour, 10);
      expect(mod.visitsCount, 12);
      expect(orig.props, contains(10));
    });

    // -------------------------------------------------------------------------
    // 7. ServiceRevenueDistributionModel
    // -------------------------------------------------------------------------
    test('19. ServiceRevenueDistributionModel handles nulls and serialization', () {
      const model = ServiceRevenueDistributionModel(
        serviceName: 'كشف استشاري',
        category: 'كشوفات',
        count: 85,
        totalRevenuePiastres: 4250000,
        percentage: 34.0,
      );

      final map = model.toMap();
      final reconstructed = ServiceRevenueDistributionModel.fromMap(map);

      expect(reconstructed, equals(model));
      expect(reconstructed.serviceName, 'كشف استشاري');
      expect(reconstructed.percentage, 34.0);
    });

    test('20. ServiceRevenueDistributionModel copyWith works accurately', () {
      const orig = ServiceRevenueDistributionModel(serviceName: 'إجراء ليزر', count: 12);
      final mod = orig.copyWith(count: 20);
      expect(mod.serviceName, 'إجراء ليزر');
      expect(mod.count, 20);
    });
  });
}

