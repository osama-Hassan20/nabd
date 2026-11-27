import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/enums/print_format_enum.dart';
import 'package:eyadty/features/settings/data/repo/settings_repo_impl.dart';
import 'package:eyadty/features/settings/domain/repo/settings_repo.dart';
import 'package:eyadty/features/settings/domain/use_cases/add_special_holiday_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/change_password_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/delete_special_holiday_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_company_settings_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/update_company_settings_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/update_print_settings_use_case.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:eyadty/features/settings/presentation/widgets/tabs/print_settings_tab.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class FakeUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  FakeUserSessionProvider({this.user, this.branch = 'branch_1'});

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch;
}

class FakeRolesSessionProvider implements RolesProvider {
  List<RoleDefinitionModel> roles;
  FakeRolesSessionProvider({required this.roles});

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

class FailingSettingsRepo implements SettingsRepo {
  @override
  Future<Either<Failures, CompanySettingsModel>> getCompanySettings() async {
    return const Left(ServerFailure(errMessage: 'db_connection_error'));
  }

  @override
  Future<Either<Failures, CompanySettingsModel>> updateCompanySettings(
    CompanySettingsModel settings,
  ) async {
    return const Left(ServerFailure(errMessage: 'db_write_error'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class UpdateFailingSettingsRepo implements SettingsRepo {
  @override
  Future<Either<Failures, CompanySettingsModel>> getCompanySettings() async {
    return const Right(CompanySettingsModel());
  }

  @override
  Future<Either<Failures, CompanySettingsModel>> updateCompanySettings(
    CompanySettingsModel settings,
  ) async {
    return const Left(ServerFailure(errMessage: 'db_write_error'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildLocalizedTab({
  required Widget child,
  required SettingsCubit settingsCubit,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: false,
    child: BlocProvider<SettingsCubit>.value(
      value: settingsCubit,
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  late SettingsRepoImpl repo;
  late InMemoryAuditLogger auditLogger;
  late FakeUserSessionProvider userProvider;
  late FakeRolesSessionProvider rolesProvider;
  late PermissionEvaluator permissionEvaluator;
  late UpdatePrintSettingsUseCase updatePrintSettingsUseCase;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    repo = SettingsRepoImpl();
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

    final ownerRole = RoleDefinitionModel(
      id: 'owner_role',
      nameAr: 'مالك النظام',
      nameEn: 'Owner',
      isSystemRole: true,
      permissions: StaffPermissionEnum.values.toList(),
    );

    const receptionistRole = RoleDefinitionModel(
      id: 'reception_role',
      nameAr: 'موظف استقبال',
      nameEn: 'Receptionist',
      isSystemRole: true,
      permissions: [StaffPermissionEnum.accessPatients],
    );

    rolesProvider = FakeRolesSessionProvider(roles: [ownerRole, receptionistRole]);

    userProvider = FakeUserSessionProvider(
      user: const StaffUserModel(
        id: 'user_owner',
        fullName: 'د. مالك',
        isOwner: true,
        isActive: true,
        isDeleted: false,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: ['owner_role'],
            isPrimary: true,
          ),
        ],
      ),
      branch: 'branch_1',
    );

    permissionEvaluator = PermissionEvaluator(
      userProvider: userProvider,
      rolesProvider: rolesProvider,
    );

    updatePrintSettingsUseCase = UpdatePrintSettingsUseCase(
      repo: repo,
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userProvider,
      auditLogger: auditLogger,
    );
  });

  group('UpdatePrintSettingsUseCase', () {
    test('succeeds when user has accessSettings permission and logs audit event', () async {
      final result = await updatePrintSettingsUseCase(
        const UpdatePrintSettingsParams(
          branchId: 'branch_1',
          receiptPrintFormat: 'thermal80',
          shiftReportPrintFormat: 'a4',
          prescriptionPrintFormat: 'thermal80',
        ),
      );

      expect(result.isRight(), isTrue);
      final saved = result.getOrElse(() => const CompanySettingsModel());
      expect(saved.receiptPrintFormat, 'thermal80');
      expect(saved.shiftReportPrintFormat, 'a4');
      expect(saved.prescriptionPrintFormat, 'thermal80');

      // Verify audit log
      final logs = auditLogger.getLogs(eventType: 'print_settings_updated');
      expect(logs.length, 1);
      expect(logs.first.performedByUserId, 'user_owner');
      expect(logs.first.branchId, 'branch_1');
      expect(logs.first.targetUserId, isNull);
      expect(logs.first.details?.contains('receiptFormat=thermal80'), isTrue);
    });

    test('preserves existing formats when only one format is updated', () async {
      await repo.updateCompanySettings(
        const CompanySettingsModel(
          receiptPrintFormat: 'thermal80',
          shiftReportPrintFormat: 'a4',
          prescriptionPrintFormat: 'thermal80',
        ),
      );

      final result = await updatePrintSettingsUseCase(
        const UpdatePrintSettingsParams(
          shiftReportPrintFormat: 'thermal80',
        ),
      );

      expect(result.isRight(), isTrue);
      final saved = result.getOrElse(() => const CompanySettingsModel());
      expect(saved.receiptPrintFormat, 'thermal80'); // preserved
      expect(saved.shiftReportPrintFormat, 'thermal80'); // updated
      expect(saved.prescriptionPrintFormat, 'thermal80'); // preserved
    });

    test('fails closed and records zero audit when permission is denied', () async {
      userProvider.user = const StaffUserModel(
        id: 'user_reception',
        fullName: 'استقبال',
        isOwner: false,
        isActive: true,
        isDeleted: false,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: ['reception_role'],
            isPrimary: true,
          ),
        ],
      );

      final result = await updatePrintSettingsUseCase(
        const UpdatePrintSettingsParams(
          branchId: 'branch_1',
          receiptPrintFormat: 'thermal80',
        ),
      );

      expect(result.isLeft(), isTrue);
      final logs = auditLogger.getLogs(eventType: 'print_settings_updated');
      expect(logs, isEmpty);
    });

    test('rejects invalid receipt print format with invalid_print_format', () async {
      final result = await updatePrintSettingsUseCase(
        const UpdatePrintSettingsParams(
          receiptPrintFormat: 'invalid_format_xyz',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'invalid_print_format'),
        (_) => fail('Should have failed validation'),
      );
      expect(auditLogger.getLogs(eventType: 'print_settings_updated'), isEmpty);
    });

    test('rejects invalid shift report print format with invalid_print_format', () async {
      final result = await updatePrintSettingsUseCase(
        const UpdatePrintSettingsParams(
          shiftReportPrintFormat: 'unsupported_format',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'invalid_print_format'),
        (_) => fail('Should have failed validation'),
      );
    });

    test('rejects invalid prescription print format with invalid_print_format', () async {
      final result = await updatePrintSettingsUseCase(
        const UpdatePrintSettingsParams(
          prescriptionPrintFormat: 'format_123',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'invalid_print_format'),
        (_) => fail('Should have failed validation'),
      );
    });

    test('defaults targetBranchId to userProvider.activeBranchId when branchId is omitted', () async {
      userProvider.branch = 'branch_custom_99';
      final result = await updatePrintSettingsUseCase(
        const UpdatePrintSettingsParams(
          receiptPrintFormat: 'thermal80',
        ),
      );

      expect(result.isRight(), isTrue);
      final logs = auditLogger.getLogs(eventType: 'print_settings_updated');
      expect(logs.length, 1);
      expect(logs.first.branchId, 'branch_custom_99');
    });

    test('propagates failure when repo.getCompanySettings fails', () async {
      final failingUseCase = UpdatePrintSettingsUseCase(
        repo: FailingSettingsRepo(),
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final result = await failingUseCase(
        const UpdatePrintSettingsParams(receiptPrintFormat: 'thermal80'),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'db_connection_error'),
        (_) => fail('Should have returned Left'),
      );
      expect(auditLogger.getLogs(eventType: 'print_settings_updated'), isEmpty);
    });

    test('propagates failure when repo.updateCompanySettings fails and logs zero audit', () async {
      final failingUseCase = UpdatePrintSettingsUseCase(
        repo: UpdateFailingSettingsRepo(),
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      final result = await failingUseCase(
        const UpdatePrintSettingsParams(receiptPrintFormat: 'thermal80'),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'db_write_error'),
        (_) => fail('Should have returned Left'),
      );
      expect(auditLogger.getLogs(eventType: 'print_settings_updated'), isEmpty);
    });

    test('owner user without explicit accessSettings role can update print settings successfully', () async {
      userProvider.user = const StaffUserModel(
        id: 'owner_user_99',
        fullName: 'المالك المؤسس',
        isOwner: true,
        isActive: true,
        isDeleted: false,
        branchAssignments: [],
      );

      final result = await updatePrintSettingsUseCase(
        const UpdatePrintSettingsParams(
          receiptPrintFormat: 'thermal80',
          shiftReportPrintFormat: 'thermal80',
          prescriptionPrintFormat: 'thermal80',
        ),
      );

      expect(result.isRight(), isTrue);
      final logs = auditLogger.getLogs(eventType: 'print_settings_updated');
      expect(logs.length, 1);
      expect(logs.first.performedByUserId, 'owner_user_99');
    });
  });

  group('SettingsRepoImpl Print Settings Persistence', () {
    test('preserves print formats when general settings are updated without overriding print formats', () async {
      await repo.updateCompanySettings(
        const CompanySettingsModel(
          companyName: 'عيادة النور',
          receiptPrintFormat: 'thermal80',
          shiftReportPrintFormat: 'thermal80',
          prescriptionPrintFormat: 'a4',
        ),
      );

      await repo.updateCompanySettings(
        const CompanySettingsModel(
          companyName: 'عيادة النور التخصصية المحدثة',
          phone: '01011112222',
        ),
      );

      final fetched = await repo.getCompanySettings();
      expect(fetched.isRight(), isTrue);
      final current = fetched.getOrElse(() => const CompanySettingsModel());
      expect(current.companyName, 'عيادة النور التخصصية المحدثة');
      expect(current.receiptPrintFormat, 'thermal80');
      expect(current.shiftReportPrintFormat, 'thermal80');
      expect(current.prescriptionPrintFormat, 'a4');
    });
  });

  group('PrintFormat Enum', () {
    test('fromValue parses values accurately and falls back safely', () {
      expect(PrintFormat.fromValue('thermal80'), PrintFormat.thermal80);
      expect(PrintFormat.fromValue('a4'), PrintFormat.a4);
      expect(PrintFormat.fromValue('invalid_value'), PrintFormat.a4);
      expect(PrintFormat.fromValue(null), PrintFormat.a4);

      expect(PrintFormat.thermal80.value, 'thermal80');
      expect(PrintFormat.a4.value, 'a4');
    });

    test('CompanySettingsModel getters return correct effective formats', () {
      const model = CompanySettingsModel(
        receiptPrintFormat: 'thermal80',
        shiftReportPrintFormat: 'a4',
        prescriptionPrintFormat: null,
      );

      expect(model.effectiveReceiptPrintFormat, PrintFormat.thermal80);
      expect(model.effectiveShiftReportPrintFormat, PrintFormat.a4);
      expect(model.effectivePrescriptionPrintFormat, PrintFormat.a4);
    });
  });

  group('SettingsCubit with Print Settings', () {
    test('updatePrintSettings updates settings and reloads', () async {
      final getSettingsUseCase = GetCompanySettingsUseCase(repo: repo);
      final updateCompanySettingsUseCase = UpdateCompanySettingsUseCase(repo: repo);

      final cubit = SettingsCubit(
        getCompanySettingsUseCase: getSettingsUseCase,
        updateCompanySettingsUseCase: updateCompanySettingsUseCase,
        addSpecialHolidayUseCase: AddSpecialHolidayUseCase(repo: repo),
        deleteSpecialHolidayUseCase: DeleteSpecialHolidayUseCase(repo: repo),
        changePasswordUseCase: ChangePasswordUseCase(repo: repo),
        updatePrintSettingsUseCase: updatePrintSettingsUseCase,
      );

      await cubit.fetchSettings();
      expect(cubit.state.settings, isNotNull);

      await cubit.updatePrintSettings(
        receiptPrintFormat: 'thermal80',
        shiftReportPrintFormat: 'thermal80',
        prescriptionPrintFormat: 'a4',
      );

      expect(cubit.state.settings?.receiptPrintFormat, 'thermal80');
      expect(cubit.state.settings?.shiftReportPrintFormat, 'thermal80');
      expect(cubit.state.settings?.prescriptionPrintFormat, 'a4');

      await cubit.close();
    });

    test('updatePrintSettings fails cleanly when permission is denied', () async {
      userProvider.user = const StaffUserModel(
        id: 'user_reception',
        fullName: 'استقبال',
        isOwner: false,
        isActive: true,
        isDeleted: false,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: ['reception_role'],
            isPrimary: true,
          ),
        ],
      );

      final getSettingsUseCase = GetCompanySettingsUseCase(repo: repo);
      final updateCompanySettingsUseCase = UpdateCompanySettingsUseCase(repo: repo);

      final cubit = SettingsCubit(
        getCompanySettingsUseCase: getSettingsUseCase,
        updateCompanySettingsUseCase: updateCompanySettingsUseCase,
        addSpecialHolidayUseCase: AddSpecialHolidayUseCase(repo: repo),
        deleteSpecialHolidayUseCase: DeleteSpecialHolidayUseCase(repo: repo),
        changePasswordUseCase: ChangePasswordUseCase(repo: repo),
        updatePrintSettingsUseCase: updatePrintSettingsUseCase,
      );

      final success = await cubit.updatePrintSettings(
        receiptPrintFormat: 'thermal80',
      );

      expect(success, isFalse);
      expect(cubit.state.errMessage, 'settings_permission_denied');
      await cubit.close();
    });

    test('returns false and emits failure with use_case_not_available when updatePrintSettingsUseCase is null', () async {
      final getSettingsUseCase = GetCompanySettingsUseCase(repo: repo);
      final updateCompanySettingsUseCase = UpdateCompanySettingsUseCase(repo: repo);

      final cubit = SettingsCubit(
        getCompanySettingsUseCase: getSettingsUseCase,
        updateCompanySettingsUseCase: updateCompanySettingsUseCase,
        addSpecialHolidayUseCase: AddSpecialHolidayUseCase(repo: repo),
        deleteSpecialHolidayUseCase: DeleteSpecialHolidayUseCase(repo: repo),
        changePasswordUseCase: ChangePasswordUseCase(repo: repo),
        updatePrintSettingsUseCase: null,
      );

      final success = await cubit.updatePrintSettings(
        receiptPrintFormat: 'thermal80',
      );

      expect(success, isFalse);
      expect(cubit.state.errMessage, 'use_case_not_available');
      await cubit.close();
    });
  });

  group('PrintSettingsTab Widget Tests', () {
    testWidgets('renders tab header, description, and all 3 document format cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final getSettingsUseCase = GetCompanySettingsUseCase(repo: repo);
      final updateCompanySettingsUseCase = UpdateCompanySettingsUseCase(repo: repo);

      final cubit = SettingsCubit(
        getCompanySettingsUseCase: getSettingsUseCase,
        updateCompanySettingsUseCase: updateCompanySettingsUseCase,
        addSpecialHolidayUseCase: AddSpecialHolidayUseCase(repo: repo),
        deleteSpecialHolidayUseCase: DeleteSpecialHolidayUseCase(repo: repo),
        changePasswordUseCase: ChangePasswordUseCase(repo: repo),
        updatePrintSettingsUseCase: updatePrintSettingsUseCase,
      );

      cubit.emit(
        cubit.state.copyWith(
          status: RequestStatusEnum.success,
          settings: const CompanySettingsModel(
            companyName: 'عيادة الأمل',
            receiptPrintFormat: 'a4',
            shiftReportPrintFormat: 'a4',
            prescriptionPrintFormat: 'a4',
          ),
        ),
      );

      await tester.pumpWidget(
        _buildLocalizedTab(
          settingsCubit: cubit,
          child: PrintSettingsTab(settingsCubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PrintSettingsTab), findsOneWidget);
      expect(find.byKey(const Key('print_settings_save_btn')), findsOneWidget);
      expect(find.byKey(const Key('format_receipt_a4')), findsOneWidget);
      expect(find.byKey(const Key('format_receipt_thermal80')), findsOneWidget);
      expect(find.byKey(const Key('format_shift_a4')), findsOneWidget);
      expect(find.byKey(const Key('format_shift_thermal80')), findsOneWidget);
      expect(find.byKey(const Key('format_prescription_a4')), findsOneWidget);
      expect(find.byKey(const Key('format_prescription_thermal80')), findsOneWidget);

      await cubit.close();
    });

    testWidgets('allows changing format by tapping thermal80 option and saves', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final getSettingsUseCase = GetCompanySettingsUseCase(repo: repo);
      final updateCompanySettingsUseCase = UpdateCompanySettingsUseCase(repo: repo);

      final cubit = SettingsCubit(
        getCompanySettingsUseCase: getSettingsUseCase,
        updateCompanySettingsUseCase: updateCompanySettingsUseCase,
        addSpecialHolidayUseCase: AddSpecialHolidayUseCase(repo: repo),
        deleteSpecialHolidayUseCase: DeleteSpecialHolidayUseCase(repo: repo),
        changePasswordUseCase: ChangePasswordUseCase(repo: repo),
        updatePrintSettingsUseCase: updatePrintSettingsUseCase,
      );

      cubit.emit(
        cubit.state.copyWith(
          status: RequestStatusEnum.success,
          settings: const CompanySettingsModel(
            companyName: 'عيادة الأمل',
            receiptPrintFormat: 'a4',
            shiftReportPrintFormat: 'a4',
            prescriptionPrintFormat: 'a4',
          ),
        ),
      );

      await tester.pumpWidget(
        _buildLocalizedTab(
          settingsCubit: cubit,
          child: PrintSettingsTab(settingsCubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on receipt thermal80 format option
      await tester.tap(find.byKey(const Key('format_receipt_thermal80')));
      await tester.pump();

      // Tap on save button
      await tester.tap(find.byKey(const Key('print_settings_save_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify that cubit settings were updated to thermal80
      expect(cubit.state.settings?.receiptPrintFormat, 'thermal80');

      // Drain toastification timer (3 seconds)
      await tester.pump(const Duration(seconds: 4));

      await cubit.close();
    });

    testWidgets('works seamlessly when settingsCubit parameter is null by using context', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final getSettingsUseCase = GetCompanySettingsUseCase(repo: repo);
      final updateCompanySettingsUseCase = UpdateCompanySettingsUseCase(repo: repo);

      final cubit = SettingsCubit(
        getCompanySettingsUseCase: getSettingsUseCase,
        updateCompanySettingsUseCase: updateCompanySettingsUseCase,
        addSpecialHolidayUseCase: AddSpecialHolidayUseCase(repo: repo),
        deleteSpecialHolidayUseCase: DeleteSpecialHolidayUseCase(repo: repo),
        changePasswordUseCase: ChangePasswordUseCase(repo: repo),
        updatePrintSettingsUseCase: updatePrintSettingsUseCase,
      );

      cubit.emit(
        cubit.state.copyWith(
          status: RequestStatusEnum.success,
          settings: const CompanySettingsModel(
            companyName: 'عيادة الأمل',
            receiptPrintFormat: 'a4',
            shiftReportPrintFormat: 'a4',
            prescriptionPrintFormat: 'a4',
          ),
        ),
      );

      await tester.pumpWidget(
        _buildLocalizedTab(
          settingsCubit: cubit,
          child: const PrintSettingsTab(), // null settingsCubit parameter
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PrintSettingsTab), findsOneWidget);

      // Select shift report thermal80 and prescription thermal80
      await tester.tap(find.byKey(const Key('format_shift_thermal80')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('format_prescription_thermal80')));
      await tester.pump();

      // Tap save
      await tester.tap(find.byKey(const Key('print_settings_save_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(cubit.state.settings?.shiftReportPrintFormat, 'thermal80');
      expect(cubit.state.settings?.prescriptionPrintFormat, 'thermal80');

      await tester.pump(const Duration(seconds: 4));
      await cubit.close();
    });

    testWidgets('shows loading state on save button while update is in progress', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final getSettingsUseCase = GetCompanySettingsUseCase(repo: repo);
      final updateCompanySettingsUseCase = UpdateCompanySettingsUseCase(repo: repo);

      final cubit = SettingsCubit(
        getCompanySettingsUseCase: getSettingsUseCase,
        updateCompanySettingsUseCase: updateCompanySettingsUseCase,
        addSpecialHolidayUseCase: AddSpecialHolidayUseCase(repo: repo),
        deleteSpecialHolidayUseCase: DeleteSpecialHolidayUseCase(repo: repo),
        changePasswordUseCase: ChangePasswordUseCase(repo: repo),
        updatePrintSettingsUseCase: updatePrintSettingsUseCase,
      );

      cubit.emit(
        cubit.state.copyWith(
          status: RequestStatusEnum.success,
          actionStatus: RequestStatusEnum.loading,
          settings: const CompanySettingsModel(
            receiptPrintFormat: 'a4',
            shiftReportPrintFormat: 'a4',
            prescriptionPrintFormat: 'a4',
          ),
        ),
      );

      await tester.pumpWidget(
        _buildLocalizedTab(
          settingsCubit: cubit,
          child: PrintSettingsTab(settingsCubit: cubit),
        ),
      );
      await tester.pump();

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

      await cubit.close();
    });

    testWidgets('handles actionStatus failure cleanly and shows error notification', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final getSettingsUseCase = GetCompanySettingsUseCase(repo: repo);
      final updateCompanySettingsUseCase = UpdateCompanySettingsUseCase(repo: repo);

      final cubit = SettingsCubit(
        getCompanySettingsUseCase: getSettingsUseCase,
        updateCompanySettingsUseCase: updateCompanySettingsUseCase,
        addSpecialHolidayUseCase: AddSpecialHolidayUseCase(repo: repo),
        deleteSpecialHolidayUseCase: DeleteSpecialHolidayUseCase(repo: repo),
        changePasswordUseCase: ChangePasswordUseCase(repo: repo),
        updatePrintSettingsUseCase: updatePrintSettingsUseCase,
      );

      cubit.emit(
        cubit.state.copyWith(
          status: RequestStatusEnum.success,
          actionStatus: RequestStatusEnum.initial,
          settings: const CompanySettingsModel(
            receiptPrintFormat: 'a4',
            shiftReportPrintFormat: 'a4',
            prescriptionPrintFormat: 'a4',
          ),
        ),
      );

      await tester.pumpWidget(
        _buildLocalizedTab(
          settingsCubit: cubit,
          child: PrintSettingsTab(settingsCubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      cubit.emit(
        cubit.state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          errMessage: 'settings_permission_denied',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      // Widget remains stable without crashing
      expect(find.byType(PrintSettingsTab), findsOneWidget);

      await cubit.close();
    });
  });
}
