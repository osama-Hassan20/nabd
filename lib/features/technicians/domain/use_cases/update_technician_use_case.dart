import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/technician_model.dart';
import '../repo/technicians_repo.dart';

class UpdateTechnicianUseCase
    extends UseCase<TechnicianModel, TechnicianModel> {
  final TechniciansRepo repo;

  UpdateTechnicianUseCase({required this.repo});

  @override
  Future<Either<Failures, TechnicianModel>> call(TechnicianModel params) {
    return repo.updateTechnician(technician: params);
  }
}
