import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/medical_service_model.dart';

abstract class MedicalServicesRepo {
  Future<Either<Failures, List<MedicalServiceModel>>> getMedicalServices({
    bool? onlyActive,
    String? doctorId,
    String? query,
  });

  Future<Either<Failures, MedicalServiceModel>> getMedicalServiceById(
    String id,
  );

  Future<Either<Failures, MedicalServiceModel>> addMedicalService(
    MedicalServiceModel service,
  );

  Future<Either<Failures, MedicalServiceModel>> updateMedicalService(
    MedicalServiceModel service,
  );

  Future<Either<Failures, MedicalServiceModel>> toggleServiceStatus(
    String id,
  );

  Future<Either<Failures, Unit>> deleteMedicalService(
    String id,
  );
}

