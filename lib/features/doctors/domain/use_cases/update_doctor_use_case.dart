import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import '../../data/models/doctor_model.dart';
import '../repo/doctors_repo.dart';

class UpdateDoctorUseCase extends UseCase<DoctorModel, DoctorModel> {
  final DoctorsRepo repo;

  UpdateDoctorUseCase({required this.repo});

  @override
  Future<Either<Failures, DoctorModel>> call(DoctorModel doctor) {
    return repo.updateDoctor(doctor: doctor);
  }
}

