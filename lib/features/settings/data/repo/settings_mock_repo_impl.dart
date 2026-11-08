import 'package:dartz/dartz.dart';
import '../../../../core/api/api_consumer.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repo/settings_repo.dart';
import '../models/company_settings_model.dart';
import '../models/special_holiday_model.dart';

class SettingsMockRepoImpl implements SettingsRepo {
  final ApiConsumer? apiConsumer;

  SettingsMockRepoImpl({this.apiConsumer}) {
    _initMockData();
  }

  late CompanySettingsModel _settings;
  String _adminPassword = 'password123';

  void _initMockData() {
    _settings = CompanySettingsModel(
      id: 'SETT-001',
      companyName: 'عيادتي',
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
      specialHolidays: [
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
      ],
      notificationEnabled: true,
      reminderMinutesBefore: 60,
    );
  }

  @override
  Future<Either<Failures, CompanySettingsModel>> getCompanySettings() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return Right(_settings);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, CompanySettingsModel>> updateCompanySettings(
    CompanySettingsModel settings,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      _settings = settings.copyWith(
        id: _settings.id,
        specialHolidays: settings.specialHolidays ?? _settings.specialHolidays,
      );
      return Right(_settings);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, SpecialHolidayModel>> addSpecialHoliday(
    SpecialHolidayModel holiday,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final newHoliday = holiday.copyWith(
        id: holiday.id ?? 'HOL-${DateTime.now().millisecondsSinceEpoch}',
      );
      final currentList = List<SpecialHolidayModel>.from(
        _settings.specialHolidays ?? [],
      );
      currentList.insert(0, newHoliday);
      _settings = _settings.copyWith(specialHolidays: currentList);
      return Right(newHoliday);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, Unit>> deleteSpecialHoliday(String holidayId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final currentList = List<SpecialHolidayModel>.from(
        _settings.specialHolidays ?? [],
      );
      currentList.removeWhere((item) => item.id == holidayId);
      _settings = _settings.copyWith(specialHolidays: currentList);
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
      await Future.delayed(const Duration(milliseconds: 500));
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
}

typedef SettingsRepoImpl = SettingsMockRepoImpl;

