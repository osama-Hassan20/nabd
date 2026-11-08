import 'package:dartz/dartz.dart';
import '../../../../core/api/api_consumer.dart';
import '../../../../core/cubits/session_cubit.dart';
import '../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../branches/data/models/branch_model.dart';
import '../../domain/repo/settings_repo.dart';
import '../models/company_settings_model.dart';
import '../models/special_holiday_model.dart';

class SettingsMockRepoImpl implements SettingsRepo {
  final ApiConsumer? apiConsumer;

  SettingsMockRepoImpl({this.apiConsumer}) {
    _initMockData();
  }

  final Map<String, CompanySettingsModel> _branchSettings = {};
  String _adminPassword = 'password123';

  List<SpecialHolidayModel> _defaultHolidays() => [
    SpecialHolidayModel(
      id: 'HOL-01',
      name: 'عيد الشرطة وثورة 25 يناير',
      startDate: DateTime(2026, 1, 25),
      endDate: DateTime(2026, 1, 25),
    ),
    SpecialHolidayModel(
      id: 'HOL-02',
      name: 'عيد الفطر المبارك',
      startDate: DateTime(2026, 3, 20),
      endDate: DateTime(2026, 3, 23),
    ),
    SpecialHolidayModel(
      id: 'HOL-03',
      name: 'عيد تحرير سيناء',
      startDate: DateTime(2026, 4, 25),
      endDate: DateTime(2026, 4, 25),
    ),
    SpecialHolidayModel(
      id: 'HOL-04',
      name: 'عيد العمال',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 1),
    ),
    SpecialHolidayModel(
      id: 'HOL-05',
      name: 'وقفة وعيد الأضحى المبارك',
      startDate: DateTime(2026, 5, 26),
      endDate: DateTime(2026, 5, 29),
    ),
    SpecialHolidayModel(
      id: 'HOL-06',
      name: 'ثورة 30 يونيو',
      startDate: DateTime(2026, 6, 30),
      endDate: DateTime(2026, 6, 30),
    ),
    SpecialHolidayModel(
      id: 'HOL-07',
      name: 'عيد القوات المسلحة (6 أكتوبر)',
      startDate: DateTime(2026, 10, 6),
      endDate: DateTime(2026, 10, 6),
    ),
  ];

  void _initMockData() {
    _branchSettings['branch_1'] = CompanySettingsModel(
      id: 'SETT-001',
      companyName: 'عيادتي - الفرع الرئيسي (المعادي)',
      logo: 'assets/icons/app_logo.png',
      phone: '+20 2 2750 8800',
      address: 'مصر - القاهرة، المعادي، شارع النصر',
      defaultHourlyRate: 250,
      workingDays: const [
        'saturday',
        'sunday',
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
      ],
      openingTime: '09:00',
      closingTime: '22:00',
      specialHolidays: _defaultHolidays(),
      notificationEnabled: true,
      reminderMinutesBefore: 60,
    );

    _branchSettings['branch_2'] = CompanySettingsModel(
      id: 'SETT-002',
      companyName: 'عيادتي - فرع الجيزة (المهندسين)',
      logo: 'assets/icons/app_logo.png',
      phone: '+20 2 3749 1100',
      address: 'مصر - الجيزة، المهندسين، شارع سوريا',
      defaultHourlyRate: 250,
      workingDays: const [
        'saturday',
        'monday',
        'wednesday',
      ],
      openingTime: '10:00',
      closingTime: '20:00',
      specialHolidays: _defaultHolidays(),
      notificationEnabled: true,
      reminderMinutesBefore: 60,
    );

    _branchSettings['branch_3'] = CompanySettingsModel(
      id: 'SETT-003',
      companyName: 'عيادتي - فرع الإسكندرية (سموحة)',
      logo: 'assets/icons/app_logo.png',
      phone: '+20 3 4200 550',
      address: 'مصر - الإسكندرية، سموحة، ميدان فيكتور عمانويل',
      defaultHourlyRate: 250,
      workingDays: const [
        'sunday',
        'tuesday',
        'thursday',
      ],
      openingTime: '12:00',
      closingTime: '21:00',
      specialHolidays: _defaultHolidays(),
      notificationEnabled: true,
      reminderMinutesBefore: 60,
    );
  }

  String _getActiveBranchId() {
    if (getIt.isRegistered<SessionCubit>()) {
      final active = getIt<SessionCubit>().state.activeBranchId;
      if (active != null && active.isNotEmpty) {
        return active;
      }
    }
    return 'branch_1';
  }

  CompanySettingsModel _getOrInitSettings(String branchId) {
    if (!_branchSettings.containsKey(branchId)) {
      _branchSettings[branchId] = CompanySettingsModel(
        id: 'SETT-$branchId',
        companyName: 'عيادتي',
        logo: 'assets/icons/app_logo.png',
        phone: '+20 2 2750 8800',
        address: 'مصر',
        defaultHourlyRate: 250,
        workingDays: const [
          'saturday',
          'sunday',
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
        ],
        openingTime: '09:00',
        closingTime: '22:00',
        specialHolidays: _defaultHolidays(),
        notificationEnabled: true,
        reminderMinutesBefore: 60,
      );
    }
    return _branchSettings[branchId]!;
  }

  @override
  Future<Either<Failures, CompanySettingsModel>> getCompanySettings() async {
    try {
      await Future.delayed(const Duration(milliseconds: 150));
      final branchId = _getActiveBranchId();
      return Right(_getOrInitSettings(branchId));
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, CompanySettingsModel>> updateCompanySettings(
    CompanySettingsModel settings,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final branchId = _getActiveBranchId();
      final current = _getOrInitSettings(branchId);
      final updated = settings.copyWith(
        id: current.id,
        specialHolidays: settings.specialHolidays ?? current.specialHolidays,
      );
      _branchSettings[branchId] = updated;
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, SpecialHolidayModel>> addSpecialHoliday(
    SpecialHolidayModel holiday,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 150));
      final branchId = _getActiveBranchId();
      final current = _getOrInitSettings(branchId);

      final newHoliday = holiday.copyWith(
        id: holiday.id ?? 'HOL-${DateTime.now().millisecondsSinceEpoch}',
      );
      final currentList = List<SpecialHolidayModel>.from(
        current.specialHolidays ?? [],
      );
      currentList.insert(0, newHoliday);
      _branchSettings[branchId] = current.copyWith(specialHolidays: currentList);
      return Right(newHoliday);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, Unit>> deleteSpecialHoliday(String holidayId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 150));
      final branchId = _getActiveBranchId();
      final current = _getOrInitSettings(branchId);

      final currentList = List<SpecialHolidayModel>.from(
        current.specialHolidays ?? [],
      );
      currentList.removeWhere((item) => item.id == holidayId);
      _branchSettings[branchId] = current.copyWith(specialHolidays: currentList);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      // In mock/demo: accept current password if matches or if it's default
      if (currentPassword != _adminPassword && currentPassword != '123456') {
        return const Left(ServerFailure(errMessage: 'current_password_incorrect'));
      }
      _adminPassword = newPassword;
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  void copyBranchSettings({
    required String sourceBranchId,
    required String targetBranchId,
    required bool copyWorkingHours,
    required bool copySpecialHolidays,
  }) {
    final source = _getOrInitSettings(sourceBranchId);
    var target = _getOrInitSettings(targetBranchId);

    if (copyWorkingHours) {
      target = target.copyWith(
        workingDays: source.workingDays != null
            ? List<String>.from(source.workingDays!)
            : null,
        openingTime: source.openingTime,
        closingTime: source.closingTime,
      );
    }

    if (copySpecialHolidays) {
      target = target.copyWith(
        specialHolidays: source.specialHolidays != null
            ? List<SpecialHolidayModel>.from(source.specialHolidays!)
            : null,
      );
    }

    _branchSettings[targetBranchId] = target;
  }

  void syncFromBranchModel(BranchModel branch) {
    if (branch.id == null) return;
    final current = _getOrInitSettings(branch.id!);
    _branchSettings[branch.id!] = current.copyWith(
      companyName: branch.name ?? current.companyName,
      phone: branch.phone ?? current.phone,
      address: branch.address ?? current.address,
      workingDays: branch.workingDays ?? current.workingDays,
      openingTime: branch.openingTime ?? current.openingTime,
      closingTime: branch.closingTime ?? current.closingTime,
      specialHolidays: branch.specialHolidays ?? current.specialHolidays,
    );
  }
}

typedef SettingsRepoImpl = SettingsMockRepoImpl;
