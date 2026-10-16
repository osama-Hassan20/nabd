import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/technician_model.dart';
import '../repo/technicians_repo.dart';

class GetTechnicianByIdUseCase extends UseCase<TechnicianModel, String> {
  final TechniciansRepo repo;

  GetTechnicianByIdUseCase({required this.repo});

  @override
  Future<Either<Failures, TechnicianModel>> call(String id) {
    return repo.getTechnicianById(id: id);
  }
}
