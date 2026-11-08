import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/layout_adaptive/widgets/custom_side_bar.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';

List<SideBarItemModel> layoutItems(BuildContext context) {
  var allItems = [
    // ═══════════════════════════════════════════════════════════════════════════
    // 1. العمليات (Operations)
    // ═══════════════════════════════════════════════════════════════════════════
    SideBarItemModel(
      groupTitle: 'nav_group_operations'.tr(),
      staffPermission: StaffPermissionEnum.accessLiveQueue,
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
    SideBarItemModel(
      groupTitle: 'nav_group_operations'.tr(),
      staffPermission: StaffPermissionEnum.accessPatients,
      title: 'nav_patients'.tr(),
      iconPath: AppIcons.users,
      id: 'patients',
      selectedIconPath: AppIcons.users,
      routePath: AppRouter.patients,
      header: 'nav_patients_header'.tr(),
      subtitle: 'nav_patients_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.patients);
      },
    ),
    SideBarItemModel(
      groupTitle: 'nav_group_operations'.tr(),
      staffPermission: StaffPermissionEnum.viewMedicalRecordDiagnostics,
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

    // ═══════════════════════════════════════════════════════════════════════════
    // 2. المال (Finance)
    // ═══════════════════════════════════════════════════════════════════════════
    SideBarItemModel(
      groupTitle: 'nav_group_finance'.tr(),
      staffPermission: StaffPermissionEnum.accessCashier,
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

    // ═══════════════════════════════════════════════════════════════════════════
    // 3. الفريق (Team)
    // ═══════════════════════════════════════════════════════════════════════════
    SideBarItemModel(
      groupTitle: 'nav_group_team'.tr(),
      staffPermission: StaffPermissionEnum.accessDoctors,
      title: 'nav_doctors'.tr(),
      iconPath: AppIcons.team,
      id: 'doctors',
      selectedIconPath: AppIcons.team,
      routePath: AppRouter.doctors,
      header: 'nav_doctors_header'.tr(),
      subtitle: 'nav_doctors_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.doctors);
      },
    ),
    SideBarItemModel(
      groupTitle: 'nav_group_team'.tr(),
      staffPermission: StaffPermissionEnum.accessHr,
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

    // ═══════════════════════════════════════════════════════════════════════════
    // 4. التقارير (Reports)
    // ═══════════════════════════════════════════════════════════════════════════
    SideBarItemModel(
      groupTitle: 'nav_group_reports'.tr(),
      staffPermission: StaffPermissionEnum.accessAnalytics,
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

    // ═══════════════════════════════════════════════════════════════════════════
    // 5. الإعداد (Settings)
    // ═══════════════════════════════════════════════════════════════════════════
    SideBarItemModel(
      groupTitle: 'nav_group_settings'.tr(),
      staffPermission: StaffPermissionEnum.accessSettings,
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
    SideBarItemModel(
      groupTitle: 'nav_group_settings'.tr(),
      staffPermission: StaffPermissionEnum.manageRolesAndPermissions,
      title: 'users_nav_title'.tr(),
      iconPath: AppIcons.users,
      id: 'users_management',
      selectedIconPath: AppIcons.users,
      routePath: AppRouter.usersManagement,
      header: 'users_nav_title'.tr(),
      subtitle: 'users_nav_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.usersManagement);
      },
    ),
    SideBarItemModel(
      groupTitle: 'nav_group_settings'.tr(),
      staffPermission: StaffPermissionEnum.viewAuditLogs,
      title: 'audit_logs_nav_title'.tr(),
      iconPath: AppIcons.lock,
      id: 'audit_logs',
      selectedIconPath: AppIcons.lock,
      routePath: AppRouter.auditLogs,
      header: 'audit_logs_nav_title'.tr(),
      subtitle: 'audit_logs_nav_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.auditLogs);
      },
    ),
  ];

  // Dynamic Filtering based on Session Permissions
  if (getIt.isRegistered<SessionCubit>()) {
    final session = getIt<SessionCubit>();
    if (session.state.currentUser != null) {
      allItems = allItems
          .where((item) =>
              item.staffPermission == null ||
              session.can(item.staffPermission! as StaffPermissionEnum))
          .toList();
    }
  }

  return allItems;
}
