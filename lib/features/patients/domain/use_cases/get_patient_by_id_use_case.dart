import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import '../../data/models/patient_model.dart';
import '../repo/patients_repo.dart';

class GetPatientByIdUseCase extends UseCase<PatientModel, String> {
  final PatientsRepo repo;

  GetPatientByIdUseCase({required this.repo});

  @override
  Future<Either<Failures, PatientModel>> call(String id) {
    return repo.getPatientById(id: id);
  }
}

