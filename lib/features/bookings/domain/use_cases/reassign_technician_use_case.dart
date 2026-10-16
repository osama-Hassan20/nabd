import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../repo/bookings_repo.dart';
import 'params/reassign_technician_params.dart';

class ReassignTechnicianUseCase implements UseCase<Unit, ReassignTechnicianParams> {
  final BookingsRepo repo;

  ReassignTechnicianUseCase({required this.repo});

  @override
  Future<Either<Failures, Unit>> call(ReassignTechnicianParams params) {
    return repo.reassignTechnician(params);
  }
}
