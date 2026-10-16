import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/layout_adaptive/widgets/custom_side_bar.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';

List<SideBarItemModel> layoutItems(BuildContext context) {
  return [
    SideBarItemModel(
      title: 'bookings'.tr(),
      iconPath: AppIcons.totalBooking,
      id: 'bookings',
      selectedIconPath: AppIcons.totalBooking,
      routePath: AppRouter.bookings,
      header: 'bookings_header'.tr(),
      subtitle: 'bookings_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.bookings);
      },
    ),
    SideBarItemModel(
      title: 'technicians'.tr(),
      iconPath: AppIcons.team,
      id: 'technicians',
      selectedIconPath: AppIcons.team,
      routePath: AppRouter.technicians,
      header: 'technicians_header'.tr(),
      subtitle: 'technicians_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.technicians);
      },
    ),
    SideBarItemModel(
      title: 'customers'.tr(),
      iconPath: AppIcons.users,
      id: 'customers',
      selectedIconPath: AppIcons.users,
      routePath: AppRouter.customers,
      header: 'customers_header'.tr(),
      subtitle: 'customers_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.customers);
      },
    ),
    SideBarItemModel(
      title: 'settings'.tr(),
      iconPath: AppIcons.settings,
      id: 'settings',
      selectedIconPath: AppIcons.settings,
      routePath: AppRouter.settings,
      header: 'settings_header'.tr(),
      subtitle: 'settings_subtitle'.tr(),
      onTap: () {
        context.go(AppRouter.settings);
      },
    ),
  ];
}
