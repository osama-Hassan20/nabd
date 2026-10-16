import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/params.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/company_settings_model.dart';
import '../repo/settings_repo.dart';

class GetCompanySettingsUseCase
    implements UseCase<CompanySettingsModel, NoParams> {
  final SettingsRepo repo;

  GetCompanySettingsUseCase({required this.repo});

  @override
  Future<Either<Failures, CompanySettingsModel>> call(NoParams params) {
    return repo.getCompanySettings();
  }
}
