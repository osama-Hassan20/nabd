import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import '../repo/drugs_repo.dart';

class UpdateAllergyAliasesParams extends Equatable {
  final String catalogItemId;
  final List<String> aliases;
  final int aliasesCountBefore;
  final String userId;

  const UpdateAllergyAliasesParams({
    required this.catalogItemId,
    required this.aliases,
    required this.aliasesCountBefore,
    required this.userId,
  });

  @override
  List<Object?> get props => [
        catalogItemId,
        aliases,
        aliasesCountBefore,
        userId,
      ];
}

class UpdateAllergyAliasesUseCase {
  final DrugsRepo repo;
  final PermissionEvaluator permissionEvaluator;
  final AuditLogger auditLogger;

  UpdateAllergyAliasesUseCase({
    required this.repo,
    required this.permissionEvaluator,
    required this.auditLogger,
  });

  Future<Either<Failures, Unit>> call(UpdateAllergyAliasesParams params) async {
    if (!permissionEvaluator.can(StaffPermissionEnum.manageDrugCatalog)) {
      return const Left(PermissionDeniedFailure(errMessage: 'permission_denied'));
    }

    final res = await repo.updateAllergyAliases(
      catalogItemId: params.catalogItemId,
      aliases: params.aliases,
    );

    return res.fold(
      (failure) => Left(failure),
      (unit) {
        auditLogger.log(
          eventType: 'allergy_aliases_updated',
          performedByUserId: params.userId,
          details: jsonEncode({
            'allergyCatalogItemId': params.catalogItemId,
            'aliasesCountBefore': params.aliasesCountBefore,
            'aliasesCountAfter': params.aliases.length,
            'userId': params.userId,
          }),
        );
        return Right(unit);
      },
    );
  }
}
