import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_tab_enum.dart';
import 'package:eyadty/features/hr/presentation/pages/hr_page.dart';

Widget _buildTestApp({
  required Widget child,
  required SessionCubit sessionCubit,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: false,
    child: BlocProvider<SessionCubit>.value(
      value: sessionCubit,
      child: MaterialApp(
        locale: const Locale('ar', 'EG'),
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionCubit sessionCubit;

  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.instance.reset();
    await setupGetIt();

    sessionCubit = GetIt.instance<SessionCubit>();
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('HrPage Widget & Provider Scoping Tests', () {
    testWidgets('1. HrPage mounts successfully without throwing ProviderNotFoundException', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestApp(
          sessionCubit: sessionCubit,
          child: const HrPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HrPage), findsOneWidget);
      expect(find.text('hr_tab_settlements'.tr()), findsOneWidget);
      expect(find.text('hr_tab_staff_payroll'.tr()), findsOneWidget);
      expect(find.text('hr_tab_employee_ledger'.tr()), findsOneWidget);
    });

    testWidgets('2. HrPage with explicit cubit mounts and switches tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cubit = GetIt.instance<HrCubit>();
      final user = sessionCubit.state.currentUser!;
      await cubit.init(branchId: 'branch_1', user: user);

      await tester.pumpWidget(
        _buildTestApp(
          sessionCubit: sessionCubit,
          child: HrPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(cubit.state.selectedTab, equals(HrTabEnum.settlements));

      // Tap on Staff Payroll tab
      await tester.tap(find.text('hr_tab_staff_payroll'.tr()));
      await tester.pumpAndSettle();

      expect(cubit.state.selectedTab, equals(HrTabEnum.staffPayroll));

      // Tap on Employee Ledger tab
      await tester.tap(find.text('hr_tab_employee_ledger'.tr()));
      await tester.pumpAndSettle();

      expect(cubit.state.selectedTab, equals(HrTabEnum.employeeLedger));

      cubit.close();
    });
  });
}
