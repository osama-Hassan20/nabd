import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import '../repo/patients_repo.dart';

class DeletePatientUseCase extends UseCase<String, String> {
  final PatientsRepo repo;

  DeletePatientUseCase({required this.repo});

  @override
  Future<Either<Failures, String>> call(String id) {
    return repo.deletePatient(id: id);
  }
}

