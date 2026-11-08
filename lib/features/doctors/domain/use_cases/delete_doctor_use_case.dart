import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import '../repo/doctors_repo.dart';

class DeleteDoctorUseCase extends UseCase<bool, String> {
  final DoctorsRepo repo;

  DeleteDoctorUseCase({required this.repo});

  @override
  Future<Either<Failures, bool>> call(String id) {
    return repo.deleteDoctor(id: id);
  }
}

