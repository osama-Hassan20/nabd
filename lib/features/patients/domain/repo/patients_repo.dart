import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import '../../data/models/enums/blood_group_enum.dart';
import '../../data/models/enums/gender_enum.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/patients_response_model.dart';

abstract class PatientsRepo {
  Future<Either<Failures, PatientsResponseModel>> getPatients({
    required PaginationParams params,
    String? search,
    GenderEnum? gender,
    BloodGroupEnum? bloodGroup,
    bool? hasDebt,
    bool isArchived = false,
  });

  Future<Either<Failures, PatientModel>> getPatientById({
    required String id,
  });

  Future<Either<Failures, PatientModel>> addPatient({
    required PatientModel patient,
    bool allowDuplicatePhone = false,
  });

  Future<Either<Failures, PatientModel>> updatePatient({
    required PatientModel patient,
    bool allowDuplicatePhone = false,
  });

  Future<Either<Failures, List<PatientModel>>> findPatientsByPhone({
    required String phone,
    String? excludePatientId,
  });

  Future<Either<Failures, String>> archivePatient({
    required String id,
    String? reason,
  });

  Future<Either<Failures, String>> unarchivePatient({
    required String id,
  });

  Future<Either<Failures, String>> deletePatient({
    required String id,
  });

  Future<Either<Failures, bool>> checkDuplicate({
    String? phone,
    String? excludePatientId,
  });
}
