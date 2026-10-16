import 'package:dartz/dartz.dart';
import 'package:purexo/core/errors/failures.dart';
import 'package:purexo/shared/auth/data/models/profile_model.dart';

abstract class LayoutRepo {
  Future<Either<Failures, ProfileModel>> getProfile();
}
