import 'package:eyadty/core/local_server/local_server_router.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/analytics/data/models/analytics_summary_kpi_model.dart';
import 'package:eyadty/features/analytics/data/models/branch_analytics_comparison_model.dart';
import 'package:eyadty/features/analytics/data/models/doctor_performance_metric_model.dart';
import 'package:eyadty/features/analytics/data/models/enums/analytics_time_range_enum.dart';
import 'package:eyadty/features/analytics/data/models/hourly_traffic_metric_model.dart';
import 'package:eyadty/features/analytics/data/models/revenue_trend_point_model.dart';
import 'package:eyadty/features/analytics/data/models/service_revenue_distribution_model.dart';

class AnalyticsLocalHandler {
  AnalyticsLocalHandler._();

  static AnalyticsTimeRangeEnum _parseRange(String? val) {
    return AnalyticsTimeRangeEnum.values.firstWhere(
      (e) => e.name == val,
      orElse: () => AnalyticsTimeRangeEnum.thisMonth,
    );
  }

  static void register(LocalServerRouter router) {
    router.register('GET', 'analytics/summary', (req) async {
      final branchId = req.queryParameters['branchId']?.toString();
      final range = _parseRange(req.queryParameters['range']?.toString());
      if (branchId == 'branch_unknown' || branchId == 'non_existent') {
        return LocalServerRouter.ok(const AnalyticsSummaryKpiModel(
          totalRevenuePiastres: 0,
          netProfitPiastres: 0,
          totalVisitsCount: 0,
          completedVisitsCount: 0,
          cancelledVisitsCount: 0,
          noShowVisitsCount: 0,
          totalBookingsCount: 0,
          averageWaitTimeMinutes: 0,
          averageConsultationMinutes: 0,
          outstandingDebtsPiastres: 0,
          totalDoctorPayoutsPiastres: 0,
          totalStaffPayrollPiastres: 0,
          patientReturnRatePercent: 0.0,
          revenueGrowthRatePercent: 0.0,
          visitsGrowthRatePercent: 0.0,
        ).toJson());
      }
      final factor = branchId == 'branch_1'
          ? 1.0
          : branchId == 'branch_2'
              ? 0.65
              : branchId == 'branch_3'
                  ? 0.45
                  : 2.1;
      final timeScale = range == AnalyticsTimeRangeEnum.today
          ? 0.04
          : range == AnalyticsTimeRangeEnum.thisWeek
              ? 0.25
              : 1.0;
      final baseRevenue = (18500000 * factor * timeScale).round();
      final doctorPayouts = (baseRevenue * 0.45).round();
      final staffPayroll = (baseRevenue * 0.20).round();
      final netProfit = baseRevenue - doctorPayouts - staffPayroll;
      final totalVisits = (420 * factor * timeScale).round();
      final completedVisits = (totalVisits * 0.88).round();
      final cancelledVisits = (totalVisits * 0.08).round();
      final noShowVisits = totalVisits - completedVisits - cancelledVisits;
      final totalBookings = totalVisits + cancelledVisits;
      return LocalServerRouter.ok(AnalyticsSummaryKpiModel(
        totalRevenuePiastres: baseRevenue,
        netProfitPiastres: netProfit,
        totalVisitsCount: totalVisits,
        completedVisitsCount: completedVisits,
        cancelledVisitsCount: cancelledVisits,
        noShowVisitsCount: noShowVisits,
        totalBookingsCount: totalBookings,
        averageWaitTimeMinutes: 16,
        averageConsultationMinutes: 24,
        outstandingDebtsPiastres: (680000 * factor).round(),
        totalDoctorPayoutsPiastres: doctorPayouts,
        totalStaffPayrollPiastres: staffPayroll,
        patientReturnRatePercent: 44.5,
        revenueGrowthRatePercent: 14.2,
        visitsGrowthRatePercent: 9.8,
      ).toJson());
    });

    router.register('GET', 'analytics/revenue-trend', (req) async {
      final branchId = req.queryParameters['branchId']?.toString();
      if (branchId == 'branch_unknown' || branchId == 'non_existent') {
        return LocalServerRouter.ok(const <dynamic>[]);
      }
      final range = _parseRange(req.queryParameters['range']?.toString());
      final now = CairoTimeHelper.now();
      final points = <Map<String, dynamic>>[];
      final multiplier = branchId == 'branch_1'
          ? 1.0
          : branchId == 'branch_2'
              ? 0.65
              : branchId == 'branch_3'
                  ? 0.45
                  : 2.1;

      if (range == AnalyticsTimeRangeEnum.today) {
        for (int h = 9; h <= 21; h++) {
          final hourlyBase = ((h >= 11 && h <= 14) || (h >= 18 && h <= 21)) ? 140000 : 60000;
          final rev = (hourlyBase * multiplier).round();
          final doc = (rev * 0.45).round();
          points.add(RevenueTrendPointModel(
            label: '${h.toString().padLeft(2, '0')}:00',
            date: DateTime(now.year, now.month, now.day, h),
            revenuePiastres: rev,
            visitsCount: (rev / 40000).ceil(),
            doctorSharePiastres: doc,
            netProfitPiastres: rev - doc,
          ).toJson());
        }
      } else if (range == AnalyticsTimeRangeEnum.thisWeek) {
        final dayNames = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
        for (int i = 0; i < 7; i++) {
          final d = now.subtract(Duration(days: 6 - i));
          final dayRev = ((i == 6 ? 300000 : 650000 + (i * 35000)) * multiplier).round();
          final doc = (dayRev * 0.45).round();
          points.add(RevenueTrendPointModel(
            label: dayNames[i],
            date: d,
            revenuePiastres: dayRev,
            visitsCount: (dayRev / 35000).ceil(),
            doctorSharePiastres: doc,
            netProfitPiastres: dayRev - doc,
          ).toJson());
        }
      } else {
        for (int w = 1; w <= 4; w++) {
          final weekRev = ((4200000 + (w * 350000)) * multiplier).round();
          final doc = (weekRev * 0.45).round();
          points.add(RevenueTrendPointModel(
            label: 'الأسبوع $w',
            date: now.subtract(Duration(days: (4 - w) * 7)),
            revenuePiastres: weekRev,
            visitsCount: (weekRev / 35000).ceil(),
            doctorSharePiastres: doc,
            netProfitPiastres: weekRev - doc,
          ).toJson());
        }
      }
      return LocalServerRouter.ok(points);
    });

    router.register('GET', 'analytics/branch-comparison', (req) async {
      final items = [
        const BranchAnalyticsComparisonModel(
          branchId: 'branch_1',
          branchName: 'الفرع الرئيسي - المعادي',
          totalRevenuePiastres: 18500000,
          visitsCount: 420,
          occupancyRatePercent: 88.5,
          shareOfTotalRevenuePercent: 48.0,
        ).toJson(),
        const BranchAnalyticsComparisonModel(
          branchId: 'branch_2',
          branchName: 'فرع الجيزة - المهندسين',
          totalRevenuePiastres: 12000000,
          visitsCount: 275,
          occupancyRatePercent: 74.0,
          shareOfTotalRevenuePercent: 31.0,
        ).toJson(),
        const BranchAnalyticsComparisonModel(
          branchId: 'branch_3',
          branchName: 'فرع الإسكندرية - سموحة',
          totalRevenuePiastres: 8100000,
          visitsCount: 190,
          occupancyRatePercent: 62.5,
          shareOfTotalRevenuePercent: 21.0,
        ).toJson(),
      ];
      return LocalServerRouter.ok(items);
    });

    router.register('GET', 'analytics/doctor-performance', (req) async {
      final branchId = req.queryParameters['branchId']?.toString();
      if (branchId == 'branch_unknown' || branchId == 'non_existent') {
        return LocalServerRouter.ok(const <dynamic>[]);
      }
      final items = [
        const DoctorPerformanceMetricModel(
          doctorId: 'DOC-01',
          doctorName: 'د. سامي الجوهري',
          specialty: 'جلدية وتجميل',
          visitsCount: 94,
          revenueGeneratedPiastres: 7520000,
          doctorCommissionPiastres: 3760000,
          clinicSharePiastres: 3760000,
          avgConsultationDurationMinutes: 18,
          patientSatisfactionRating: 4.9,
        ).toJson(),
        const DoctorPerformanceMetricModel(
          doctorId: 'DOC-02',
          doctorName: 'د. هبة المنشاوي',
          specialty: 'طب الأسنان',
          visitsCount: 82,
          revenueGeneratedPiastres: 6150000,
          doctorCommissionPiastres: 2767500,
          clinicSharePiastres: 3382500,
          avgConsultationDurationMinutes: 28,
          patientSatisfactionRating: 4.8,
        ).toJson(),
        const DoctorPerformanceMetricModel(
          doctorId: 'DOC-03',
          doctorName: 'د. طارق العريان',
          specialty: 'عظام ومفاصل',
          visitsCount: 68,
          revenueGeneratedPiastres: 4420000,
          doctorCommissionPiastres: 2210000,
          clinicSharePiastres: 2210000,
          avgConsultationDurationMinutes: 22,
          patientSatisfactionRating: 4.7,
        ).toJson(),
        const DoctorPerformanceMetricModel(
          doctorId: 'DOC-04',
          doctorName: 'د. منى زكي',
          specialty: 'أطفال وحديثي ولادة',
          visitsCount: 75,
          revenueGeneratedPiastres: 3750000,
          doctorCommissionPiastres: 1500000,
          clinicSharePiastres: 2250000,
          avgConsultationDurationMinutes: 19,
          patientSatisfactionRating: 4.9,
        ).toJson(),
        const DoctorPerformanceMetricModel(
          doctorId: 'DOC-05',
          doctorName: 'د. وليد فواز',
          specialty: 'عيون وليزر',
          visitsCount: 54,
          revenueGeneratedPiastres: 4050000,
          doctorCommissionPiastres: 2025000,
          clinicSharePiastres: 2025000,
          avgConsultationDurationMinutes: 25,
          patientSatisfactionRating: 4.6,
        ).toJson(),
        const DoctorPerformanceMetricModel(
          doctorId: 'DOC-06',
          doctorName: 'د. رانيا يوسف',
          specialty: 'باطنة عامة وسكر',
          visitsCount: 62,
          revenueGeneratedPiastres: 3100000,
          doctorCommissionPiastres: 1240000,
          clinicSharePiastres: 1860000,
          avgConsultationDurationMinutes: 24,
          patientSatisfactionRating: 4.8,
        ).toJson(),
      ];
      return LocalServerRouter.ok(items);
    });

    router.register('GET', 'analytics/hourly-traffic', (req) async {
      final items = <Map<String, dynamic>>[];
      for (int h = 9; h <= 22; h++) {
        String level = 'low';
        int count = 4;
        if ((h >= 11 && h <= 13) || (h >= 18 && h <= 20)) {
          level = 'peak';
          count = 18;
        } else if (h >= 14 && h <= 17) {
          level = 'medium';
          count = 10;
        } else if (h >= 21) {
          level = 'medium';
          count = 8;
        }
        items.add(HourlyTrafficMetricModel(
          hour: h,
          dayOfWeek: 1,
          visitsCount: count,
          occupancyLevel: level,
        ).toJson());
      }
      return LocalServerRouter.ok(items);
    });

    router.register('GET', 'analytics/service-distribution', (req) async {
      final items = [
        const ServiceRevenueDistributionModel(
          serviceName: 'كشف استشاري تخصصي',
          category: 'كشوفات',
          count: 145,
          totalRevenuePiastres: 7250000,
          percentage: 39.2,
        ).toJson(),
        const ServiceRevenueDistributionModel(
          serviceName: 'كشف أخصائي',
          category: 'كشوفات',
          count: 120,
          totalRevenuePiastres: 3600000,
          percentage: 19.5,
        ).toJson(),
        const ServiceRevenueDistributionModel(
          serviceName: 'جلسة ليزر / إجراء سريري',
          category: 'إجراءات',
          count: 55,
          totalRevenuePiastres: 4400000,
          percentage: 23.8,
        ).toJson(),
        const ServiceRevenueDistributionModel(
          serviceName: 'استشارة ومتابعة دورية',
          category: 'متابعات',
          count: 85,
          totalRevenuePiastres: 1700000,
          percentage: 9.2,
        ).toJson(),
        const ServiceRevenueDistributionModel(
          serviceName: 'خدمات تشخيصية وفحوصات',
          category: 'تشخيص',
          count: 40,
          totalRevenuePiastres: 1550000,
          percentage: 8.3,
        ).toJson(),
      ];
      return LocalServerRouter.ok(items);
    });
  }
}
