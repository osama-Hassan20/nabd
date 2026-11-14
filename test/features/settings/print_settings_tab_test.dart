import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/enums/print_format_enum.dart';
import 'package:eyadty/features/settings/data/repo/settings_mock_repo_impl.dart';
import 'package:eyadty/features/settings/domain/use_cases/add_special_holiday_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/change_password_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/delete_special_holiday_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_company_settings_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/update_company_settings_use_case.dart';
import 'package:eyadty/features/settings/domain/use_cases/update_print_settings_use_case.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class MockUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  MockUserSessionProvider({this.user, this.branch = 'branch_1'});

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch;
}

class MockRolesSessionProvider implements RolesProvider {
  List<RoleDefinitionModel> roles;
  MockRolesSessionProvider({required this.roles});

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

void main() {
  late SettingsMockRepoImpl repo;
  late InMemoryAuditLogger auditLogger;
  late MockUserSessionProvider userProvider;
  late MockRolesSessionProvider rolesProvider;
  late PermissionEvaluator permissionEvaluator;
  late UpdatePrintSettingsUseCase updatePrintSettingsUseCase;

  setUp(() {
    repo = SettingsMockRepoImpl();
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

    rolesProvider = MockRolesSessionProvider(roles: [ownerRole, receptionistRole]);

    userProvider = MockUserSessionProvider(
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
      expect(logs.first.details?.contains('receiptFormat=thermal80'), isTrue);
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
  });

  group('SettingsMockRepoImpl Print Settings Persistence', () {
    test('preserves print formats when general settings are updated without overriding print formats', () async {
      // First update print settings
      await repo.updateCompanySettings(
        const CompanySettingsModel(
          companyName: 'عيادة النور',
          receiptPrintFormat: 'thermal80',
          shiftReportPrintFormat: 'thermal80',
          prescriptionPrintFormat: 'a4',
        ),
      );

      // Now update only general info
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

      await cubit.updatePrintSettings(
        receiptPrintFormat: 'thermal80',
      );

      expect(cubit.state.errMessage, 'settings_permission_denied');
      await cubit.close();
    });
  });
}
