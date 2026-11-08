import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import '../repo/patients_repo.dart';

class UnarchivePatientUseCase extends UseCase<String, String> {
  final PatientsRepo repo;

  UnarchivePatientUseCase({required this.repo});

  @override
  Future<Either<Failures, String>> call(String id) {
    return repo.unarchivePatient(id: id);
  }
}

