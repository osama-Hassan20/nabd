import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import '../../data/models/doctor_model.dart';
import '../repo/doctors_repo.dart';

class GetDoctorByIdUseCase extends UseCase<DoctorModel, String> {
  final DoctorsRepo repo;

  GetDoctorByIdUseCase({required this.repo});

  @override
  Future<Either<Failures, DoctorModel>> call(String id) {
    return repo.getDoctorById(id: id);
  }
}

