import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import '../../data/models/drug_model.dart';
import '../../data/models/enums/review_status_enum.dart';
import '../repo/drugs_repo.dart';

class ReviewQuickAddDrugParams extends Equatable {
  final String drugId;
  final ReviewStatusEnum decision;
  final String reviewedByUserId;
  final String? mergeTargetDrugId;

  const ReviewQuickAddDrugParams({
    required this.drugId,
    required this.decision,
    required this.reviewedByUserId,
    this.mergeTargetDrugId,
  });

  @override
  List<Object?> get props => [drugId, decision, reviewedByUserId, mergeTargetDrugId];
}

class ReviewQuickAddDrugUseCase {
  final DrugsRepo repo;
  final PermissionEvaluator permissionEvaluator;
  final AuditLogger auditLogger;

  ReviewQuickAddDrugUseCase({
    required this.repo,
    required this.permissionEvaluator,
    required this.auditLogger,
  });

  Future<Either<Failures, DrugModel>> call(ReviewQuickAddDrugParams params) async {
    if (!permissionEvaluator.can(StaffPermissionEnum.manageDrugCatalog)) {
      return const Left(PermissionDeniedFailure(errMessage: 'permission_denied'));
    }

    final res = await repo.reviewQuickAddDrug(
      drugId: params.drugId,
      decision: params.decision,
      reviewedByUserId: params.reviewedByUserId,
      mergeTargetDrugId: params.mergeTargetDrugId,
    );

    return res.fold(
      (failure) => Left(failure),
      (updated) {
        auditLogger.log(
          eventType: 'drug_reviewed',
          performedByUserId: params.reviewedByUserId,
          details: jsonEncode({
            'drugId': params.drugId,
            'decision': params.decision.name,
            'reviewedByUserId': params.reviewedByUserId,
          }),
        );
        return Right(updated);
      },
    );
  }
}
