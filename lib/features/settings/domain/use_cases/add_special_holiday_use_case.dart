import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/special_holiday_model.dart';
import '../repo/settings_repo.dart';

class AddSpecialHolidayUseCase
    implements UseCase<SpecialHolidayModel, SpecialHolidayModel> {
  final SettingsRepo repo;

  AddSpecialHolidayUseCase({required this.repo});

  @override
  Future<Either<Failures, SpecialHolidayModel>> call(
    SpecialHolidayModel params,
  ) {
    return repo.addSpecialHoliday(params);
  }
}
