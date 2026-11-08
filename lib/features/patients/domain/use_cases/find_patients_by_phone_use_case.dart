import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/patient_model.dart';
import '../repo/patients_repo.dart';

class FindPatientsByPhoneUseCase {
  final PatientsRepo repo;

  FindPatientsByPhoneUseCase({required this.repo});

  Future<Either<Failures, List<PatientModel>>> call({
    required String phone,
    String? excludePatientId,
  }) {
    return repo.findPatientsByPhone(
      phone: phone,
      excludePatientId: excludePatientId,
    );
  }
}

