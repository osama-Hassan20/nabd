import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../data/models/enums/addendum_change_type_enum.dart';
import '../../data/models/enums/visit_status_enum.dart';
import '../../data/models/prescription_item_model.dart';
import '../../data/models/visit_addendum_model.dart';
import '../../data/models/visit_model.dart';
import '../repo/visits_repo.dart';

class AddVisitAddendumParams {
  final String visitId;
  final String reason;
  final AddendumChangeTypeEnum changeType;
  final String? affectedItemId;
  final PrescriptionItemModel? oldItemSnapshot;
  final PrescriptionItemModel? newItemSnapshot;
  final String? diagnosisBefore;
  final String? diagnosisAfter;
  final String? notes;

  const AddVisitAddendumParams({
    required this.visitId,
    required this.reason,
    required this.changeType,
    this.affectedItemId,
    this.oldItemSnapshot,
    this.newItemSnapshot,
    this.diagnosisBefore,
    this.diagnosisAfter,
    this.notes,
  });
}

class AddVisitAddendumUseCase
    implements UseCase<VisitModel, AddVisitAddendumParams> {
  final VisitsRepo visitsRepo;
  final PermissionEvaluator permissionEvaluator;
  final AuditLogger? auditLogger;

  AddVisitAddendumUseCase({
    required this.visitsRepo,
    required this.permissionEvaluator,
    this.auditLogger,
  });

  @override
  Future<Either<Failures, VisitModel>> call(
    AddVisitAddendumParams params,
  ) async {
    // 1. Mandatory reason check
    if (params.reason.trim().isEmpty) {
      return const Left(
        ValidationFailure(errMessage: 'addendum_reason_required'),
      );
    }

    // 2. Fetch visit
    final visitRes = await visitsRepo.getVisitById(visitId: params.visitId);
    if (visitRes.isLeft()) {
      return Left(
        visitRes.fold(
          (l) => l,
          (r) => const ValidationFailure(errMessage: 'visit_not_found'),
        ),
      );
    }

    final visit = visitRes.getOrElse(() => null);
    if (visit == null) {
      return const Left(ValidationFailure(errMessage: 'visit_not_found'));
    }

    // 3. Status must be finalized
    if (visit.status != VisitStatusEnum.finalized) {
      return const Left(
        ValidationFailure(
          errMessage: 'cannot_add_addendum_to_unfinalized_visit',
        ),
      );
    }

    // 4. Assigned doctor constraint
    final user = permissionEvaluator.userProvider.currentUser;
    final linkedDoctorId = user?.linkedDoctorId;
    if (linkedDoctorId == null || linkedDoctorId != visit.doctorId) {
      return const Left(
        PermissionDeniedFailure(
          errMessage: 'only_assigned_doctor_can_add_addendum',
        ),
      );
    }

    // 5. Fail-Closed Permission Guard
    if (params.changeType == AddendumChangeTypeEnum.diagnosis) {
      final canEditDiagnosis = permissionEvaluator.can(
        StaffPermissionEnum.editMedicalDiagnosis,
        branchId: visit.branchId,
        patientDoctorIds: visit.doctorId != null ? {visit.doctorId!} : null,
      );
      if (!canEditDiagnosis) {
        return const Left(
          PermissionDeniedFailure(
            errMessage: 'permission_denied_edit_medical_diagnosis',
          ),
        );
      }

      // Check diagnosis actually differs
      if (params.diagnosisAfter == null ||
          params.diagnosisAfter!.trim().isEmpty ||
          params.diagnosisAfter!.trim() ==
              (params.diagnosisBefore ?? '').trim()) {
        return const Left(
          ValidationFailure(errMessage: 'diagnosis_addendum_must_differ'),
        );
      }
    } else {
      final canIssueRx = permissionEvaluator.can(
        StaffPermissionEnum.issuePrescription,
        branchId: visit.branchId,
        patientDoctorIds: visit.doctorId != null ? {visit.doctorId!} : null,
      );
      if (!canIssueRx) {
        return const Left(
          PermissionDeniedFailure(
            errMessage: 'permission_denied_issue_prescription',
          ),
        );
      }
    }

    // 6. Construct Addendum Model
    final addendumId = 'ADD-${(visit.addenda?.length ?? 0) + 1}';
    final addendum = VisitAddendumModel(
      id: addendumId,
      visitId: visit.id,
      doctorId: visit.doctorId,
      doctorName: visit.doctorName,
      createdAt: CairoTimeHelper.now(),
      reason: params.reason.trim(),
      changeType: params.changeType,
      affectedItemId: params.affectedItemId,
      oldItemSnapshot: params.oldItemSnapshot,
      newItemSnapshot: params.newItemSnapshot,
      diagnosisBefore: params.diagnosisBefore,
      diagnosisAfter: params.diagnosisAfter,
      notes: params.notes,
    );

    // 7. Persist via repository
    final res = await visitsRepo.addVisitAddendum(
      visitId: visit.id!,
      addendum: addendum,
    );

    // 8. Strict Security Audit (zero clinical text)
    res.fold(
      (_) {},
      (updatedVisit) {
        if (auditLogger != null) {
          auditLogger!.log(
            eventType: 'visit_addendum_added',
            performedByUserId: visit.doctorId,
            branchId: visit.branchId ??
                permissionEvaluator.userProvider.activeBranchId,
            details: jsonEncode({
              'addendumId': addendum.id,
              'visitId': visit.id,
              'doctorId': visit.doctorId,
              'changeType': addendum.changeType?.toJson(),
            }),
          );
        }
      },
    );

    return res;
  }
}
