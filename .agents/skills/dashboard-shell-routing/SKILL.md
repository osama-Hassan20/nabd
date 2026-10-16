---
name: dashboard-shell-routing
description: >-
  Use this skill when configuring, adding, or modifying routes in Flutter dashboard projects using GoRouter and ShellRoute.
  Covers layout shells, sidebar-to-route synchronization, dynamic header title/subtitle mapping, nested sub-routes,
  route-level permissions guard, authentication guard, and custom page transition animations.
---

# Dashboard ShellRoute & GoRouter Navigation Skill

This skill explains how the navigation and routing system is built in this dashboard project, and provides exact templates to add new routes, sub-routes, permissions, and animated page transitions.

---

## 1. Core Architecture Overview

The routing architecture consists of 4 tightly coupled elements:
1. **`AppRouter` constants (`lib/core/routing/routes.dart`)**: Route path strings (e.g. `/`, `/login`, `/teachers`, `/orders`).
2. **`GoRouter` instance (`lib/core/routing/app_router.dart`)**:
   - `initialLocation`: Dynamic check (`getInitialRoute()`) verifying access tokens.
   - `redirect`: Centralized guard checking (a) user token, (b) RBAC permissions via `BasicCubit.hasPermission(...)`.
   - `observers`: `[routeObserver]` for tracking popups and modal dialogues.
3. **`ShellRoute` wrapper**: Wraps all authenticated pages inside `AppLayout`, injecting dynamic title/subtitle into the top header based on the current active URL.
4. **Animated Page Transitions (`buildAnimatedPage`)**: Platform-aware transitions (Cupertino for iOS/macOS, slide/fade for Web/Desktop).

---

## 2. Route Constants (`routes.dart`)

Always declare route strings in `lib/core/routing/routes.dart`:

```dart
class AppRouter {
  static const String appLayout = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String students = '/students';
  static const String teachers = '/teachers';
  static const String orders = '/orders';
  static const String transactions = '/transactions';
  static const String employees = '/employees';
  static const String categories = '/categories';
  static const String support = '/support';
  static const String settings = '/settings';
  static const String sliders = '/sliders';
  static const String accessDenied = '/accessDenied';
  
  // New feature route:
  static const String newFeature = '/newFeature';
}
```

---

## 3. Route Permissions Guard Mapping

In `lib/core/routing/app_router.dart`, map each protected route to its required permissions:

```dart
final Map<String, List<Enum>> _routePermissions = {
  AppRouter.students: [StudentPermission.view],
  AppRouter.teachers: [TeacherPermission.view],
  AppRouter.employees: [EmployeesPermission.view],
  AppRouter.orders: [OrderPermission.view],
  AppRouter.sliders: [SliderPermissions.view],
  AppRouter.transactions: [FinancialPermission.view],
  AppRouter.categories: [CategoriesPermission.view],
  AppRouter.support: [SupportPermission.view],
  AppRouter.settings: [
    NotificationsPermission.view,
    StudyStagePermission.view,
    LectureTypePermission.view,
    ProvincesPermission.view,
  ],
  // Add your new feature permissions here:
  AppRouter.newFeature: [NewFeaturePermission.view],
};
```

### The Central Redirect Guard:
```dart
redirect: (context, state) {
  final bool hasToken =
      AppSharedPreferences.getString(key: AppConstants.accessToken) != null;
  if (!hasToken) return AppRouter.login;

  // Permission Guard
  final basicCubit = getIt<BasicCubit>();

  for (var entry in _routePermissions.entries) {
    if (state.fullPath != null && state.fullPath!.startsWith(entry.key)) {
      final hasAny = entry.value.any((p) => basicCubit.hasPermission(p));
      if (!hasAny) {
        debugPrint('Access denied to ${state.fullPath}');
        return AppRouter.accessDenied;
      }
    }
  }

  return null;
},
```

---

## 4. ShellRoute Builder & Dynamic Header Injection

The `ShellRoute` wraps all authenticated routes and dynamically calculates the top header's title and subtitle from:
1. `subRouteHeaders` (for detail routes like `/:id` or nested sub-pages).
2. `layoutItems(context)` (for top-level sidebar items).

