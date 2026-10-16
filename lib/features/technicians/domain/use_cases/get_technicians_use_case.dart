import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/params.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/technicians_response_model.dart';
import '../repo/technicians_repo.dart';

class GetTechniciansUseCase
    extends UseCase<TechniciansResponseModel, PaginationParams> {
  final TechniciansRepo repo;

  GetTechniciansUseCase({required this.repo});

  @override
  Future<Either<Failures, TechniciansResponseModel>> call(
    PaginationParams params,
  ) {
    return repo.getTechnicians(params: params);
  }
}
