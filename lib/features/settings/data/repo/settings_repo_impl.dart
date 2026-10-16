import 'package:dartz/dartz.dart';
import '../../../../core/api/api_consumer.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repo/settings_repo.dart';
import '../models/company_settings_model.dart';
import '../models/special_holiday_model.dart';

class SettingsRepoImpl implements SettingsRepo {
  final ApiConsumer? apiConsumer;

  SettingsRepoImpl({this.apiConsumer}) {
    _initMockData();
  }

  late CompanySettingsModel _settings;
  String _adminPassword = 'password123';

  void _initMockData() {
    _settings = CompanySettingsModel(
      id: 'SETT-001',
      companyName: 'بيوريكسو لخدمات النظافة والتشغيل',
      logo: 'assets/icons/purexo_logo.png',
      phone: '+974 4488 9900',
      address: 'الدوحة، قطر - طريق لوسيل، برج الميرة، الطابق 14',
      defaultHourlyRate: 100,
      workingDays: const [
        'saturday',
        'sunday',
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
      ],
      openingTime: '08:00',
      closingTime: '20:00',
      specialHolidays: [
        SpecialHolidayModel(
          id: 'HOL-01',
          name: 'اليوم الوطني لدولة قطر',
          startDate: DateTime(2026, 12, 18),
          endDate: DateTime(2026, 12, 18),
        ),
        SpecialHolidayModel(
          id: 'HOL-02',
          name: 'عيد الفطر المبارك',
          startDate: DateTime(2027, 3, 9),
          endDate: DateTime(2027, 3, 11),
        ),
        SpecialHolidayModel(
          id: 'HOL-03',
          name: 'اليوم الرياضي للدولة',
          startDate: DateTime(2027, 2, 9),
          endDate: DateTime(2027, 2, 9),
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
