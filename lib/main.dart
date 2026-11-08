import 'package:eyadty/shared/cubit/basic_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:eyadty/firebase_options.dart';
import 'app.dart';
import 'core/bloc_observer.dart';
import 'core/cubits/session_cubit.dart';
import 'core/dependency_injection/dependency_injection.dart';
import 'core/services/navigation_mode_service.dart';
import 'core/storage/cache_helper.dart';
import 'core/utils/constants/app_constants.dart';

import 'package:url_strategy/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //validateConfig();
  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  // } catch (e) {
  //   if (kDebugMode) {
  //     print('Firebase initialization failed: $e');
  //   }
  // }
  // MediaKit.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await AppSharedPreferences.initialSharedPreference();
  setPathUrlStrategy();
  await NavigationModeService.check3ButtonNavigation();

  await setupGetIt();
  //  await AppSharedPreferences.clearAll();
  Bloc.observer = MyBlocObserver();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('ar', 'EG')],
      path: AppConstants.translationPath,
      fallbackLocale: const Locale('ar', 'EG'),
      startLocale: const Locale('ar', 'EG'),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => getIt<BasicCubit>()),
          BlocProvider.value(value: getIt<SessionCubit>()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}
