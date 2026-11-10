import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/visit_model.dart';
import '../repo/visits_repo.dart';

class SaveVisitDraftUseCase implements UseCase<VisitModel, VisitModel> {
  final VisitsRepo repo;
  final PermissionEvaluator? permissionEvaluator;

  SaveVisitDraftUseCase({
    required this.repo,
    this.permissionEvaluator,
  });

  @override
  Future<Either<Failures, VisitModel>> call(VisitModel draft) {
    if (permissionEvaluator != null) {
      final canEdit = permissionEvaluator!.can(
        StaffPermissionEnum.editMedicalDiagnosis,
        branchId: draft.branchId,
        patientDoctorIds: draft.doctorId != null ? {draft.doctorId!} : null,
      );
      if (!canEdit) {
        return Future.value(
          const Left(
            ValidationFailure(errMessage: 'permission_denied_edit_diagnosis'),
          ),
        );
      }
    }

    return repo.saveVisitDraft(draft: draft);
  }
}