```dart
ShellRoute(
  builder: (context, state, child) {
    final items = layoutItems(context);

    // 1. Explicit headers for sub-routes (Localized via easy_localization)
    final Map<String, (String title, String subtitle)> subRouteHeaders = {
      '${AppRouter.bookings}/:id': (
        'booking_details'.tr(),
        'bookings_subtitle'.tr(),
      ),
      '${AppRouter.technicians}/:id': (
        'technician_details'.tr(),
        'technicians_subtitle'.tr(),
      ),
      '${AppRouter.customers}/:id': (
        'customer_details'.tr(),
        'customers_subtitle'.tr(),
      ),
      '${AppRouter.newFeature}/:id': (
        'item_details'.tr(),
        'item_details_subtitle'.tr(),
      ),
    };

    String? title;
    String? subtitle;

    if (subRouteHeaders.containsKey(state.fullPath)) {
      final headerInfo = subRouteHeaders[state.fullPath]!;
      title = headerInfo.$1;
      subtitle = headerInfo.$2;
    } else {
      // Find matching item from sidebar definitions
      final currentItem = items.firstWhere(
        (item) =>
            state.uri.path.startsWith(item.routePath ?? '') &&
            item.routePath != AppRouter.appLayout,
        orElse: () => items.first,
      );
      title = currentItem.header;
      subtitle = currentItem.subtitle;
    }

    return AppLayout(title: title, subtitle: subtitle, child: child);
  },
  routes: [
    // Registered shell children...
  ],
)
```

---

## 5. Adding New Routes & Nested Sub-Routes

Inside `ShellRoute.routes`:

### A. Simple Top-Level Route
```dart
GoRoute(
  path: AppRouter.newFeature,
  name: AppRouter.newFeature,
  pageBuilder: (context, state) => buildAnimatedPage(
    key: state.pageKey,
    child: const AdminNewFeaturePage(),
    animationType: checkIsIOS()
        ? AnimationType.cupertino
        : AnimationType.slideFromLeft,
    duration: const Duration(milliseconds: 800),
  ),
),
```

### B. Nested Route with ID and Extra Cubit
```dart
GoRoute(
  path: AppRouter.newFeature,
  name: AppRouter.newFeature,
  pageBuilder: (context, state) => buildAnimatedPage(
    key: state.pageKey,
    child: const AdminNewFeaturePage(),
  ),
  routes: [
    // Sub-route: /newFeature/:id
    GoRoute(
      path: '/:id',
      pageBuilder: (context, state) => buildAnimatedPage(
        key: state.pageKey,
        child: NewFeatureDetailsPage(
          itemId: state.pathParameters['id']!,
          cubit: state.extra as AdminNewFeatureCubit?,
        ),
        animationType: checkIsIOS()
            ? AnimationType.cupertino
            : AnimationType.slideFromLeft,
        duration: const Duration(milliseconds: 400),
      ),
      routes: [
        // Nested sub-route: /newFeature/:id/logs/:logId
        GoRoute(
          path: 'logs/:logId',
          pageBuilder: (context, state) => buildAnimatedPage(
            key: state.pageKey,
            child: NewFeatureLogsPage(
              logId: state.pathParameters['logId']!,
            ),
          ),
        ),
      ],
    ),
  ],
),
```

---

## 6. Page Navigation & Extra Passing Patterns

When navigating in code:
```dart
// 1. Simple push or replace
context.go(AppRouter.newFeature);

// 2. Go to details with parameter and cubit pass
context.go(
  '${AppRouter.newFeature}/${item.id}',
  extra: cubit, // Optional: pass cubit to avoid re-fetching parent state
);

// 3. Popping back
if (context.canPop()) {
  context.pop();
} else {
  context.go(AppRouter.newFeature);
}
```

---

## 7. Connecting Route to Sidebar (`lib/core/utils/constants/app_list.dart`)

To display the route in the dashboard sidebar, append a `SideBarItemModel` to `layoutItems(BuildContext context)`:

```dart
SideBarItemModel(
  title: 'الميزة الجديدة',
  iconPath: AppIcons.newFeatureIcon,
  id: 'new_feature',
  selectedIconPath: AppIcons.newFeatureIcon,
  routePath: AppRouter.newFeature,
  header: 'إدارة الميزة الجديدة',
  subtitle: 'وصف تفصيلي لما يمكن للمشرف القيام به في هذا القسم.',
  onTap: () {
    context.go(AppRouter.newFeature);
  },
  requiredPermissions: [NewFeaturePermission.view],
),
```
