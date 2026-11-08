import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/core/utils/constants/app_constants.dart';
import 'package:eyadty/core/utils/constants/app_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadty/features/analytics/presentation/pages/analytics_page.dart';
import 'package:eyadty/features/bookings/presentation/pages/booking_details_page.dart';
import 'package:eyadty/features/bookings/presentation/pages/bookings_page.dart';
import 'package:eyadty/features/cashier/presentation/pages/cashier_page.dart';
import 'package:eyadty/features/patients/presentation/pages/patient_details_page.dart';
import 'package:eyadty/features/patients/presentation/pages/patients_page.dart';
import 'package:eyadty/features/hr/presentation/pages/hr_page.dart';
import 'package:eyadty/features/settings/presentation/pages/settings_page.dart';
import 'package:eyadty/features/doctors/presentation/pages/doctor_details_page.dart';
import 'package:eyadty/features/doctors/presentation/pages/doctors_page.dart';
import 'package:eyadty/features/visits/presentation/pages/visits_page.dart';
import 'package:eyadty/shared/app_layout/presentation/pages/app_layout.dart';
import 'package:eyadty/shared/auth/presentation/pages/login_page.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/shared/presentation/pages/forbidden_403_page.dart';

import 'routes.dart';

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

// Animation Types Enum
enum AnimationType {
  fade,
  slide,
  scale,
  rotation,
  slideFromBottom,
  slideFromTop,
  slideFromLeft,
  slideFromRight,
  cupertino,
}

// Function to check if the platform is iOS
bool checkIsIOS() {
  if (kIsWeb) return false;
  return Platform.isIOS;
}

// Helper function to build animated page transitions
Page<dynamic> buildAnimatedPage({
  required LocalKey key,
  required Widget child,
  AnimationType animationType = AnimationType.fade,
  Duration duration = const Duration(milliseconds: 300),
  Duration reverseDuration = const Duration(milliseconds: 5),
  RouteTransitionsBuilder? customTransitionsBuilder,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
    transitionsBuilder: customTransitionsBuilder ??
        (context, animation, secondaryAnimation, child) {
          return _buildTransition(
            animationType,
            animation,
            secondaryAnimation,
            child,
          );
        },
  );
}

// Helper function to build different transitions based on AnimationType
Widget _buildTransition(
  AnimationType type,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  Widget transition;

  switch (type) {
    case AnimationType.cupertino:
      return CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: false,
        child: child,
      );

    case AnimationType.fade:
      transition = FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
      break;

    case AnimationType.slide:
    case AnimationType.slideFromRight:
      transition = SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        ),
        child: child,
      );
      break;

    case AnimationType.slideFromLeft:
      transition = SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        ),
        child: child,
      );
      break;

    case AnimationType.slideFromBottom:
      transition = SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        ),
        child: child,
      );
      break;

    case AnimationType.slideFromTop:
      transition = SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, -1.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        ),
        child: child,
      );
      break;

    case AnimationType.scale:
      transition = ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        ),
        child: child,
      );
      break;

    case AnimationType.rotation:
      transition = RotationTransition(
        turns: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        ),
        child: child,
      );
      break;
  }

  return FadeTransition(
    opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.001),
      ),
    ),
    child: transition,
  );
}

// Enhanced Custom Transition Page
class CustomTransitionPage<T> extends Page<T> {
  const CustomTransitionPage({
    required this.child,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 5),
    this.transitionsBuilder,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final RouteTransitionsBuilder? transitionsBuilder;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedPageRoute<T>(
      page: this,
      transitionsBuilder: transitionsBuilder,
    );
  }
}

class _PageBasedPageRoute<T> extends PageRoute<T> {
  _PageBasedPageRoute({
    required CustomTransitionPage<T> page,
    this.transitionsBuilder,
  }) : super(settings: page);

  CustomTransitionPage<T> get _page => settings as CustomTransitionPage<T>;
  final RouteTransitionsBuilder? transitionsBuilder;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _page.reverseTransitionDuration;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _page.child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return transitionsBuilder?.call(
          context,
          animation,
          secondaryAnimation,
          child,
        ) ??
        FadeTransition(opacity: animation, child: child);
  }
}

