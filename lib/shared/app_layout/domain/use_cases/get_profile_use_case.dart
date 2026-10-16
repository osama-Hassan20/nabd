import 'package:dartz/dartz.dart';
import 'package:purexo/core/errors/failures.dart';
import 'package:purexo/shared/auth/data/models/profile_model.dart';
import 'package:purexo/shared/app_layout/domain/repositories/layout_repo.dart';

class GetProfileUseCase {
  final LayoutRepo repository;

  GetProfileUseCase({required this.repository});

  Future<Either<Failures, ProfileModel>> call() {
    return repository.getProfile();
  }
}
