import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/shared/auth/data/models/profile_model.dart';

abstract class LayoutRepo {
  Future<Either<Failures, ProfileModel>> getProfile();
}
