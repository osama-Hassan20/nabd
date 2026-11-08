import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/doctor_schedule_model.dart';
import '../repo/doctors_repo.dart';

class GetDoctorScheduleUseCase {
  final DoctorsRepo repo;

  GetDoctorScheduleUseCase({required this.repo});

  Future<Either<Failures, DoctorScheduleModel?>> call(String doctorId) {
    return repo.getDoctorSchedule(doctorId: doctorId);
  }
}

