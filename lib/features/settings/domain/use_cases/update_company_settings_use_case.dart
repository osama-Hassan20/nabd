import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/company_settings_model.dart';
import '../repo/settings_repo.dart';

class UpdateCompanySettingsUseCase
    implements UseCase<CompanySettingsModel, CompanySettingsModel> {
  final SettingsRepo repo;

  UpdateCompanySettingsUseCase({required this.repo});

  @override
  Future<Either<Failures, CompanySettingsModel>> call(
    CompanySettingsModel params,
  ) {
    return repo.updateCompanySettings(params);
  }
}
