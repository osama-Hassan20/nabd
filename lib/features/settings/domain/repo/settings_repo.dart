import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/company_settings_model.dart';
import '../../data/models/special_holiday_model.dart';

abstract class SettingsRepo {
  Future<Either<Failures, CompanySettingsModel>> getCompanySettings();
  Future<Either<Failures, CompanySettingsModel>> updateCompanySettings(
    CompanySettingsModel settings,
  );
  Future<Either<Failures, SpecialHolidayModel>> addSpecialHoliday(
    SpecialHolidayModel holiday,
  );
  Future<Either<Failures, Unit>> deleteSpecialHoliday(String holidayId);
  Future<Either<Failures, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
