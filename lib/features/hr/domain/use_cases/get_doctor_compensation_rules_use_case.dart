import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/doctor_compensation_rule_model.dart';
import '../repo/hr_repo.dart';

class GetDoctorCompensationRulesUseCase {
  final HrRepo hrRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;

  const GetDoctorCompensationRulesUseCase({
    required this.hrRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
  });

  Future<Either<Failures, List<DoctorCompensationRuleModel>>> call({
    String? doctorId,
    String? branchId,
  }) async {
    final user = currentUserProvider?.currentUser;
    if (user == null || user.canAuthenticate == false) {
      return const Left(ValidationFailure(errMessage: 'permission_denied'));
    }

    if (permissionEvaluator != null) {
      final isOwner = user.isOwner == true;
      final isSelfDoctor = doctorId != null &&
          user.linkedDoctorId != null &&
          user.linkedDoctorId == doctorId;
      final hasPermission = permissionEvaluator!.can(
        StaffPermissionEnum.manageCompensationRules,
        branchId: branchId,
      );

      if (!isOwner && !isSelfDoctor && !hasPermission) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    return hrRepo.getCompensationRules(
      doctorId: doctorId,
      branchId: branchId,
    );
  }
}

