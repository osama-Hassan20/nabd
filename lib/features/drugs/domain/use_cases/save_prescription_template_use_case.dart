import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import '../../data/models/prescription_template_model.dart';
import '../repo/drugs_repo.dart';

class SavePrescriptionTemplateUseCase {
  final DrugsRepo repo;
  final AuditLogger auditLogger;

  SavePrescriptionTemplateUseCase({
    required this.repo,
    required this.auditLogger,
  });

  Future<Either<Failures, PrescriptionTemplateModel>> call(
    PrescriptionTemplateModel template,
  ) async {
    final isNew = template.id == null;
    final res = await repo.savePrescriptionTemplate(template);

    return res.fold(
      (failure) => Left(failure),
      (saved) {
        auditLogger.log(
          eventType: isNew
              ? 'prescription_template_created'
              : 'prescription_template_updated',
          performedByUserId: saved.doctorId,
          details: jsonEncode({
            'templateId': saved.id,
            'doctorId': saved.doctorId,
            'itemsCount': saved.items?.length ?? 0,
          }),
        );
        return Right(saved);
      },
    );
  }
}
