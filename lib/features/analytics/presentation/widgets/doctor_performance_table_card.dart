import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../cashier/domain/helpers/money.dart';
import '../manager/analytics_cubit.dart';
import '../manager/analytics_state.dart';
import 'shimmers/analytics_chart_shimmer.dart';

class DoctorPerformanceTableCard extends StatelessWidget {
  const DoctorPerformanceTableCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      buildWhen: (prev, current) =>
          prev.doctorsStatus != current.doctorsStatus ||
          prev.doctorPerformances != current.doctorPerformances,
      builder: (context, state) {
        final colors = context.themeColors;

        if (state.doctorsStatus == RequestStatusEnum.loading && state.doctorPerformances.isEmpty) {
          return const AnalyticsChartShimmer(height: 380);
        }

        if (state.doctorsStatus == RequestStatusEnum.failure && state.doctorPerformances.isEmpty) {
          return Container(
            height: 200,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    state.doctorsError ?? 'analytics_load_error'.tr(),
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.read<AnalyticsCubit>().loadDoctorPerformance(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text('retry'.tr()),
                  ),
                ],
              ),
            ),
          );
        }

        final doctors = state.doctorPerformances;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'analytics_doctor_leaderboard_title'.tr(),
                style: CustomAppFontStyle.bold16.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'analytics_doctor_leaderboard_subtitle'.tr(),
                style: CustomAppFontStyle.regular12.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 20),
              if (doctors.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text(
                      'no_data'.tr(),
                      style: CustomAppFontStyle.regular13.copyWith(color: colors.textSecondary),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    horizontalMargin: 12,
                    columnSpacing: 24,
                    headingRowHeight: 44,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 56,
                    columns: [
                      DataColumn(label: Text('analytics_col_doctor'.tr(), style: CustomAppFontStyle.bold13)),
                      DataColumn(label: Text('analytics_col_specialty'.tr(), style: CustomAppFontStyle.bold13)),
                      DataColumn(label: Text('analytics_col_visits'.tr(), style: CustomAppFontStyle.bold13), numeric: true),
                      DataColumn(label: Text('analytics_col_revenue'.tr(), style: CustomAppFontStyle.bold13), numeric: true),
                      DataColumn(label: Text('analytics_col_commission'.tr(), style: CustomAppFontStyle.bold13), numeric: true),
                      DataColumn(label: Text('analytics_col_avg_duration'.tr(), style: CustomAppFontStyle.bold13)),
                      DataColumn(label: Text('analytics_col_satisfaction'.tr(), style: CustomAppFontStyle.bold13)),
                    ],
                    rows: [
                      for (int i = 0; i < doctors.length; i++)
                        DataRow(
                          cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: i == 0
                                        ? const Color(0xFFFEF3C7)
                                        : i == 1
                                            ? const Color(0xFFF1F5F9)
                                            : const Color(0xFFFDEEEB),
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: i == 0
                                            ? const Color(0xFFD97706)
                                            : AppColors.pitchBlack,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    doctors[i].doctorName ?? '',
                                    style: CustomAppFontStyle.bold13.copyWith(color: colors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(doctors[i].specialty ?? '—', style: CustomAppFontStyle.regular13.copyWith(color: colors.textSecondary))),
                            DataCell(Text('${doctors[i].visitsCount ?? 0}', style: CustomAppFontStyle.bold13.copyWith(color: colors.textPrimary))),
                            DataCell(
                              Text(
                                doctors[i].revenueGeneratedPiastres != null
                                    ? Money.fromPiastres(doctors[i].revenueGeneratedPiastres!).formatEgp()
                                    : '—',
                                style: CustomAppFontStyle.bold13.copyWith(color: colors.textPrimary),
                              ),
                            ),
                            DataCell(
                              Text(
                                doctors[i].doctorCommissionPiastres != null
                                    ? Money.fromPiastres(doctors[i].doctorCommissionPiastres!).formatEgp()
                                    : '—',
                                style: CustomAppFontStyle.bold13.copyWith(color: colors.primary),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${doctors[i].avgConsultationDurationMinutes ?? 0} ${'minutes_short'.tr()}',
                                style: CustomAppFontStyle.regular13.copyWith(color: colors.textSecondary),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    doctors[i].patientSatisfactionRating?.toStringAsFixed(1) ?? '—',
                                    style: CustomAppFontStyle.bold13,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

