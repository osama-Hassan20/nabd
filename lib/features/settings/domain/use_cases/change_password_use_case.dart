import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../repo/settings_repo.dart';

class ChangePasswordParams {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
  });
}

class ChangePasswordUseCase implements UseCase<Unit, ChangePasswordParams> {
  final SettingsRepo repo;

  ChangePasswordUseCase({required this.repo});

  @override
  Future<Either<Failures, Unit>> call(ChangePasswordParams params) {
    return repo.changePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
  }
}
