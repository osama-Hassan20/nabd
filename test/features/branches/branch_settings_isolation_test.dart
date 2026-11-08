import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/features/branches/data/models/branch_model.dart';
import 'package:eyadty/features/branches/data/models/copy_branch_settings_param.dart';
import 'package:eyadty/features/branches/data/repo/branches_mock_repo_impl.dart';
import 'package:eyadty/features/branches/domain/repo/branches_repo.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/special_holiday_model.dart';
import 'package:eyadty/features/settings/data/repo/settings_mock_repo_impl.dart';
import 'package:eyadty/features/settings/domain/repo/settings_repo.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsMockRepoImpl settingsRepo;
  late BranchesMockRepoImpl branchesRepo;
  late SessionCubit sessionCubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
  });

  setUp(() async {
    if (getIt.isRegistered<SessionCubit>()) getIt.unregister<SessionCubit>();
    if (getIt.isRegistered<SettingsRepo>()) getIt.unregister<SettingsRepo>();
    if (getIt.isRegistered<BranchesRepo>()) getIt.unregister<BranchesRepo>();

    sessionCubit = SessionCubit(SessionState.initial());
    settingsRepo = SettingsMockRepoImpl();
    branchesRepo = BranchesMockRepoImpl(
      auditLogger: InMemoryAuditLogger(),
    );

    getIt.registerLazySingleton<SessionCubit>(() => sessionCubit);
    getIt.registerLazySingleton<SettingsRepo>(() => settingsRepo);
    getIt.registerLazySingleton<BranchesRepo>(() => branchesRepo);

    // Seed session as owner
    final ownerUser = const StaffUserModel(
      id: 'owner_1',
      fullName: 'Owner Test',
      isOwner: true,
    );
    sessionCubit.switchMockUser(ownerUser);
    sessionCubit.switchBranch('branch_1');
  });

  tearDown(() {
    if (getIt.isRegistered<SessionCubit>()) getIt.unregister<SessionCubit>();
    if (getIt.isRegistered<SettingsRepo>()) getIt.unregister<SettingsRepo>();
    if (getIt.isRegistered<BranchesRepo>()) getIt.unregister<BranchesRepo>();
  });

  group('Milestone 5: Per-Branch Settings Isolation Tests', () {
    test('Settings are isolated per active branch', () async {
      // 1. Initially on branch_1
      final res1 = await settingsRepo.getCompanySettings();
      expect(res1.isRight(), isTrue);
      final s1 = res1.getOrElse(() => const CompanySettingsModel());
      expect(s1.openingTime, '09:00');
      expect(s1.closingTime, '22:00');
      expect(s1.workingDays, contains('thursday'));

      // 2. Switch to branch_2
      sessionCubit.switchBranch('branch_2');
      final res2 = await settingsRepo.getCompanySettings();
      expect(res2.isRight(), isTrue);
      final s2 = res2.getOrElse(() => const CompanySettingsModel());
      expect(s2.openingTime, '10:00');
      expect(s2.closingTime, '20:00');
      expect(s2.workingDays, isNot(contains('thursday')));

      // 3. Switch to branch_3
      sessionCubit.switchBranch('branch_3');
      final res3 = await settingsRepo.getCompanySettings();
      expect(res3.isRight(), isTrue);
      final s3 = res3.getOrElse(() => const CompanySettingsModel());
      expect(s3.openingTime, '12:00');
      expect(s3.closingTime, '21:00');
    });

    test('Updating branch_2 settings does not affect branch_1', () async {
      sessionCubit.switchBranch('branch_2');
      final currentRes = await settingsRepo.getCompanySettings();
      final current = currentRes.getOrElse(() => const CompanySettingsModel());

      final updatedB2 = current.copyWith(
        openingTime: '11:00',
        closingTime: '19:00',
      );
      await settingsRepo.updateCompanySettings(updatedB2);

      // Verify branch_2 is updated
      final checkB2 = await settingsRepo.getCompanySettings();
      expect(checkB2.getOrElse(() => const CompanySettingsModel()).openingTime, '11:00');

      // Switch back to branch_1 and verify untouched
      sessionCubit.switchBranch('branch_1');
      final checkB1 = await settingsRepo.getCompanySettings();
      expect(checkB1.getOrElse(() => const CompanySettingsModel()).openingTime, '09:00');
    });

    test('Holidays can be added and deleted independently per branch', () async {
      // Add custom holiday to branch_2
      sessionCubit.switchBranch('branch_2');
      final newHol = SpecialHolidayModel(
        name: 'Giza Local Holiday',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 1),
      );
      final addRes = await settingsRepo.addSpecialHoliday(newHol);
      expect(addRes.isRight(), isTrue);
      final added = addRes.getOrElse(() => const SpecialHolidayModel());

      final b2Settings = (await settingsRepo.getCompanySettings()).getOrElse(() => const CompanySettingsModel());
      expect(b2Settings.specialHolidays?.any((h) => h.name == 'Giza Local Holiday'), isTrue);

      // Switch to branch_1 and verify it does NOT have this holiday
      sessionCubit.switchBranch('branch_1');
      final b1Settings = (await settingsRepo.getCompanySettings()).getOrElse(() => const CompanySettingsModel());
      expect(b1Settings.specialHolidays?.any((h) => h.name == 'Giza Local Holiday'), isFalse);

      // Delete from branch_2
      sessionCubit.switchBranch('branch_2');
      await settingsRepo.deleteSpecialHoliday(added.id!);
      final b2AfterDelete = (await settingsRepo.getCompanySettings()).getOrElse(() => const CompanySettingsModel());
      expect(b2AfterDelete.specialHolidays?.any((h) => h.id == added.id), isFalse);
    });

    test('BranchesRepo.copySettingsFromBranch syncs working hours and holidays to SettingsRepo', () async {
      // Branch 1 has 09:00 - 22:00
      // Branch 3 has 12:00 - 21:00
      // Copy working hours from branch_1 to branch_3
      final copyParam = const CopyBranchSettingsParam(
        sourceBranchId: 'branch_1',
        targetBranchId: 'branch_3',
        copyWorkingHours: true,
        copySpecialHolidays: true,
      );

      final copyRes = await branchesRepo.copySettingsFromBranch(
        copyParam,
        currentUserId: 'owner_1',
      );
      expect(copyRes.isRight(), isTrue);
      final updatedBranch3 = copyRes.getOrElse(() => const BranchModel());
      expect(updatedBranch3.openingTime, '09:00');
      expect(updatedBranch3.closingTime, '22:00');

      // Verify SettingsRepo for branch_3 was synced
      sessionCubit.switchBranch('branch_3');
      final settRes = await settingsRepo.getCompanySettings();
      final sett = settRes.getOrElse(() => const CompanySettingsModel());
      expect(sett.openingTime, '09:00');
      expect(sett.closingTime, '22:00');
      expect(sett.workingDays, contains('thursday'));
    });

    test('BranchesRepo.updateBranch syncs name and hours to SettingsRepo', () async {
      final b2Res = await branchesRepo.getBranchById('branch_2');
      final b2 = b2Res.getOrElse(() => const BranchModel());

      final updated = b2.copyWith(
        name: 'عيادتي - فرع الجيزة المتطور',
        openingTime: '08:30',
        closingTime: '23:00',
      );

      await branchesRepo.updateBranch(updated, currentUserId: 'owner_1');

      sessionCubit.switchBranch('branch_2');
      final settRes = await settingsRepo.getCompanySettings();
      final sett = settRes.getOrElse(() => const CompanySettingsModel());
      expect(sett.companyName, 'عيادتي - فرع الجيزة المتطور');
      expect(sett.openingTime, '08:30');
      expect(sett.closingTime, '23:00');
    });
  });
}
