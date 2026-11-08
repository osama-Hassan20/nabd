import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import '../../data/models/doctors_response_model.dart';
import '../repo/doctors_repo.dart';

class GetDoctorsUseCase
    extends UseCase<DoctorsResponseModel, PaginationParams> {
  final DoctorsRepo repo;

  GetDoctorsUseCase({required this.repo});

  @override
  Future<Either<Failures, DoctorsResponseModel>> call(
      PaginationParams params) {
    return repo.getDoctors(params: params);
  }
}

