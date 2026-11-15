import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import '../repo/drugs_repo.dart';

class ArchiveDrugParams extends Equatable {
  final String drugId;
  final String userId;

  const ArchiveDrugParams({
    required this.drugId,
    required this.userId,
  });

  @override
  List<Object?> get props => [drugId, userId];
}

class ArchiveDrugUseCase {
  final DrugsRepo repo;
  final PermissionEvaluator permissionEvaluator;
  final AuditLogger auditLogger;

  ArchiveDrugUseCase({
    required this.repo,
    required this.permissionEvaluator,
    required this.auditLogger,
  });

  Future<Either<Failures, Unit>> call(ArchiveDrugParams params) async {
    if (!permissionEvaluator.can(StaffPermissionEnum.manageDrugCatalog)) {
      return const Left(PermissionDeniedFailure(errMessage: 'permission_denied'));
    }

    final res = await repo.archiveDrug(params.drugId);
    return res.fold(
      (failure) => Left(failure),
      (unit) {
        auditLogger.log(
          eventType: 'drug_archived',
          performedByUserId: params.userId,
          details: jsonEncode({
            'drugId': params.drugId,
            'userId': params.userId,
          }),
        );
        return Right(unit);
      },
    );
  }
}
