import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import '../../data/models/doctor_model.dart';
import '../repo/doctors_repo.dart';

class AddDoctorUseCase extends UseCase<DoctorModel, DoctorModel> {
  final DoctorsRepo repo;

  AddDoctorUseCase({required this.repo});

  @override
  Future<Either<Failures, DoctorModel>> call(DoctorModel doctor) {
    return repo.addDoctor(doctor: doctor);
  }
}

