import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_state.dart';
import 'package:eyadty/features/settings/presentation/widgets/tabs/company_info_tab.dart';
import 'package:eyadty/features/settings/presentation/widgets/tabs/branches_management_tab.dart';
import 'package:eyadty/features/settings/presentation/widgets/tabs/default_pricing_tab.dart';
import 'package:eyadty/features/settings/presentation/widgets/tabs/special_holidays_tab.dart';
import 'package:eyadty/features/settings/presentation/widgets/tabs/working_schedule_tab.dart';
import 'package:eyadty/features/settings/presentation/widgets/services/medical_services_tab.dart';
import 'package:eyadty/features/settings/presentation/widgets/doctors_schedule/doctors_schedule_tab.dart';
import 'package:eyadty/features/settings/presentation/widgets/tabs/print_settings_tab.dart';
import 'package:eyadty/features/settings/presentation/widgets/tabs/security_privacy_tab.dart';
import 'package:eyadty/features/settings/presentation/widgets/tabs/theme_appearance_tab.dart';
import 'package:eyadty/features/settings/presentation/widgets/prescription_template/prescription_template_designer.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_shimmer_container.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';

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

class _SettingsCategoryItem {
  final String id;
  final String title;
  final String icon;
  final IconData fallbackIcon;
  final List<_SettingsSubTabItem> subTabs;

  const _SettingsCategoryItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.fallbackIcon,
    required this.subTabs,
  });
}

class _SettingsSubTabItem {
  final String id;
  final String title;
  final String icon;
  final IconData fallbackIcon;
  final Widget Function(SettingsCubit cubit) builder;

