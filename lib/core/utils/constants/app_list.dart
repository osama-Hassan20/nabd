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
      staffPermission: StaffPermissionEnum.viewVisitsQueue,
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
    // 2. الإدارة الطبية (Medical Management)
    // ═══════════════════════════════════════════════════════════════════════════
    SideBarItemModel(
      groupTitle: 'nav_group_medical'.tr(),
      staffPermission: StaffPermissionEnum.manageDrugCatalog,
      title: 'nav_drugs'.tr(),
      iconPath: AppIcons.drugs,
      id: 'drugs',
      selectedIconPath: AppIcons.drugs,
      routePath: AppRouter.drugs,
      header: 'nav_drugs_header'.tr(),
      subtitle: 'nav_drugs_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.drugs);
      },
    ),
    SideBarItemModel(
      groupTitle: 'nav_group_medical'.tr(),
      staffPermission: StaffPermissionEnum.manageDrugCatalog,
      title: 'nav_radiology'.tr(),
      iconPath: AppIcons.radiology,
      id: 'radiology',
      selectedIconPath: AppIcons.radiology,
      routePath: AppRouter.radiology,
      header: 'nav_radiology_header'.tr(),
      subtitle: 'nav_radiology_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.radiology);
      },
    ),
    SideBarItemModel(
      groupTitle: 'nav_group_medical'.tr(),
      staffPermission: StaffPermissionEnum.manageDrugCatalog,
      title: 'nav_lab_tests'.tr(),
      iconPath: AppIcons.labTests,
      id: 'lab_tests',
      selectedIconPath: AppIcons.labTests,
      routePath: AppRouter.labTests,
      header: 'nav_lab_tests_header'.tr(),
      subtitle: 'nav_lab_tests_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.labTests);
      },
    ),
    SideBarItemModel(
      groupTitle: 'nav_group_medical'.tr(),
      staffPermission: StaffPermissionEnum.manageDrugCatalog,
      title: 'nav_chronic_diseases'.tr(),
      iconPath: AppIcons.chronicDiseases,
      id: 'chronic_diseases',
      selectedIconPath: AppIcons.chronicDiseases,
      routePath: AppRouter.chronicDiseases,
      header: 'nav_chronic_diseases_header'.tr(),
      subtitle: 'nav_chronic_diseases_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.chronicDiseases);
      },
    ),
    SideBarItemModel(
      groupTitle: 'nav_group_medical'.tr(),
      staffPermission: StaffPermissionEnum.manageDrugCatalog,
      title: 'nav_allergies'.tr(),
      iconPath: AppIcons.allergies,
      id: 'allergies',
      selectedIconPath: AppIcons.allergies,
      routePath: AppRouter.allergies,
      header: 'nav_allergies_header'.tr(),
      subtitle: 'nav_allergies_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.allergies);
      },
    ),
    SideBarItemModel(
      groupTitle: 'nav_group_medical'.tr(),
      staffPermission: StaffPermissionEnum.manageDrugCatalog,
      title: 'nav_surgeries'.tr(),
      iconPath: AppIcons.surgeries,
      id: 'surgeries',
      selectedIconPath: AppIcons.surgeries,
      routePath: AppRouter.surgeries,
      header: 'nav_surgeries_header'.tr(),
      subtitle: 'nav_surgeries_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.surgeries);
      },
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // 3. المال (Finance)
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
      staffPermission: null,
      title: 'profile'.tr(),
      iconPath: AppIcons.user,
      id: 'profile',
      selectedIconPath: AppIcons.user,
      routePath: AppRouter.profile,
      header: 'profile'.tr(),
      subtitle: 'بيانات الحساب الشخصي والأمان',
      onTap: () {
        context.go(AppRouter.profile);
      },
    ),
    SideBarItemModel(
      groupTitle: 'nav_group_settings'.tr(),
      staffPermission: null,
      title: 'notifications'.tr(),
      iconPath: AppIcons.notification,
      id: 'notifications',
      selectedIconPath: AppIcons.notification,
      routePath: AppRouter.notifications,
      header: 'notifications'.tr(),
      subtitle: 'تنبيهات النظام وإشارات الاستقبال',
      onTap: () {
        context.go(AppRouter.notifications);
      },
    ),
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
