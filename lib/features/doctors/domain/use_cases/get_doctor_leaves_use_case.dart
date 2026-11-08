import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import '../../data/models/doctor_leave_model.dart';
import '../repo/doctors_repo.dart';

class GetDoctorLeavesUseCase extends UseCase<List<DoctorLeaveModel>, String> {
  final DoctorsRepo repo;

  GetDoctorLeavesUseCase({required this.repo});

  @override
  Future<Either<Failures, List<DoctorLeaveModel>>> call(String doctorId) {
    return repo.getDoctorLeaves(doctorId: doctorId);
  }
}

