import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purexo/core/dependency_injection/dependency_injection.dart';
import 'package:purexo/core/utils/enums/request_status_enum.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:purexo/features/settings/presentation/cubit/settings_state.dart';
import 'package:purexo/features/settings/presentation/widgets/tabs/company_info_tab.dart';
import 'package:purexo/features/settings/presentation/widgets/tabs/default_pricing_tab.dart';
import 'package:purexo/features/settings/presentation/widgets/tabs/special_holidays_tab.dart';
import 'package:purexo/features/settings/presentation/widgets/tabs/working_schedule_tab.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'package:purexo/shared/widgets/custom_container.dart';
import 'package:purexo/shared/widgets/custom_push_container_button.dart';
import 'package:purexo/shared/widgets/custom_shimmer_container.dart';
import 'package:purexo/shared/widgets/custom_tab_bar.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => getIt<SettingsCubit>()..init(),
        child: const SettingsView(),
      ),
    );
  }
}

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<String> _tabIcons = [
    AppIcons.company,
    AppIcons.clock,
    AppIcons.money,
    AppIcons.calendar,
  ];

  List<String> get _tabs => [
    'tab_company_info'.tr(),
    'tab_working_schedule'.tr(),
    'tab_pricing'.tr(),
    'tab_special_holidays'.tr(),
    // 'tab_notifications'.tr(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    context.read<SettingsCubit>().changeTab(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final isMobile = AdaptiveLayout.isMobile(context);
    final horizontalPadding = AdaptiveLayout.getResponsiveValue(
      context: context,
      mobile: 4.0,
      tablet: 16.0,
      desktop: 24.0,
    );

    return BlocConsumer<SettingsCubit, SettingsState>(
      listenWhen: (prev, curr) => prev.selectedTab != curr.selectedTab,
      listener: (context, state) {
        if (_tabController.index != state.selectedTab) {
          _tabController.animateTo(state.selectedTab);
        }
      },
      builder: (context, state) {
        if (state.status == RequestStatusEnum.loading &&
            state.settings == null) {
          return _buildLoadingShimmer();
        }

        if (state.status == RequestStatusEnum.failure &&
            state.settings == null) {
          return _buildErrorView(cubit);
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isMobile ? 12 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Custom Tab Bar Header ──────────────────────────────────
              CustomContainer(
                border: Border.all(color: AppColors.grayE2E8F0),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 16,
                  vertical: isMobile ? 8 : 12,
                ),
                child: CustomTabBar(
                  tabs: _tabs,
                  icons: _tabIcons,
                  controller: _tabController,
                  height: isMobile ? 46 : 42,
                  radius: 8,
                  labelPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 3 : 4,
                  ),
                  tabPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 6 : 8,
                  ),
                  textStyle:
                      (isMobile
                              ? CustomAppFontStyle.medium14
                              : CustomAppFontStyle.regular16)
                          .copyWith(color: AppColors.gray334155),
                  selectedTextStyle:
                      (isMobile
                              ? CustomAppFontStyle.semiBold14
                              : CustomAppFontStyle.semiBold16)
                          .copyWith(color: AppColors.white),
                ),
              ),

              SizedBox(height: isMobile ? 12 : 16),

              // ─── Active Tab Content ─────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    CompanyInfoTab(settingsCubit: cubit),
                    WorkingScheduleTab(settingsCubit: cubit),
                    DefaultPricingTab(settingsCubit: cubit),
                    SpecialHolidaysTab(settingsCubit: cubit),
                    // NotificationsTab(settingsCubit: cubit),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          CustomShimmerContainer(
            height: 60,
            width: double.infinity,
            borderRadius: 12,
          ),
          SizedBox(height: 24),
          CustomShimmerContainer(
            height: 450,
            width: double.infinity,
            borderRadius: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(SettingsCubit cubit) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'failed_to_load'.tr(),
            style: CustomAppFontStyle.semiBold18.copyWith(
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          CustomPushButton(
            height: 42,
            width: 140,
            backgroundColor: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            onTap: cubit.fetchSettings,
            child: Center(
              child: Text(
                'retry'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
