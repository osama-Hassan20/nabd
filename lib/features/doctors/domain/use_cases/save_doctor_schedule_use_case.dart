import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/doctor_schedule_model.dart';
import '../repo/doctors_repo.dart';

class SaveDoctorScheduleUseCase {
  final DoctorsRepo repo;

  SaveDoctorScheduleUseCase({required this.repo});

  Future<Either<Failures, DoctorScheduleModel>> call(
    DoctorScheduleModel schedule,
  ) {
    return repo.saveDoctorSchedule(schedule: schedule);
  }
}

