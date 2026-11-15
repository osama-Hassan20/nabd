import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/prescription_template_model.dart';
import '../repo/drugs_repo.dart';

class GetDoctorTemplatesUseCase {
  final DrugsRepo repo;

  GetDoctorTemplatesUseCase({required this.repo});

  Future<Either<Failures, List<PrescriptionTemplateModel>>> call(String doctorId) {
    return repo.getDoctorTemplates(doctorId);
  }
}

