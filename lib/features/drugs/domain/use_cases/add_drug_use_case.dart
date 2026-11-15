import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import '../../data/models/drug_model.dart';
import '../repo/drugs_repo.dart';

class AddDrugParams extends Equatable {
  final DrugModel drug;
  final String userId;

  const AddDrugParams({
    required this.drug,
    required this.userId,
  });

  @override
  List<Object?> get props => [drug, userId];
}

class AddDrugUseCase {
  final DrugsRepo repo;
  final PermissionEvaluator permissionEvaluator;
  final AuditLogger auditLogger;

  AddDrugUseCase({
    required this.repo,
    required this.permissionEvaluator,
    required this.auditLogger,
  });

  Future<Either<Failures, DrugModel>> call(AddDrugParams params) async {
    if (!permissionEvaluator.can(StaffPermissionEnum.manageDrugCatalog)) {
      return const Left(PermissionDeniedFailure(errMessage: 'permission_denied'));
    }

    final res = await repo.addDrug(params.drug.copyWith(createdByUserId: params.userId));
    return res.fold(
      (failure) => Left(failure),
      (created) {
        auditLogger.log(
          eventType: 'drug_created',
          performedByUserId: params.userId,
          details: jsonEncode({
            'drugId': created.id,
            'categoryId': created.categoryId,
            'userId': params.userId,
          }),
        );
        return Right(created);
      },
    );
  }
}
