import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/doctor_leave_model.dart';
import '../repo/doctors_repo.dart';

class AddDoctorLeaveUseCase {
  final DoctorsRepo repo;

  AddDoctorLeaveUseCase({required this.repo});

  Future<Either<Failures, DoctorLeaveModel>> call(
    DoctorLeaveModel leave, {
    bool force = false,
  }) {
    return repo.addDoctorLeave(leave: leave, force: force);
  }
}

