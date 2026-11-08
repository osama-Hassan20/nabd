import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/copy_branch_settings_param.dart';
import '../../domain/repo/branches_repo.dart';
import 'branches_state.dart';

class BranchesCubit extends Cubit<BranchesState> {
  final BranchesRepo branchesRepo;

  BranchesCubit({required this.branchesRepo}) : super(const BranchesState());

  Future<void> loadBranches({bool showLoading = true}) async {
    if (showLoading) {
      emit(state.copyWith(status: RequestStatusEnum.loading, clearError: true));
    }

    final result = await branchesRepo.getBranches();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ),
      ),
      (branches) => emit(
        state.copyWith(
          status: RequestStatusEnum.success,
          branches: branches,
          clearError: true,
        ),
      ),
    );
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setActiveFilter(String filter) {
    emit(state.copyWith(activeFilter: filter));
  }

  Future<bool> createBranch(
    BranchModel branch, {
    required String currentUserId,
  }) async {
    emit(state.copyWith(status: RequestStatusEnum.loading, clearError: true));

    final result = await branchesRepo.createBranch(
      branch,
      currentUserId: currentUserId,
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (created) async {
        await loadBranches(showLoading: false);
        emit(
          state.copyWith(
            status: RequestStatusEnum.success,
            successMessage: 'branch_created_successfully',
          ),
        );
        return true;
      },
    );
  }

  Future<bool> updateBranch(
    BranchModel branch, {
    required String currentUserId,
  }) async {
    emit(state.copyWith(status: RequestStatusEnum.loading, clearError: true));

    final result = await branchesRepo.updateBranch(
      branch,
      currentUserId: currentUserId,
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (updated) async {
        await loadBranches(showLoading: false);
        emit(
          state.copyWith(
            status: RequestStatusEnum.success,
            successMessage: 'branch_updated_successfully',
          ),
        );
        return true;
      },
    );
  }

  Future<bool> toggleBranchStatus({
    required String branchId,
    required bool isActive,
    required String currentUserId,
    bool forceWithActiveBookings = false,
  }) async {
    emit(state.copyWith(status: RequestStatusEnum.loading, clearError: true));

    final result = await branchesRepo.toggleBranchStatus(
      branchId: branchId,
      isActive: isActive,
      currentUserId: currentUserId,
      forceWithActiveBookings: forceWithActiveBookings,
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (updated) async {
        await loadBranches(showLoading: false);
        emit(
          state.copyWith(
            status: RequestStatusEnum.success,
            successMessage: isActive
                ? 'branch_activated_successfully'
                : 'branch_deactivated_successfully',
          ),
        );
        return true;
      },
    );
  }

  Future<bool> setMainBranch({
    required String branchId,
    required String currentUserId,
  }) async {
    emit(state.copyWith(status: RequestStatusEnum.loading, clearError: true));

    final result = await branchesRepo.setMainBranch(
      branchId: branchId,
      currentUserId: currentUserId,
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (updated) async {
        await loadBranches(showLoading: false);
        emit(
          state.copyWith(
            status: RequestStatusEnum.success,
            successMessage: 'main_branch_updated_successfully',
          ),
        );
        return true;
      },
    );
  }

  Future<bool> copySettingsFromBranch(
    CopyBranchSettingsParam param, {
    required String currentUserId,
  }) async {
    emit(state.copyWith(status: RequestStatusEnum.loading, clearError: true));

    final result = await branchesRepo.copySettingsFromBranch(
      param,
      currentUserId: currentUserId,
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (updated) async {
        await loadBranches(showLoading: false);
        emit(
          state.copyWith(
            status: RequestStatusEnum.success,
            successMessage: 'settings_copied_successfully',
          ),
        );
        return true;
      },
    );
  }
}
