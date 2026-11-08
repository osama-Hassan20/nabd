import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../repo/medical_services_repo.dart';

class DeleteMedicalServiceUseCase implements UseCase<Unit, String> {
  final MedicalServicesRepo repo;

  DeleteMedicalServiceUseCase({required this.repo});

  @override
  Future<Either<Failures, Unit>> call(String id) {
    return repo.deleteMedicalService(id);
  }
}

