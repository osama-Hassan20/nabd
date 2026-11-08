import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/medical_service_model.dart';
import '../repo/medical_services_repo.dart';
import 'params/get_medical_services_params.dart';

class GetMedicalServicesUseCase
    implements UseCase<List<MedicalServiceModel>, GetMedicalServicesParams> {
  final MedicalServicesRepo repo;

  GetMedicalServicesUseCase({required this.repo});

  @override
  Future<Either<Failures, List<MedicalServiceModel>>> call(
    GetMedicalServicesParams params,
  ) {
    return repo.getMedicalServices(
      onlyActive: params.onlyActive,
      doctorId: params.doctorId,
      query: params.query,
    );
  }
}

