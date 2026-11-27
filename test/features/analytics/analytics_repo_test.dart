import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/analytics/data/models/branch_analytics_comparison_model.dart';
import 'package:eyadty/features/analytics/data/models/doctor_performance_metric_model.dart';
import 'package:eyadty/features/analytics/data/models/enums/analytics_time_range_enum.dart';
import 'package:eyadty/features/analytics/data/models/hourly_traffic_metric_model.dart';
import 'package:eyadty/features/analytics/data/models/revenue_trend_point_model.dart';
import 'package:eyadty/features/analytics/data/models/service_revenue_distribution_model.dart';
import 'package:eyadty/features/analytics/data/repo/analytics_repo_impl.dart';

void main() {
  group('AnalyticsRepoImpl Unit Tests (Plan F-07 M-2)', () {
    late AnalyticsRepoImpl repo;

    setUp(() {
      CairoTimeHelper.setFixedClock(DateTime(2026, 11, 15, 12, 0, 0));
      repo = AnalyticsRepoImpl(seedInitialData: true);
    });

    tearDown(() {
      CairoTimeHelper.resetFixedClock();
    });

    // -------------------------------------------------------------------------
    // 1. Date Range Resolution Tests
    // -------------------------------------------------------------------------
    test('1. resolveDateRange for today returns start and end of current day', () {
      final range = repo.resolveDateRange(timeRange: AnalyticsTimeRangeEnum.today);
      expect(range.start, DateTime(2026, 11, 15, 0, 0, 0));
      expect(range.end, DateTime(2026, 11, 15, 23, 59, 59));
    });

    test('2. resolveDateRange for thisMonth returns 1st of month to end of month', () {
      final range = repo.resolveDateRange(timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(range.start, DateTime(2026, 11, 1, 0, 0, 0));
      expect(range.end.month, 11);
      expect(range.end.day, 30);
    });

    test('3. resolveDateRange for lastMonth returns full previous month bounds', () {
      final range = repo.resolveDateRange(timeRange: AnalyticsTimeRangeEnum.lastMonth);
      expect(range.start, DateTime(2026, 10, 1, 0, 0, 0));
      expect(range.end.month, 10);
      expect(range.end.day, 31);
    });

    test('4. resolveDateRange for custom respects passed bounds', () {
      final customStart = DateTime(2026, 9, 1);
      final customEnd = DateTime(2026, 9, 15);
      final range = repo.resolveDateRange(
        timeRange: AnalyticsTimeRangeEnum.custom,
        customStart: customStart,
        customEnd: customEnd,
      );
      expect(range.start, customStart);
      expect(range.end, customEnd);
    });

    // -------------------------------------------------------------------------
    // 2. Summary KPIs Tests
    // -------------------------------------------------------------------------
    test('5. getAnalyticsSummary returns valid KPI metrics for branch_1', () async {
      final result = await repo.getAnalyticsSummary(
        branchId: 'branch_1',
        timeRange: AnalyticsTimeRangeEnum.thisMonth,
      );

      expect(result.isRight(), isTrue);
      final summary = result.getOrElse(() => throw StateError(''));
      expect(summary.totalRevenuePiastres, 18500000);
      expect(summary.totalVisitsCount, 420);
      expect(summary.completedVisitsCount, (420 * 0.88).round());
      expect(summary.totalDoctorPayoutsPiastres, (18500000 * 0.45).round());
      expect(summary.netProfitPiastres, isNotNull);
      expect(summary.netProfitPiastres! > 0, isTrue);
    });

    test('6. getAnalyticsSummary scales correctly for branch_2 and branch_3', () async {
      final res2 = await repo.getAnalyticsSummary(
        branchId: 'branch_2',
        timeRange: AnalyticsTimeRangeEnum.thisMonth,
      );
      final res3 = await repo.getAnalyticsSummary(
        branchId: 'branch_3',
        timeRange: AnalyticsTimeRangeEnum.thisMonth,
      );

      final s2 = res2.getOrElse(() => throw StateError(''));
      final s3 = res3.getOrElse(() => throw StateError(''));

      expect(s2.totalRevenuePiastres! < 18500000, isTrue);
      expect(s3.totalRevenuePiastres! < s2.totalRevenuePiastres!, isTrue);
    });

    test('7. getAnalyticsSummary consolidated (null branchId) reflects multi-branch total', () async {
      final resAll = await repo.getAnalyticsSummary(
        branchId: null,
        timeRange: AnalyticsTimeRangeEnum.thisMonth,
      );

      final all = resAll.getOrElse(() => throw StateError(''));
      expect(all.totalRevenuePiastres! > 18500000, isTrue);
    });

    test('8. getAnalyticsSummary for today uses scaled day values', () async {
      final resDay = await repo.getAnalyticsSummary(
        branchId: 'branch_1',
        timeRange: AnalyticsTimeRangeEnum.today,
      );

      final sDay = resDay.getOrElse(() => throw StateError(''));
      expect(sDay.totalRevenuePiastres! < 18500000, isTrue);
      expect(sDay.totalVisitsCount! < 420, isTrue);
    });

    test('9. getAnalyticsSummary for unknown branch returns zero metrics', () async {
      final res = await repo.getAnalyticsSummary(
        branchId: 'branch_unknown',
        timeRange: AnalyticsTimeRangeEnum.thisMonth,
      );

      final s = res.getOrElse(() => throw StateError(''));
      expect(s.totalRevenuePiastres, 0);
      expect(s.totalVisitsCount, 0);
      expect(s.netProfitPiastres, 0);
    });

    // -------------------------------------------------------------------------
    // 3. Revenue Trend Tests
    // -------------------------------------------------------------------------
    test('10. getRevenueTrend for today returns hourly data points', () async {
      final res = await repo.getRevenueTrend(
        branchId: 'branch_1',
        timeRange: AnalyticsTimeRangeEnum.today,
      );

      expect(res.isRight(), isTrue);
      final list = res.getOrElse(() => []);
      expect(list.length, 13); // 09:00 to 21:00
      expect(list.first.label, '09:00');
      expect(list.last.label, '21:00');
    });

    test('11. getRevenueTrend for thisWeek returns 7 daily data points', () async {
      final res = await repo.getRevenueTrend(
        branchId: 'branch_1',
        timeRange: AnalyticsTimeRangeEnum.thisWeek,
      );

      final list = res.getOrElse(() => []);
      expect(list.length, 7);
      expect(list.any((p) => p.label == 'السبت'), isTrue);
    });

    test('12. getRevenueTrend for thisMonth returns 4 weekly aggregated points', () async {
      final res = await repo.getRevenueTrend(
        branchId: 'branch_1',
        timeRange: AnalyticsTimeRangeEnum.thisMonth,
      );

      final list = res.getOrElse(() => []);
      expect(list.length, 4);
      expect(list.first.label, 'الأسبوع 1');
    });

    test('13. getRevenueTrend for unknown branch returns empty list', () async {
      final res = await repo.getRevenueTrend(
        branchId: 'branch_unknown',
        timeRange: AnalyticsTimeRangeEnum.thisMonth,
      );

      expect(res.isRight(), isTrue);
      expect(res.getOrElse(() => [const RevenueTrendPointModel()]).isEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // 4. Branch Comparison Tests
    // -------------------------------------------------------------------------
    test('14. getBranchComparison returns all three official clinic branches', () async {
      final res = await repo.getBranchComparison(timeRange: AnalyticsTimeRangeEnum.thisMonth);

      expect(res.isRight(), isTrue);
      final branches = res.getOrElse(() => []);
      expect(branches.length, 3);

      expect(branches[0].branchId, 'branch_1');
      expect(branches[0].branchName, contains('المعادي'));

      expect(branches[1].branchId, 'branch_2');
      expect(branches[1].branchName, contains('المهندسين'));

      expect(branches[2].branchId, 'branch_3');
      expect(branches[2].branchName, contains('سموحة'));
    });

    test('15. getBranchComparison percentages sum up to 100%', () async {
      final res = await repo.getBranchComparison(timeRange: AnalyticsTimeRangeEnum.thisMonth);
      final branches = res.getOrElse(() => []);

      final totalShare = branches.fold<double>(0.0, (acc, b) => acc + (b.shareOfTotalRevenuePercent ?? 0));
      expect((totalShare - 100.0).abs() < 0.1, isTrue);
    });

    // -------------------------------------------------------------------------
    // 5. Doctor Performance Tests
    // -------------------------------------------------------------------------
    test('16. getDoctorPerformance returns ranked list of official doctors DOC-01 to DOC-06', () async {
      final res = await repo.getDoctorPerformance(timeRange: AnalyticsTimeRangeEnum.thisMonth);

      expect(res.isRight(), isTrue);
      final doctors = res.getOrElse(() => []);
      expect(doctors.length, 6);

      expect(doctors[0].doctorId, 'DOC-01');
      expect(doctors[0].doctorName, contains('سامي'));
      expect(doctors[0].revenueGeneratedPiastres, isNotNull);
      expect(doctors[0].doctorCommissionPiastres, isNotNull);
      expect(doctors[0].clinicSharePiastres, isNotNull);
    });

    test('17. getDoctorPerformance clinic and doctor share add up to revenue', () async {
      final res = await repo.getDoctorPerformance(timeRange: AnalyticsTimeRangeEnum.thisMonth);
      final doctors = res.getOrElse(() => []);

      for (final doc in doctors) {
        final sum = (doc.doctorCommissionPiastres ?? 0) + (doc.clinicSharePiastres ?? 0);
        expect(sum, doc.revenueGeneratedPiastres);
      }
    });

    test('18. getDoctorPerformance unknown branch returns empty list', () async {
      final res = await repo.getDoctorPerformance(
        branchId: 'non_existent',
        timeRange: AnalyticsTimeRangeEnum.thisMonth,
      );
      expect(res.getOrElse(() => [const DoctorPerformanceMetricModel()]).isEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // 6. Hourly Traffic Tests
    // -------------------------------------------------------------------------
    test('19. getHourlyTraffic returns clinic opening hours 09:00 to 22:00', () async {
      final res = await repo.getHourlyTraffic(timeRange: AnalyticsTimeRangeEnum.thisMonth);

      expect(res.isRight(), isTrue);
      final traffic = res.getOrElse(() => []);
      expect(traffic.length, 14); // 9 to 22
      expect(traffic.first.hour, 9);
      expect(traffic.last.hour, 22);
    });

    test('20. getHourlyTraffic marks peak hours accurately between 11-13 and 18-20', () async {
      final res = await repo.getHourlyTraffic(timeRange: AnalyticsTimeRangeEnum.thisMonth);
      final traffic = res.getOrElse(() => []);

      final peakHours = traffic.where((t) => t.occupancyLevel == 'peak').map((t) => t.hour).toList();
      expect(peakHours, contains(12));
      expect(peakHours, contains(19));
    });

    // -------------------------------------------------------------------------
    // 7. Service Distribution Tests
    // -------------------------------------------------------------------------
    test('21. getServiceDistribution returns top medical services', () async {
      final res = await repo.getServiceDistribution(timeRange: AnalyticsTimeRangeEnum.thisMonth);

      expect(res.isRight(), isTrue);
      final services = res.getOrElse(() => []);
      expect(services.length, 5);
      expect(services.first.serviceName, contains('كشف استشاري'));
    });

    test('22. getServiceDistribution percentages sum close to 100%', () async {
      final res = await repo.getServiceDistribution(timeRange: AnalyticsTimeRangeEnum.thisMonth);
      final services = res.getOrElse(() => []);

      final totalPercent = services.fold<double>(0.0, (acc, s) => acc + (s.percentage ?? 0));
      expect((totalPercent - 100.0).abs() < 0.5, isTrue);
    });

    // -------------------------------------------------------------------------
    // 8. Seed Initial Data Flag Tests
    // -------------------------------------------------------------------------
    test('23. Unseeded repo returns empty/default summary', () async {
      final unseededRepo = AnalyticsRepoImpl(seedInitialData: false);
      final res = await unseededRepo.getAnalyticsSummary(timeRange: AnalyticsTimeRangeEnum.today);
      expect(res.isRight(), isTrue);
      final summary = res.getOrElse(() => throw StateError(''));
      expect(summary.totalRevenuePiastres, isNull);
    });

    test('24. Unseeded repo returns empty list for trend and branches', () async {
      final unseededRepo = AnalyticsRepoImpl(seedInitialData: false);
      final trend = await unseededRepo.getRevenueTrend(timeRange: AnalyticsTimeRangeEnum.today);
      final branches = await unseededRepo.getBranchComparison(timeRange: AnalyticsTimeRangeEnum.today);

      expect(trend.getOrElse(() => [const RevenueTrendPointModel()]).isEmpty, isTrue);
      expect(branches.getOrElse(() => [const BranchAnalyticsComparisonModel()]).isEmpty, isTrue);
    });

    test('25. Unseeded repo returns empty list for doctors, traffic, and services', () async {
      final unseededRepo = AnalyticsRepoImpl(seedInitialData: false);
      final docs = await unseededRepo.getDoctorPerformance(timeRange: AnalyticsTimeRangeEnum.today);
      final traffic = await unseededRepo.getHourlyTraffic(timeRange: AnalyticsTimeRangeEnum.today);
      final services = await unseededRepo.getServiceDistribution(timeRange: AnalyticsTimeRangeEnum.today);

      expect(docs.getOrElse(() => [const DoctorPerformanceMetricModel()]).isEmpty, isTrue);
      expect(traffic.getOrElse(() => [const HourlyTrafficMetricModel()]).isEmpty, isTrue);
      expect(services.getOrElse(() => [const ServiceRevenueDistributionModel()]).isEmpty, isTrue);
    });
  });
}
