import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../repo/settings_repo.dart';

class DeleteSpecialHolidayUseCase implements UseCase<Unit, String> {
  final SettingsRepo repo;

  DeleteSpecialHolidayUseCase({required this.repo});

  @override
  Future<Either<Failures, Unit>> call(String holidayId) {
    return repo.deleteSpecialHoliday(holidayId);
  }
}
