import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/medical_service_model.dart';
import '../repo/medical_services_repo.dart';

class UpdateMedicalServiceUseCase
    implements UseCase<MedicalServiceModel, MedicalServiceModel> {
  final MedicalServicesRepo repo;

  UpdateMedicalServiceUseCase({required this.repo});

  @override
  Future<Either<Failures, MedicalServiceModel>> call(MedicalServiceModel params) {
    return repo.updateMedicalService(params);
  }
}

