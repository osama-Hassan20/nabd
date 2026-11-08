import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/medical_service_model.dart';
import '../repo/medical_services_repo.dart';

class AddMedicalServiceUseCase
    implements UseCase<MedicalServiceModel, MedicalServiceModel> {
  final MedicalServicesRepo repo;

  AddMedicalServiceUseCase({required this.repo});

  @override
  Future<Either<Failures, MedicalServiceModel>> call(MedicalServiceModel params) {
    return repo.addMedicalService(params);
  }
}

