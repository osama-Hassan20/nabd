import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import '../../data/models/drug_model.dart';
import '../repo/drugs_repo.dart';

class ImportDrugsParams extends Equatable {
  final List<DrugModel> drugsToImport;
  final int skippedCount;
  final String userId;

  const ImportDrugsParams({
    required this.drugsToImport,
    required this.skippedCount,
    required this.userId,
  });

  @override
  List<Object?> get props => [drugsToImport, skippedCount, userId];
}

class ImportDrugsUseCase {
  final DrugsRepo repo;
  final PermissionEvaluator permissionEvaluator;
  final AuditLogger auditLogger;

  ImportDrugsUseCase({
    required this.repo,
    required this.permissionEvaluator,
    required this.auditLogger,
  });

  Future<Either<Failures, int>> call(ImportDrugsParams params) async {
    if (!permissionEvaluator.can(StaffPermissionEnum.manageDrugCatalog)) {
      return const Left(PermissionDeniedFailure(errMessage: 'permission_denied'));
    }

    final res = await repo.importDrugsBatch(params.drugsToImport);

    return res.fold(
      (failure) => Left(failure),
      (importedCount) {
        auditLogger.log(
          eventType: 'drugs_imported_batch',
          performedByUserId: params.userId,
          details: jsonEncode({
            'importedCount': importedCount,
            'skippedCount': params.skippedCount,
            'userId': params.userId,
          }),
        );
        return Right(importedCount);
      },
    );
  }
}
