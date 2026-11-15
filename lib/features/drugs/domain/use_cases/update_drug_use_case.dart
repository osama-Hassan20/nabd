import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import '../../data/models/drug_model.dart';
import '../repo/drugs_repo.dart';

class UpdateDrugParams extends Equatable {
  final DrugModel drug;
  final List<String> updatedFields;
  final String userId;

  const UpdateDrugParams({
    required this.drug,
    required this.updatedFields,
    required this.userId,
  });

  @override
  List<Object?> get props => [drug, updatedFields, userId];
}

class UpdateDrugUseCase {
  final DrugsRepo repo;
  final PermissionEvaluator permissionEvaluator;
  final AuditLogger auditLogger;

  UpdateDrugUseCase({
    required this.repo,
    required this.permissionEvaluator,
    required this.auditLogger,
  });

  Future<Either<Failures, DrugModel>> call(UpdateDrugParams params) async {
    if (!permissionEvaluator.can(StaffPermissionEnum.manageDrugCatalog)) {
      return const Left(PermissionDeniedFailure(errMessage: 'permission_denied'));
    }

    final res = await repo.updateDrug(params.drug);
    return res.fold(
      (failure) => Left(failure),
      (updated) {
        auditLogger.log(
          eventType: 'drug_updated',
          performedByUserId: params.userId,
          details: jsonEncode({
            'drugId': updated.id,
            'updatedFields': params.updatedFields,
            'userId': params.userId,
          }),
        );
        return Right(updated);
      },
    );
  }
}