StaffPermissionEnum? getRequiredPermissionForRoute(String location) {
  if (location.startsWith(AppRouter.usersManagement)) {
    return StaffPermissionEnum.manageRolesAndPermissions;
  }
  if (location.startsWith('/settings/medical-services')) {
    return StaffPermissionEnum.manageMedicalServices;
  }
  if (location.startsWith(AppRouter.bookings)) {
    return StaffPermissionEnum.accessLiveQueue;
  }
  if (location.startsWith(AppRouter.patients)) {
    return StaffPermissionEnum.accessPatients;
  }
  if (location.startsWith(AppRouter.doctors)) {
    return StaffPermissionEnum.accessDoctors;
  }
  if (location.startsWith(AppRouter.cashier)) {
    return StaffPermissionEnum.accessCashier;
  }
  if (location.startsWith(AppRouter.hr)) {
    return StaffPermissionEnum.accessHr;
  }
  if (location.startsWith(AppRouter.analytics)) {
    return StaffPermissionEnum.accessAnalytics;
  }
  if (location.startsWith(AppRouter.settings)) {
    return StaffPermissionEnum.accessSettings;
  }
  return null;
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

List<RouteBase> getAppRoutes() => [
    GoRoute(
      path: AppRouter.login,
      name: AppRouter.login,
      pageBuilder: (context, state) => buildAnimatedPage(
        key: state.pageKey,
        child: const LoginPage(),
        animationType: checkIsIOS()
            ? AnimationType.cupertino
            : AnimationType.slideFromRight,
        duration: const Duration(milliseconds: 800),
      ),
    ),
    GoRoute(
      path: AppRouter.forbidden,
      name: AppRouter.forbidden,
      pageBuilder: (context, state) => buildAnimatedPage(
        key: state.pageKey,
        child: const Forbidden403Page(),
        animationType: checkIsIOS()
            ? AnimationType.cupertino
            : AnimationType.fade,
        duration: const Duration(milliseconds: 400),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) {
        final items = layoutItems(context);

        final Map<String, (String title, String subtitle)> subRouteHeaders = {
          '${AppRouter.bookings}/:id': (
            'booking_details'.tr(),
            'nav_queue_subtitle'.tr(),
          ),
          '${AppRouter.patients}/:id': (
            'patient_details'.tr(),
            'nav_patients_subtitle'.tr(),
          ),
          '${AppRouter.doctors}/:id': (
            'doctor_details'.tr(),
            'nav_doctors_subtitle'.tr(),
          ),
        };

        String? title;
        String? subtitle;

        if (subRouteHeaders.containsKey(state.fullPath)) {
          final headerInfo = subRouteHeaders[state.fullPath]!;
          title = headerInfo.$1;
          subtitle = headerInfo.$2;
        } else {
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
        GoRoute(
          path: AppRouter.appLayout,
          redirect: (context, state) => AppRouter.bookings,
        ),

        // 1. Live Queue & Appointments
        GoRoute(
          path: AppRouter.bookings,
          name: AppRouter.bookings,
          pageBuilder: (context, state) => buildAnimatedPage(
            key: state.pageKey,
            child: const BookingsPage(),
            animationType: checkIsIOS()
                ? AnimationType.cupertino
                : AnimationType.slideFromLeft,
            duration: const Duration(milliseconds: 600),
          ),
          routes: [
            GoRoute(
              path: ':id',
              name: 'bookingDetails',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return buildAnimatedPage(
                  key: state.pageKey,
                  child: BookingDetailsPage(bookingId: id),
                  animationType: checkIsIOS()
                      ? AnimationType.cupertino
                      : AnimationType.slideFromRight,
                  duration: const Duration(milliseconds: 350),
                );
              },
            ),
          ],
        ),

        // 2. Patients & Medical EMR
        GoRoute(
          path: AppRouter.patients,
          name: AppRouter.patients,
          pageBuilder: (context, state) => buildAnimatedPage(
            key: state.pageKey,
            child: const PatientsPage(),
            animationType: checkIsIOS()
                ? AnimationType.cupertino
                : AnimationType.slideFromLeft,
            duration: const Duration(milliseconds: 600),
          ),
          routes: [
            GoRoute(
              path: ':id',
              name: 'patientDetails',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return buildAnimatedPage(
                  key: state.pageKey,
                  child: PatientDetailsPage(patientId: id),
                  animationType: checkIsIOS()
                      ? AnimationType.cupertino
                      : AnimationType.slideFromRight,
                  duration: const Duration(milliseconds: 350),
                );
              },
            ),
          ],
        ),

        // 3. Clinical Visits & Prescriptions
        GoRoute(
          path: AppRouter.visits,
          name: AppRouter.visits,
          pageBuilder: (context, state) => buildAnimatedPage(
            key: state.pageKey,
            child: const VisitsPage(),
            animationType: checkIsIOS()
                ? AnimationType.cupertino
                : AnimationType.slideFromLeft,
            duration: const Duration(milliseconds: 600),
          ),
        ),

        // 4. Doctors & Staff Schedules
        GoRoute(
          path: AppRouter.doctors,
          name: AppRouter.doctors,
          pageBuilder: (context, state) => buildAnimatedPage(
            key: state.pageKey,
            child: const DoctorsPage(),
            animationType: checkIsIOS()
                ? AnimationType.cupertino
                : AnimationType.slideFromLeft,
            duration: const Duration(milliseconds: 600),
          ),
          routes: [
            GoRoute(
              path: ':id',
              name: 'doctorDetails',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return buildAnimatedPage(
                  key: state.pageKey,
                  child: DoctorDetailsPage(doctorId: id),
                  animationType: checkIsIOS()
                      ? AnimationType.cupertino
                      : AnimationType.slideFromRight,
                  duration: const Duration(milliseconds: 350),
                );
              },
            ),
          ],
        ),

        // 5. Cashier & Shift Drawer
        GoRoute(
          path: AppRouter.cashier,
          name: AppRouter.cashier,
          pageBuilder: (context, state) => buildAnimatedPage(
            key: state.pageKey,
            child: const CashierPage(),
            animationType: checkIsIOS()
                ? AnimationType.cupertino
                : AnimationType.slideFromLeft,
            duration: const Duration(milliseconds: 600),
          ),
        ),

        // 6. HR & Doctor Settlements
        GoRoute(
          path: AppRouter.hr,
          name: AppRouter.hr,
          pageBuilder: (context, state) => buildAnimatedPage(
            key: state.pageKey,
            child: const HrPage(),
            animationType: checkIsIOS()
                ? AnimationType.cupertino
                : AnimationType.slideFromLeft,
            duration: const Duration(milliseconds: 600),
          ),
        ),

        // 7. Executive Analytics & Statistics
        GoRoute(
          path: AppRouter.analytics,
          name: AppRouter.analytics,
          pageBuilder: (context, state) => buildAnimatedPage(
            key: state.pageKey,
            child: const AnalyticsPage(),
            animationType: checkIsIOS()
                ? AnimationType.cupertino
                : AnimationType.slideFromLeft,
            duration: const Duration(milliseconds: 600),
          ),
        ),

        // 8. Facility & Multi-Branch Settings
        GoRoute(
          path: AppRouter.settings,
          name: AppRouter.settings,
          pageBuilder: (context, state) => buildAnimatedPage(
            key: state.pageKey,
            child: const SettingsPage(),
            animationType: checkIsIOS()
                ? AnimationType.cupertino
                : AnimationType.slideFromLeft,
            duration: const Duration(milliseconds: 600),
          ),
          routes: [
            GoRoute(
              path: 'users',
              name: AppRouter.usersManagement,
              pageBuilder: (context, state) => buildAnimatedPage(
                key: state.pageKey,
                child: const SettingsPage(),
                animationType: checkIsIOS()
                    ? AnimationType.cupertino
                    : AnimationType.slideFromLeft,
                duration: const Duration(milliseconds: 600),
              ),
            ),
          ],
        ),
      ],
    ),
  ];