  const _SettingsSubTabItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.fallbackIcon,
    required this.builder,
  });
}

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  int _selectedCategoryIndex = 0;
  int _selectedSubTabIndex = 0;

  late final List<_SettingsCategoryItem> _categories;

  @override
  void initState() {
    super.initState();
    _initCategories();
  }

  void _initCategories() {
    _categories = [
      _SettingsCategoryItem(
        id: 'facility_and_branches',
        title: 'المنشأة والفروع',
        icon: AppIcons.company,
        fallbackIcon: Icons.business_rounded,
        subTabs: [
          _SettingsSubTabItem(
            id: 'company_info',
            title: 'بيانات وترخيص المنشأة',
            icon: AppIcons.company,
            fallbackIcon: Icons.apartment_rounded,
            builder: (cubit) => CompanyInfoTab(settingsCubit: cubit),
          ),
          _SettingsSubTabItem(
            id: 'branches',
            title: 'إدارة الفروع والمقرات',
            icon: AppIcons.location,
            fallbackIcon: Icons.location_on_outlined,
            builder: (_) => const BranchesManagementTab(),
          ),
        ],
      ),
      _SettingsCategoryItem(
        id: 'schedules_and_operations',
        title: 'المواعيد والدوام',
        icon: AppIcons.clock,
        fallbackIcon: Icons.access_time_rounded,
        subTabs: [
          _SettingsSubTabItem(
            id: 'working_schedule',
            title: 'جدول ومواعيد العمل العامة',
            icon: AppIcons.clock,
            fallbackIcon: Icons.schedule_rounded,
            builder: (cubit) => WorkingScheduleTab(settingsCubit: cubit),
          ),
          _SettingsSubTabItem(
            id: 'doctors_schedule',
            title: 'دوام الأطباء والعيادات',
            icon: AppIcons.calendar,
            fallbackIcon: Icons.badge_outlined,
            builder: (_) => const DoctorsScheduleTab(),
          ),
          _SettingsSubTabItem(
            id: 'special_holidays',
            title: 'العطلات الرسمية والإجازات',
            icon: AppIcons.calendar,
            fallbackIcon: Icons.event_busy_outlined,
            builder: (cubit) => SpecialHolidaysTab(settingsCubit: cubit),
          ),
        ],
      ),
      _SettingsCategoryItem(
        id: 'services_and_pricing',
        title: 'الخدمات والتسعير',
        icon: AppIcons.service,
        fallbackIcon: Icons.medical_services_rounded,
        subTabs: [
          _SettingsSubTabItem(
            id: 'medical_services',
            title: 'دليل الخدمات الطبية',
            icon: AppIcons.service,
            fallbackIcon: Icons.health_and_safety_outlined,
            builder: (_) => const MedicalServicesTab(),
          ),
          _SettingsSubTabItem(
            id: 'default_pricing',
            title: 'التسعير الافتراضي للخدمات',
            icon: AppIcons.money,
            fallbackIcon: Icons.payments_outlined,
            builder: (cubit) => DefaultPricingTab(settingsCubit: cubit),
          ),
        ],
      ),
      _SettingsCategoryItem(
        id: 'print_and_prescriptions',
        title: 'قوالب الروشتة والطباعة',
        icon: AppIcons.transactions,
        fallbackIcon: Icons.print_rounded,
        subTabs: [
          _SettingsSubTabItem(
            id: 'prescription_designer',
            title: 'مصمم قوالب الروشتة (Rx Designer)',
            icon: AppIcons.transactions,
            fallbackIcon: Icons.assignment_outlined,
            builder: (cubit) => PrescriptionTemplateDesigner(settingsCubit: cubit),
          ),
          _SettingsSubTabItem(
            id: 'print_formats',
            title: 'أحجام الطباعة والفواتير الحرارية',
            icon: AppIcons.transactions,
            fallbackIcon: Icons.receipt_long_outlined,
            builder: (cubit) => PrintSettingsTab(settingsCubit: cubit),
          ),
        ],
      ),
      _SettingsCategoryItem(
        id: 'security_and_appearance',
        title: 'الأمان والنظام',
        icon: AppIcons.lock,
        fallbackIcon: Icons.shield_outlined,
        subTabs: [
          _SettingsSubTabItem(
            id: 'security_privacy',
            title: 'الأمان والخصوصية وسجل الدخول',
            icon: AppIcons.lock,
            fallbackIcon: Icons.lock_outline_rounded,
            builder: (_) => const SecurityPrivacyTab(),
          ),
          _SettingsSubTabItem(
            id: 'theme_appearance',
            title: 'المظهر وسمات الشاشة',
            icon: AppIcons.change,
            fallbackIcon: Icons.palette_outlined,
            builder: (_) => const ThemeAppearanceTab(),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final colors = context.themeColors;
    final isMobile = AdaptiveLayout.isMobile(context);
    final horizontalPadding = AdaptiveLayout.getResponsiveValue(
      context: context,
      mobile: 8.0,
      tablet: 16.0,
      desktop: 24.0,
    );

    return BlocConsumer<SettingsCubit, SettingsState>(
      listenWhen: (prev, curr) => prev.selectedTab != curr.selectedTab,
      listener: (context, state) {
        // Sync flat tab index with category hierarchy if triggered externally
        _syncFromFlatIndex(state.selectedTab);
      },
      builder: (context, state) {
        if (state.status == RequestStatusEnum.loading && state.settings == null) {
          return _buildLoadingShimmer();
        }

        if (state.status == RequestStatusEnum.failure && state.settings == null) {
          return _buildErrorView(cubit);
        }

        final currentCategory = _categories[_selectedCategoryIndex];
        final currentSubTab = currentCategory.subTabs[_selectedSubTabIndex];

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isMobile ? 8 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. Primary Category Navigation Bar ───────────────────────
              _buildCategoryNavigationBar(colors, isMobile),

              SizedBox(height: isMobile ? 8 : 12),

              // ─── 2. Sub-Tabs Bar For Selected Category ────────────────────
              _buildSubTabsBar(colors, isMobile, currentCategory),

              SizedBox(height: isMobile ? 10 : 14),

              // ─── 3. Active Tab Content Area ──────────────────────────────
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey('${currentCategory.id}_${currentSubTab.id}'),
                  child: currentSubTab.builder(cubit),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryNavigationBar(dynamic colors, bool isMobile) {
    return CustomContainer(
      border: Border.all(color: colors.borderSubtle),
      backGroundColor: colors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 10,
        vertical: isMobile ? 6 : 8,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(_categories.length, (idx) {
            final cat = _categories[idx];
            final isSelected = _selectedCategoryIndex == idx;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () {
                  if (_selectedCategoryIndex != idx) {
                    setState(() {
                      _selectedCategoryIndex = idx;
                      _selectedSubTabIndex = 0;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(9),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 14,
                    vertical: isMobile ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary
                        : colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.borderSubtle,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (colors.primary as Color).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomAssetImage(
                        path: cat.icon,
                        width: 17,
                        height: 17,
                        color: isSelected ? AppColors.white : colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat.title,
                        style: (isSelected
                                ? CustomAppFontStyle.semiBold14
                                : CustomAppFontStyle.medium14)
                            .copyWith(
                          color: isSelected ? AppColors.white : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.white.withValues(alpha: 0.22)
                              : colors.borderSubtle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${cat.subTabs.length}',
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: isSelected ? AppColors.white : colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSubTabsBar(
    dynamic colors,
    bool isMobile,
    _SettingsCategoryItem currentCategory,
  ) {
    if (currentCategory.subTabs.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(currentCategory.subTabs.length, (idx) {
            final subTab = currentCategory.subTabs[idx];
            final isSelected = _selectedSubTabIndex == idx;

            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: InkWell(
                onTap: () {
                  if (_selectedSubTabIndex != idx) {
                    setState(() {
                      _selectedSubTabIndex = idx;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (colors.primary as Color).withValues(alpha: 0.12)
                        : colors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.borderSubtle,
                      width: isSelected ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomAssetImage(
                        path: subTab.icon,
                        width: 15,
                        height: 15,
                        color: isSelected ? colors.primary : colors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subTab.title,
                        style: (isSelected
                                ? CustomAppFontStyle.semiBold14
                                : CustomAppFontStyle.regular14)
                            .copyWith(
                          color: isSelected ? colors.primary : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _syncFromFlatIndex(int flatIndex) {
    // Map flat index:
    // 0: Company Info -> Cat 0, Sub 0
    // 1: Branches -> Cat 0, Sub 1
    // 2: Working Schedule -> Cat 1, Sub 0
    // 3: Pricing -> Cat 2, Sub 1
    // 4: Special Holidays -> Cat 1, Sub 2
    // 5: Medical Services -> Cat 2, Sub 0
    // 6: Doctors Schedule -> Cat 1, Sub 1
    // 7: Print Settings -> Cat 3, Sub 0
    // 8: Security Privacy -> Cat 4, Sub 0
    // 9: Theme Appearance -> Cat 4, Sub 1
    int catIdx = 0;
    int subIdx = 0;
    switch (flatIndex) {
      case 0:
        catIdx = 0;
        subIdx = 0;
        break;
      case 1:
        catIdx = 0;
        subIdx = 1;
        break;
      case 2:
        catIdx = 1;
        subIdx = 0;
        break;
      case 3:
        catIdx = 2;
        subIdx = 1;
        break;
      case 4:
        catIdx = 1;
        subIdx = 2;
        break;
      case 5:
        catIdx = 2;
        subIdx = 0;
        break;
      case 6:
        catIdx = 1;
        subIdx = 1;
        break;
      case 7:
        catIdx = 3;
        subIdx = 0;
        break;
      case 8:
        catIdx = 4;
        subIdx = 0;
        break;
      case 9:
        catIdx = 4;
        subIdx = 1;
        break;
      default:
        return;
    }
    setState(() {
      _selectedCategoryIndex = catIdx;
      _selectedSubTabIndex = subIdx;
    });
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
