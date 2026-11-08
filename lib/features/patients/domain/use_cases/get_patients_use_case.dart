import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import '../../data/models/patients_response_model.dart';
import '../repo/patients_repo.dart';

class GetPatientsUseCase
    extends UseCase<PatientsResponseModel, PaginationParams> {
  final PatientsRepo repo;

  GetPatientsUseCase({required this.repo});

  @override
  Future<Either<Failures, PatientsResponseModel>> call(
      PaginationParams params) {
    return repo.getPatients(params: params);
  }
}

