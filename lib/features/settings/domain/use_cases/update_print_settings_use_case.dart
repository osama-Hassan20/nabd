import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/company_settings_model.dart';
import '../repo/settings_repo.dart';

class UpdatePrintSettingsParams {
  final String? branchId;
  final String? receiptPrintFormat;
  final String? shiftReportPrintFormat;
  final String? prescriptionPrintFormat;

  const UpdatePrintSettingsParams({
    this.branchId,
    this.receiptPrintFormat,
    this.shiftReportPrintFormat,
    this.prescriptionPrintFormat,
  });
}

class UpdatePrintSettingsUseCase
    implements UseCase<CompanySettingsModel, UpdatePrintSettingsParams> {
  final SettingsRepo repo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  UpdatePrintSettingsUseCase({
    required this.repo,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  static const Set<String> _validFormats = {'a4', 'thermal80'};

  @override
  Future<Either<Failures, CompanySettingsModel>> call(
    UpdatePrintSettingsParams params,
  ) async {
    final targetBranchId =
        params.branchId ?? currentUserProvider?.activeBranchId;

    final isAllowed = permissionEvaluator?.can(
          StaffPermissionEnum.accessSettings,
          branchId: targetBranchId,
        ) ??
        (currentUserProvider?.currentUser?.isOwner == true);

    if (!isAllowed) {
      return const Left(
        ValidationFailure(errMessage: 'settings_permission_denied'),
      );
    }

    if (params.receiptPrintFormat != null &&
        !_validFormats.contains(params.receiptPrintFormat)) {
      return const Left(
        ValidationFailure(errMessage: 'invalid_print_format'),
      );
    }
    if (params.shiftReportPrintFormat != null &&
        !_validFormats.contains(params.shiftReportPrintFormat)) {
      return const Left(
        ValidationFailure(errMessage: 'invalid_print_format'),
      );
    }
    if (params.prescriptionPrintFormat != null &&
        !_validFormats.contains(params.prescriptionPrintFormat)) {
      return const Left(
        ValidationFailure(errMessage: 'invalid_print_format'),
      );
    }

    final currentRes = await repo.getCompanySettings();
    if (currentRes.isLeft()) {
      return currentRes;
    }
    final current = currentRes.getOrElse(() => const CompanySettingsModel());

    final toSave = current.copyWith(
      receiptPrintFormat: params.receiptPrintFormat ?? current.receiptPrintFormat,
      shiftReportPrintFormat:
          params.shiftReportPrintFormat ?? current.shiftReportPrintFormat,
      prescriptionPrintFormat:
          params.prescriptionPrintFormat ?? current.prescriptionPrintFormat,
    );

    final updateRes = await repo.updateCompanySettings(toSave);

    return updateRes.fold(
      (failure) => Left(failure),
      (saved) {
        auditLogger?.log(
          eventType: 'print_settings_updated',
          targetUserId: null,
          performedByUserId: currentUserProvider?.currentUser?.id,
          branchId: targetBranchId,
          details:
              'receiptFormat=${saved.receiptPrintFormat}, shiftReportFormat=${saved.shiftReportPrintFormat}, prescriptionFormat=${saved.prescriptionPrintFormat}',
        );
        return Right(saved);
      },
    );
  }
}

