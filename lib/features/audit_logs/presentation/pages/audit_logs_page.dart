import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/custom_empty_widget.dart';
import '../../../../shared/widgets/custom_shimmer_container.dart';
import '../../../../shared/widgets/error_page.dart';
import '../cubit/audit_logs_cubit.dart';
import '../cubit/audit_logs_state.dart';
import '../widgets/audit_logs_filter_bar.dart';
import '../widgets/audit_logs_table.dart';

class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AuditLogsCubit>()..loadLogs(),
      child: const _AuditLogsView(),
    );
  }
}

class _AuditLogsView extends StatelessWidget {
  const _AuditLogsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: BlocBuilder<AuditLogsCubit, AuditLogsState>(
        builder: (context, state) {
          final cubit = context.read<AuditLogsCubit>();

          return RefreshIndicator(
            onRefresh: () async => cubit.loadLogs(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(context, cubit, state),
                  const SizedBox(height: 16),

                  // Summary Stat Cards
                  _buildSummaryCards(context, state),
                  const SizedBox(height: 16),

                  // Filter Bar
                  AuditLogsFilterBar(cubit: cubit, state: state),
                  const SizedBox(height: 16),

                  // Main Content (Table / Empty / Loading / Error)
                  _buildContent(context, cubit, state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AuditLogsCubit cubit,
    AuditLogsState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'audit_logs_title'.tr(),
                  style: CustomAppFontStyle.bold18.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'audit_logs_desc'.tr(),
                  style: CustomAppFontStyle.regular12.copyWith(
                    color: AppColors.gray71717A,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => cubit.loadLogs(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, AuditLogsState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 750;

        final items = [
          _StatCardItem(
            title: 'إجمالي السجلات',
            count: state.totalEventsCount,
            icon: Icons.list_alt_rounded,
            color: const Color(0xFF6366F1),
          ),
          _StatCardItem(
            title: 'عمليات الأمان',
            count: state.securityEventsCount,
            icon: Icons.lock_outline_rounded,
            color: const Color(0xFFE54848),
          ),
          _StatCardItem(
            title: 'استعراض ملفات المرضى',
            count: state.patientAccessCount,
            icon: Icons.visibility_outlined,
            color: const Color(0xFF0EA5E9),
          ),
          _StatCardItem(
            title: 'عمليات الفروع',
            count: state.branchOperationsCount,
            icon: Icons.storefront_outlined,
            color: const Color(0xFF10B981),
          ),
        ];

        if (isCompact) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((it) => SizedBox(
              width: (constraints.maxWidth - 10) / 2,
              child: _buildStatCard(it),
            )).toList(),
          );
        }

        return Row(
          children: items.map((it) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _buildStatCard(it),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatCard(_StatCardItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: CustomAppFontStyle.regular11.copyWith(
                    color: AppColors.gray71717A,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.count}',
                  style: CustomAppFontStyle.bold16.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AuditLogsCubit cubit,
    AuditLogsState state,
  ) {
    if (state.status == RequestStatusEnum.loading && state.logs.isEmpty) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, _) => const CustomShimmerContainer(
          width: double.infinity,
          height: 52,
          borderRadius: 10,
        ),
      );
    }

    if (state.status == RequestStatusEnum.failure && state.logs.isEmpty) {
      return ErrorPage(
        onPressed: () => cubit.loadLogs(),
      );
    }

    final filtered = state.filteredLogs;

    if (filtered.isEmpty) {
      return CustomEmptyWidget(
        title: 'no_audit_logs_found'.tr(),
        subtitle: Text(
          'no_audit_logs_desc'.tr(),
          style: CustomAppFontStyle.regular13.copyWith(
            color: AppColors.gray71717A,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: AuditLogsTable(logs: filtered),
    );
  }
}

class _StatCardItem {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCardItem({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });
}
