import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/technician_model.dart';
import '../repo/technicians_repo.dart';

class AddTechnicianUseCase extends UseCase<TechnicianModel, TechnicianModel> {
  final TechniciansRepo repo;

  AddTechnicianUseCase({required this.repo});

  @override
  Future<Either<Failures, TechnicianModel>> call(TechnicianModel params) {
    return repo.addTechnician(technician: params);
  }
}
