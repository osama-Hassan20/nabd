import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/analytics/presentation/manager/analytics_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/cashier/domain/repo/cashier_repo.dart';
import 'package:eyadty/features/cashier/domain/use_cases/approve_shortage_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/close_shift_drawer_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/collect_payment_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/force_close_shift_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/get_active_shift_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/open_shift_drawer_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/record_drawer_expense_use_case.dart';
import 'package:eyadty/features/cashier/domain/use_cases/refund_payment_use_case.dart';
import 'package:eyadty/features/cashier/presentation/manager/cashier_cubit.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/drugs/presentation/manager/drugs_cubit.dart';
import 'package:eyadty/features/hr/presentation/manager/hr_cubit.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/settings/domain/use_cases/update_print_settings_use_case.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:eyadty/features/visits/domain/use_cases/print_prescription_use_case.dart';
import 'package:eyadty/features/visits/presentation/manager/visits_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.instance.reset();
    await setupGetIt();
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('Dependency Injection Complete Integrity Tests', () {
    test('1. CurrentUserProvider and RolesProvider are properly registered and resolve to SessionCubit', () {
      expect(GetIt.instance.isRegistered<CurrentUserProvider>(), isTrue);
      expect(GetIt.instance.isRegistered<RolesProvider>(), isTrue);
      expect(GetIt.instance.isRegistered<CurrentRoleProvider>(), isTrue);
      expect(GetIt.instance.isRegistered<SessionCubit>(), isTrue);
      expect(GetIt.instance.isRegistered<PermissionEvaluator>(), isTrue);

      final userProvider = GetIt.instance<CurrentUserProvider>();
      final sessionCubit = GetIt.instance<SessionCubit>();

      expect(identical(userProvider, sessionCubit), isTrue);
      expect(userProvider.currentUser, isNotNull);
    });

    test('2. Cashier use cases can all be resolved without throwing Bad state or missing dependency', () {
      expect(() => GetIt.instance<CashierRepo>(), returnsNormally);
      expect(() => GetIt.instance<GetActiveShiftUseCase>(), returnsNormally);
      expect(() => GetIt.instance<OpenShiftDrawerUseCase>(), returnsNormally);
      expect(() => GetIt.instance<CloseShiftDrawerUseCase>(), returnsNormally);
      expect(() => GetIt.instance<CollectPaymentUseCase>(), returnsNormally);
      expect(() => GetIt.instance<RefundPaymentUseCase>(), returnsNormally);
      expect(() => GetIt.instance<RecordDrawerExpenseUseCase>(), returnsNormally);
      expect(() => GetIt.instance<ApproveShortageUseCase>(), returnsNormally);
      expect(() => GetIt.instance<ForceCloseShiftUseCase>(), returnsNormally);
    });

    test('3. CashierCubit can be instantiated without throwing (resolves all dependencies and use cases)', () {
      expect(() => GetIt.instance<CashierCubit>(), returnsNormally);
      final cashierCubit = GetIt.instance<CashierCubit>();
      expect(cashierCubit, isA<CashierCubit>());
      cashierCubit.close();
    });

    test('4. PrintPrescriptionUseCase resolves userProvider and can be instantiated without throwing', () {
      expect(() => GetIt.instance<PrintPrescriptionUseCase>(), returnsNormally);
      final printUseCase = GetIt.instance<PrintPrescriptionUseCase>();
      expect(printUseCase, isA<PrintPrescriptionUseCase>());
    });

    test('5. VisitsCubit resolves without throwing', () {
      expect(() => GetIt.instance<VisitsCubit>(), returnsNormally);
      final visitsCubit = GetIt.instance<VisitsCubit>();
      expect(visitsCubit, isA<VisitsCubit>());
      visitsCubit.close();
    });

    test('6. All remaining feature cubits resolve without throwing', () {
      expect(() => GetIt.instance<BookingsCubit>(), returnsNormally);
      expect(() => GetIt.instance<PatientsCubit>(), returnsNormally);
      expect(() => GetIt.instance<DoctorsCubit>(), returnsNormally);
      expect(() => GetIt.instance<SettingsCubit>(), returnsNormally);
      expect(() => GetIt.instance<DrugsCubit>(), returnsNormally);
      expect(() => GetIt.instance<HrCubit>(), returnsNormally);
      expect(() => GetIt.instance<AnalyticsCubit>(), returnsNormally);

      final settingsCubit = GetIt.instance<SettingsCubit>();
      final hrCubit = GetIt.instance<HrCubit>();
      final analyticsCubit = GetIt.instance<AnalyticsCubit>();

      expect(settingsCubit, isA<SettingsCubit>());
      expect(hrCubit, isA<HrCubit>());
      expect(analyticsCubit, isA<AnalyticsCubit>());

      settingsCubit.close();
      hrCubit.close();
      analyticsCubit.close();
    });

    test('7. Settings UpdatePrintSettingsUseCase resolves without throwing', () {
      expect(() => GetIt.instance<UpdatePrintSettingsUseCase>(), returnsNormally);
      final uc = GetIt.instance<UpdatePrintSettingsUseCase>();
      expect(uc, isA<UpdatePrintSettingsUseCase>());
    });
  });
}

