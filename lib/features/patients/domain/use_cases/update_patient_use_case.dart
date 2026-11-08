import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/patient_model.dart';
import '../repo/patients_repo.dart';

class UpdatePatientUseCase {
  final PatientsRepo repo;

  UpdatePatientUseCase({required this.repo});

  Future<Either<Failures, PatientModel>> call(
    PatientModel patient, {
    bool allowDuplicatePhone = false,
  }) {
    return repo.updatePatient(
      patient: patient,
      allowDuplicatePhone: allowDuplicatePhone,
    );
  }
}

