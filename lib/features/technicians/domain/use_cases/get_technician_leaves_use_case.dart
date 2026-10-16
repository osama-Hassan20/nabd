import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/technician_leave_model.dart';
import '../repo/technicians_repo.dart';

class GetTechnicianLeavesUseCase
    extends UseCase<List<TechnicianLeaveModel>, String> {
  final TechniciansRepo repo;

  GetTechnicianLeavesUseCase({required this.repo});

  @override
  Future<Either<Failures, List<TechnicianLeaveModel>>> call(
    String technicianId,
  ) {
    return repo.getTechnicianLeaves(technicianId: technicianId);
  }
}
