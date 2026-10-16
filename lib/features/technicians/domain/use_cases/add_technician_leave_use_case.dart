import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/technician_leave_model.dart';
import '../repo/technicians_repo.dart';

class AddTechnicianLeaveUseCase
    extends UseCase<TechnicianLeaveModel, TechnicianLeaveModel> {
  final TechniciansRepo repo;

  AddTechnicianLeaveUseCase({required this.repo});

  @override
  Future<Either<Failures, TechnicianLeaveModel>> call(
    TechnicianLeaveModel params,
  ) {
    return repo.addTechnicianLeave(leave: params);
  }
}
