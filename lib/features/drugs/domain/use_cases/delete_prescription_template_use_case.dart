import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import '../repo/drugs_repo.dart';

class DeleteTemplateParams extends Equatable {
  final String templateId;
  final String doctorId;

  const DeleteTemplateParams({
    required this.templateId,
    required this.doctorId,
  });

  @override
  List<Object?> get props => [templateId, doctorId];
}

class DeletePrescriptionTemplateUseCase {
  final DrugsRepo repo;
  final AuditLogger auditLogger;

  DeletePrescriptionTemplateUseCase({
    required this.repo,
    required this.auditLogger,
  });

  Future<Either<Failures, Unit>> call(DeleteTemplateParams params) async {
    final res = await repo.deletePrescriptionTemplate(
      params.templateId,
      params.doctorId,
    );

    return res.fold(
      (failure) => Left(failure),
      (unit) {
        auditLogger.log(
          eventType: 'prescription_template_deleted',
          performedByUserId: params.doctorId,
          details: jsonEncode({
            'templateId': params.templateId,
            'doctorId': params.doctorId,
          }),
        );
        return Right(unit);
      },
    );
  }
}