GoRouter createAppRouter({
  SessionCubit? sessionCubit,
  String initialLocation = AppRouter.bookings,
  List<NavigatorObserver>? observers,
  List<RouteBase>? routes,
}) {
  final session = sessionCubit ??
      (getIt.isRegistered<SessionCubit>() ? getIt<SessionCubit>() : null);

  return GoRouter(
    observers: observers ?? [routeObserver],
    initialLocation: initialLocation,
    refreshListenable:
        session != null ? GoRouterRefreshStream(session.stream) : null,
    redirect: (context, state) {
      final location = state.uri.path;
      final isLogin = location == AppRouter.login;
      final isForbidden = location == AppRouter.forbidden;

      final currentSession = session ??
          (getIt.isRegistered<SessionCubit>() ? getIt<SessionCubit>() : null);
      if (currentSession == null) {
        return null;
      }

      final isAuthenticated = currentSession.state.isAuthenticated;

      // 1. Unauthenticated users redirected to /login
      if (!isAuthenticated) {
        if (isLogin) return null;
        return '${AppRouter.login}?from=${Uri.encodeComponent(location)}';
      }

      // 2. Authenticated users on /login redirected to destination or bookings
      if (isLogin) {
        final from = state.uri.queryParameters['from'];
        return (from != null && from.isNotEmpty) ? from : AppRouter.bookings;
      }

      // 3. User on /forbidden: re-evaluate if their permissions changed (e.g. role switch)
      if (isForbidden) {
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) {
          final reqPerm = getRequiredPermissionForRoute(from);
          if (reqPerm == null || currentSession.can(reqPerm)) {
            return from;
          }
        }
        return null;
      }

      // 4. Role/permission enforcement
      final requiredPermission = getRequiredPermissionForRoute(location);
      if (requiredPermission != null) {
        final hasPermission = currentSession.can(requiredPermission);
        if (!hasPermission) {
          return '${AppRouter.forbidden}?from=${Uri.encodeComponent(location)}';
        }
      }

      return null;
    },
    routes: routes ?? getAppRoutes(),
  );
}

GoRouter? _globalRouterInstance;
GoRouter get appRouter => _globalRouterInstance ??= createAppRouter();

void resetAppRouter() {
  _globalRouterInstance?.dispose();
  _globalRouterInstance = null;
}

String getInitialRoute() {
  final bool hasToken =
      AppSharedPreferences.getString(key: AppConstants.accessToken) != null;
  return hasToken ? AppRouter.appLayout : AppRouter.login;
}
