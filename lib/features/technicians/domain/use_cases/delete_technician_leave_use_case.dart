import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../repo/technicians_repo.dart';

class DeleteTechnicianLeaveUseCase extends UseCase<bool, String> {
  final TechniciansRepo repo;

  DeleteTechnicianLeaveUseCase({required this.repo});

  @override
  Future<Either<Failures, bool>> call(String leaveId) {
    return repo.deleteTechnicianLeave(leaveId: leaveId);
  }
}
