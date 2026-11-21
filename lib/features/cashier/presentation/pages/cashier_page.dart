import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/animation/fade_transition_animation.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_cubit.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_state.dart';
import 'package:eyadty/features/cashier/presentation/widgets/active_shift_bar.dart';
import 'package:eyadty/features/cashier/presentation/widgets/cashier_metrics_section.dart';
import 'package:eyadty/features/cashier/presentation/widgets/payments_history_table.dart';
import 'package:eyadty/features/cashier/presentation/widgets/shift_history_table.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

class CashierPage extends StatelessWidget {
  const CashierPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CashierCubit>(
      create: (context) {
        final session = context.read<SessionCubit>().state;
        final branchId = session.activeBranchId ?? 'branch_1';
        final userId = session.currentUser?.id ?? '';
        return getIt<CashierCubit>()..init(branchId: branchId, userId: userId);
      },
      child: const _CashierPageView(),
    );
  }
}

class _CashierPageView extends StatefulWidget {
  const _CashierPageView();

  @override
  State<_CashierPageView> createState() => _CashierPageViewState();
}

class _CashierPageViewState extends State<_CashierPageView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionCubit, SessionState>(
      listenWhen: (prev, curr) =>
          prev.activeBranchId != curr.activeBranchId ||
          prev.currentUser?.id != curr.currentUser?.id,
      listener: (context, session) {
        final branchId = session.activeBranchId ?? 'branch_1';
        final userId = session.currentUser?.id ?? '';
        context.read<CashierCubit>().onBranchOrUserChanged(
              newBranchId: branchId,
              newUserId: userId,
            );
      },
      child: FadeTransitionAnimation(
        duration: const Duration(milliseconds: 300),
        child: Scaffold(
          backgroundColor: context.themeColors.scaffoldBackground,
          body: BlocBuilder<CashierCubit, CashierState>(
            builder: (context, state) {
              final colors = context.themeColors;
              if (state.status == RequestStatusEnum.loading &&
                  state.activeShift == null &&
                  state.shiftHistory.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(color: colors.primary),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    _buildHeader(context),
                    const SizedBox(height: 20),

                    // Active Shift Banner / Bar
                    ActiveShiftBar(
                      activeShift: state.activeShift,
                      onRefresh: () {
                        final session = context.read<SessionCubit>().state;
                        context.read<CashierCubit>().init(
                              branchId: session.activeBranchId ?? 'branch_1',
                              userId: session.currentUser?.id ?? '',
                            );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Metrics Section
                    CashierMetricsSection(
                      summaryMetrics: state.summaryMetrics,
                      activeShift: state.activeShift,
                    ),
                    const SizedBox(height: 24),

                    // Tab Selector & Tables
                    _buildTabsSection(context, state),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.themeColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'nav_cashier_header'.tr(),
              style: CustomAppFontStyle.bold20.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'nav_cashier_subtitle'.tr(),
              style: CustomAppFontStyle.regular13.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        CustomPushButton(
          height: 38,
          backgroundColor: colors.cardBackground,
          boxBorder: Border.all(color: colors.borderSubtle),
          borderRadius: BorderRadius.circular(10),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onTap: () {
            final session = context.read<SessionCubit>().state;
            context.read<CashierCubit>().init(
                  branchId: session.activeBranchId ?? 'branch_1',
                  userId: session.currentUser?.id ?? '',
                );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded,
                  color: colors.textPrimary, size: 16),
              const SizedBox(width: 6),
              Text(
                'تحديث',
                style: CustomAppFontStyle.medium12.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabsSection(BuildContext context, CashierState state) {
    final colors = context.themeColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab bar header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SizedBox(
              width: 380,
              child: TabBar(
                controller: _tabController,
                indicatorColor: colors.primary,
                indicatorWeight: 3,
                labelColor: colors.primary,
                unselectedLabelColor: colors.textSecondary,
                labelStyle: CustomAppFontStyle.bold14,
                unselectedLabelStyle: CustomAppFontStyle.medium14,
                tabs: [
                  Tab(text: 'cashier_payments_tab'.tr()),
                  Tab(text: 'cashier_shifts_history_tab'.tr()),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: colors.borderSubtle),

          // Tab views
          SizedBox(
            height: 480,
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  child: PaymentsHistoryTable(
                    payments: state.shiftPayments,
                  ),
                ),
                SingleChildScrollView(
                  child: ShiftHistoryTable(
                    shifts: state.shiftHistory,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
