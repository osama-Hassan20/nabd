import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/doctor_compensation_rule_model.dart';
import '../repo/hr_repo.dart';

class GetActiveRuleForDoctorUseCase {
  final HrRepo hrRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;

  const GetActiveRuleForDoctorUseCase({
    required this.hrRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
  });

  Future<Either<Failures, DoctorCompensationRuleModel>> call({
    required String doctorId,
    required String branchId,
    DateTime? date,
  }) async {
    final user = currentUserProvider?.currentUser;
    if (user == null || user.canAuthenticate == false) {
      return const Left(ValidationFailure(errMessage: 'permission_denied'));
    }

    if (permissionEvaluator != null) {
      final isOwner = user.isOwner == true;
      final isSelfDoctor = user.linkedDoctorId != null && user.linkedDoctorId == doctorId;
      final hasPermission = permissionEvaluator!.can(
        StaffPermissionEnum.manageCompensationRules,
        branchId: branchId,
      );

      if (!isOwner && !isSelfDoctor && !hasPermission) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    return hrRepo.getActiveRuleForDoctor(
      doctorId: doctorId,
      branchId: branchId,
      date: date,
    );
  }
}

