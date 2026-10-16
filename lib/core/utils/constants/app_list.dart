import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/layout_adaptive/widgets/custom_side_bar.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';

List<SideBarItemModel> layoutItems(BuildContext context) {
  return [
    // 1. Live Queue & Appointments
    SideBarItemModel(
      title: 'nav_queue'.tr(),
      iconPath: AppIcons.calendar,
      id: 'queue',
      selectedIconPath: AppIcons.calendar,
      routePath: AppRouter.bookings,
      header: 'nav_queue_header'.tr(),
      subtitle: 'nav_queue_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.bookings);
      },
    ),

    // 2. Patients & Unified EMR
    SideBarItemModel(
      title: 'nav_patients'.tr(),
      iconPath: AppIcons.users,
      id: 'patients',
      selectedIconPath: AppIcons.users,
      routePath: AppRouter.customers,
      header: 'nav_patients_header'.tr(),
      subtitle: 'nav_patients_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.customers);
      },
    ),

    // 3. Clinical Visits & Prescriptions
    SideBarItemModel(
      title: 'nav_visits'.tr(),
      iconPath: AppIcons.file,
      id: 'visits',
      selectedIconPath: AppIcons.file,
      routePath: AppRouter.visits,
      header: 'nav_visits_header'.tr(),
      subtitle: 'nav_visits_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.visits);
      },
    ),

    // 4. Doctors & Staff Schedules
    SideBarItemModel(
      title: 'nav_doctors'.tr(),
      iconPath: AppIcons.team,
      id: 'doctors',
      selectedIconPath: AppIcons.team,
      routePath: AppRouter.technicians,
      header: 'nav_doctors_header'.tr(),
      subtitle: 'nav_doctors_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.technicians);
      },
    ),

    // 5. Cashier & Shift Drawer
    SideBarItemModel(
      title: 'nav_cashier'.tr(),
      iconPath: AppIcons.wallet,
      id: 'cashier',
      selectedIconPath: AppIcons.wallet,
      routePath: AppRouter.cashier,
      header: 'nav_cashier_header'.tr(),
      subtitle: 'nav_cashier_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.cashier);
      },
    ),

    // 6. HR & Doctor Settlements
    SideBarItemModel(
      title: 'nav_hr'.tr(),
      iconPath: AppIcons.percentage,
      id: 'hr',
      selectedIconPath: AppIcons.percentage,
      routePath: AppRouter.hr,
      header: 'nav_hr_header'.tr(),
      subtitle: 'nav_hr_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.hr);
      },
    ),

    // 7. Executive Analytics & Statistics
    SideBarItemModel(
      title: 'nav_analytics'.tr(),
      iconPath: AppIcons.dashboard,
      id: 'analytics',
      selectedIconPath: AppIcons.dashboard,
      routePath: AppRouter.analytics,
      header: 'nav_analytics_header'.tr(),
      subtitle: 'nav_analytics_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.analytics);
      },
    ),

    // 8. Facility & Multi-Branch Settings
    SideBarItemModel(
      title: 'nav_settings'.tr(),
      iconPath: AppIcons.settings,
      id: 'settings',
      selectedIconPath: AppIcons.settings,
      routePath: AppRouter.settings,
      header: 'nav_settings_header'.tr(),
      subtitle: 'nav_settings_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.settings);
      },
    ),
  ];
}
