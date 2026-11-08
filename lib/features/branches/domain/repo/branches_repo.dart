import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/copy_branch_settings_param.dart';

abstract class BranchesRepo {
  Future<Either<Failures, List<BranchModel>>> getBranches();

  Future<Either<Failures, BranchModel>> getBranchById(String id);

  Future<Either<Failures, BranchModel>> createBranch(
    BranchModel branch, {
    required String currentUserId,
  });

  Future<Either<Failures, BranchModel>> updateBranch(
    BranchModel branch, {
    required String currentUserId,
  });

  Future<Either<Failures, BranchModel>> toggleBranchStatus({
    required String branchId,
    required bool isActive,
    required String currentUserId,
    bool forceWithActiveBookings = false,
  });

  Future<Either<Failures, BranchModel>> setMainBranch({
    required String branchId,
    required String currentUserId,
  });

  Future<Either<Failures, BranchModel>> copySettingsFromBranch(
    CopyBranchSettingsParam param, {
    required String currentUserId,
  });
}

