import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/cubits/theme/app_theme_cubit.dart';
import 'core/dependency_injection/dependency_injection.dart';
import 'core/routing/app_router.dart';
import 'core/services/navigation_mode_service.dart';
import 'core/utils/theme/app_theme.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NavigationModeService.check3ButtonNavigation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NavigationModeService.check3ButtonNavigation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(context) {
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      bloc: getIt.isRegistered<AppThemeCubit>() ? getIt<AppThemeCubit>() : null,
      builder: (context, themeState) {
        final currentMode = themeState.themeMode;
        final activeTheme = MyAppTheme.getTheme(currentMode);

        return MaterialApp.router(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          title: "عيادتي - لوحة التحكم",
          routerConfig: appRouter,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return ValueListenableBuilder<bool>(
              valueListenable: NavigationModeService.is3ButtonNavNotifier,
              builder: (context, is3Button, _) {
                final extraBottom = is3Button ? 45.0 : 0.0;
                return Padding(
                  padding: EdgeInsets.only(bottom: extraBottom),
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      boldText: false,
                      textScaler: const TextScaler.linear(1),
                    ),
                    child: child!,
                  ),
                );
              },
            );
          },
          debugShowCheckedModeBanner: false,
          theme: activeTheme,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
            overscroll: true,
            scrollbars: true,
          ),
        );
      },
    );
  }
}
