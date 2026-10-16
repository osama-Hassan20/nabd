import 'package:eyadty/core/api/end_points.dart';
import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/shared/auth/data/models/profile_model.dart';
import '../../../../core/api/api_consumer.dart';
import '../../domain/repositories/layout_repo.dart';

class LayoutRepoImpl implements LayoutRepo {
  final ApiConsumer apiConsumer;

  LayoutRepoImpl({required this.apiConsumer});

  @override
  Future<Either<Failures, ProfileModel>> getProfile() async {
    try {
      final response = await apiConsumer.get(path: EndPoints.profile);
      final profileModel = ProfileModel.fromJson(response['data']);
      return right(profileModel);
    } catch (e) {
      return left(ServerFailure(errMessage: e.toString()));
    }
  }
}
