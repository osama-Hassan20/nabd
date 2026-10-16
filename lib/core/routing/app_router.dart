import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/core/utils/constants/app_constants.dart';
import 'package:eyadty/core/utils/constants/app_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadty/features/bookings/presentation/pages/booking_details_page.dart';
import 'package:eyadty/features/bookings/presentation/pages/bookings_page.dart';
import 'package:eyadty/features/customers/presentation/pages/customer_details_page.dart';
import 'package:eyadty/features/customers/presentation/pages/customers_page.dart';
import 'package:eyadty/features/settings/presentation/pages/settings_page.dart';
import 'package:eyadty/features/technicians/presentation/pages/technician_details_page.dart';
import 'package:eyadty/features/technicians/presentation/pages/technicians_page.dart';
import 'package:eyadty/shared/app_layout/presentation/pages/app_layout.dart';
import 'package:eyadty/shared/auth/presentation/pages/login_page.dart';

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

bool checkIsIOS() {
  if (kIsWeb) return false;
  return Platform.isIOS;
}

// Custom Page Builder with Animation Support
Page<T> buildAnimatedPage<T extends Object?>({
  required Widget child,
  required LocalKey key,
  AnimationType animationType = AnimationType.fade,
  Duration duration = const Duration(milliseconds: 300),
  Curve curve = Curves.easeInOut,
}) {
  if (checkIsIOS() && animationType == AnimationType.cupertino) {
    return CupertinoPage<T>(key: key, child: child);
  }

  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return _getAnimationTransition(
        animationType,
        animation,
        secondaryAnimation,
        child,
        curve,
      );
    },
  );
}

// Animation Builder Function
Widget _getAnimationTransition(
  AnimationType type,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
  Curve curve,
) {
  final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

  Widget transition;
  switch (type) {
    case AnimationType.fade:
      transition = FadeTransition(opacity: curvedAnimation, child: child);
      break;

    case AnimationType.slide:
    case AnimationType.slideFromRight:
      transition = SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );
      break;

    case AnimationType.slideFromLeft:
      transition = SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );
      break;

    case AnimationType.slideFromBottom:
      transition = SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );
      break;

    case AnimationType.slideFromTop:
      transition = SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, -1.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );
      break;

    case AnimationType.scale:
      transition = ScaleTransition(
        scale: curvedAnimation,
        child: FadeTransition(opacity: curvedAnimation, child: child),
      );
      break;

    case AnimationType.rotation:
      transition = RotationTransition(
        turns: curvedAnimation,
        child: FadeTransition(opacity: curvedAnimation, child: child),
      );
      break;

    case AnimationType.cupertino:
      transition = FadeTransition(opacity: curvedAnimation, child: child);
      break;
  }

  // Make the outgoing page disappear immediately
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

final GoRouter appRouter = GoRouter(
  observers: [routeObserver],
  initialLocation: AppRouter.bookings,
  redirect: (context, state) {
    // Bypassed for now: No backend connection yet
    return null;
  },
  routes: [
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
    ShellRoute(
      builder: (context, state, child) {
        final items = layoutItems(context);

        final Map<String, (String title, String subtitle)> subRouteHeaders = {
          '${AppRouter.bookings}/:id': (
            'booking_details'.tr(),
            'bookings_subtitle'.tr(),
          ),
          '${AppRouter.customers}/:id': (
            'customer_details'.tr(),
            'customers_subtitle'.tr(),
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

        GoRoute(
          path: AppRouter.technicians,
          name: AppRouter.technicians,
          pageBuilder: (context, state) => buildAnimatedPage(
            key: state.pageKey,
            child: const TechniciansPage(),
            animationType: checkIsIOS()
                ? AnimationType.cupertino
                : AnimationType.slideFromLeft,
            duration: const Duration(milliseconds: 600),
          ),
          routes: [
            GoRoute(
              path: ':id',
              name: 'technicianDetails',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return buildAnimatedPage(
                  key: state.pageKey,
                  child: TechnicianDetailsPage(technicianId: id),
                  animationType: checkIsIOS()
                      ? AnimationType.cupertino
                      : AnimationType.slideFromRight,
                  duration: const Duration(milliseconds: 350),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRouter.customers,
          name: AppRouter.customers,
          pageBuilder: (context, state) => buildAnimatedPage(
            key: state.pageKey,
            child: const CustomersPage(),
            animationType: checkIsIOS()
                ? AnimationType.cupertino
                : AnimationType.slideFromLeft,
            duration: const Duration(milliseconds: 600),
          ),
          routes: [
            GoRoute(
              path: ':id',
              name: 'customerDetails',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return buildAnimatedPage(
                  key: state.pageKey,
                  child: CustomerDetailsPage(customerId: id),
                  animationType: checkIsIOS()
                      ? AnimationType.cupertino
                      : AnimationType.slideFromRight,
                  duration: const Duration(milliseconds: 350),
                );
              },
            ),
          ],
        ),
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
        ),
      ],
    ),
  ],
);

String getInitialRoute() {
  final bool hasToken =
      AppSharedPreferences.getString(key: AppConstants.accessToken) != null;
  return hasToken ? AppRouter.appLayout : AppRouter.login;
}
