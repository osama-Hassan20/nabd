import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import '../repo/doctors_repo.dart';

class DeleteDoctorLeaveUseCase extends UseCase<bool, String> {
  final DoctorsRepo repo;

  DeleteDoctorLeaveUseCase({required this.repo});

  @override
  Future<Either<Failures, bool>> call(String leaveId) {
    return repo.deleteDoctorLeave(leaveId: leaveId);
  }
}

