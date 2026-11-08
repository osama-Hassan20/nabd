import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/medical_service_model.dart';
import '../repo/medical_services_repo.dart';

class ToggleMedicalServiceStatusUseCase
    implements UseCase<MedicalServiceModel, String> {
  final MedicalServicesRepo repo;

  ToggleMedicalServiceStatusUseCase({required this.repo});

  @override
  Future<Either<Failures, MedicalServiceModel>> call(String id) {
    return repo.toggleServiceStatus(id);
  }
}

