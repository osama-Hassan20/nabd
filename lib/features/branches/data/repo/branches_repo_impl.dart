import 'package:dartz/dartz.dart';
import '../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/providers/active_bookings_count_provider.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../settings/data/models/special_holiday_model.dart';
import '../../../settings/data/repo/settings_repo_impl.dart';
import '../../../settings/domain/repo/settings_repo.dart';
import '../../domain/repo/branches_repo.dart';
import '../models/branch_model.dart';
import '../models/copy_branch_settings_param.dart';

class BranchesRepoImpl implements BranchesRepo {
  final AuditLogger? auditLogger;
  final ActiveBookingsCountProvider? activeBookingsProvider;

  BranchesRepoImpl({
    this.auditLogger,
    this.activeBookingsProvider,
  }) {
    _seedLocalData();
  }

  final List<BranchModel> _branches = [];

  void _seedLocalData() {
    _branches.addAll([
      BranchModel(
        id: 'branch_1',
        name: 'فرع المعادي',
        nameKey: 'branch_main',
        address: 'مصر - القاهرة، المعادي، شارع النصر',
        phone: '+20 2 2750 8800',
        email: 'maadi@eyadty.com',
        isActive: true,
        isMain: true,
        openingTime: '09:00',
        closingTime: '22:00',
        workingDays: const [
          'saturday',
          'sunday',
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
        ],
        specialHolidays: [
          SpecialHolidayModel(
            id: 'HOL-01',
            name: 'عيد الشرطة وثورة 25 يناير',
            startDate: DateTime(2026, 1, 25),
            endDate: DateTime(2026, 1, 25),
          ),
          SpecialHolidayModel(
            id: 'HOL-02',
            name: 'عيد الفطر المبارك',
            startDate: DateTime(2026, 3, 20),
            endDate: DateTime(2026, 3, 23),
          ),
        ],
        activeRoomsCount: 4,
        staffMembersCount: 6,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      BranchModel(
        id: 'branch_2',
        name: 'فرع مدينة نصر',
        nameKey: 'branch_second',
        address: 'مصر - القاهرة، مدينة نصر، شارع عباس العقاد',
        phone: '+20 2 2260 4400',
        email: 'nasrcity@eyadty.com',
        isActive: true,
        isMain: false,
        openingTime: '10:00',
        closingTime: '23:00',
        workingDays: const [
          'saturday',
          'sunday',
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
        ],
        specialHolidays: [
          SpecialHolidayModel(
            id: 'HOL-01',
            name: 'عيد الشرطة وثورة 25 يناير',
            startDate: DateTime(2026, 1, 25),
            endDate: DateTime(2026, 1, 25),
          ),
        ],
        activeRoomsCount: 3,
        staffMembersCount: 4,
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 1, 15),
      ),
      BranchModel(
        id: 'branch_3',
        name: 'فرع التجمع الخامس',
        nameKey: 'branch_third',
        address: 'مصر - القاهرة الجديدة، التجمع الخامس، شارع التسعين',
        phone: '+20 2 2810 5500',
        email: 'tagamoa@eyadty.com',
        isActive: false,
        isMain: false,
        openingTime: '12:00',
        closingTime: '20:00',
        workingDays: const [
          'sunday',
          'tuesday',
          'thursday',
        ],
        specialHolidays: const [],
        activeRoomsCount: 2,
        staffMembersCount: 3,
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 1),
      ),
    ]);
  }

  @override
  Future<Either<Failures, List<BranchModel>>> getBranches() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      return Right(List<BranchModel>.from(_branches));
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, BranchModel>> getBranchById(String id) async {
    try {
      final index = _branches.indexWhere((b) => b.id == id);
      if (index == -1) {
        return const Left(BranchNotFoundFailure(errMessage: 'branch_not_found'));
      }
      return Right(_branches[index]);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, BranchModel>> createBranch(
    BranchModel branch, {
    required String currentUserId,
  }) async {
    try {
      final newId = branch.id ?? 'branch_${_branches.length + 1}';
      final now = DateTime.now();

      // If set as main branch, demote all others
      if (branch.isMain == true) {
        for (int i = 0; i < _branches.length; i++) {
          if (_branches[i].isMain == true) {
            _branches[i] = _branches[i].copyWith(isMain: false);
          }
        }
      }

      final created = branch.copyWith(
        id: newId,
        isActive: branch.isActive ?? true,
        isMain: branch.isMain ?? false,
        createdAt: now,
        updatedAt: now,
      );

      _branches.add(created);

      auditLogger?.log(
        eventType: 'create_branch',
        performedByUserId: currentUserId,
        branchId: newId,
        details: 'name: ${created.name}, isMain: ${created.isMain}',
      );

      return Right(created);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, BranchModel>> updateBranch(
    BranchModel branch, {
    required String currentUserId,
  }) async {
    try {
      final index = _branches.indexWhere((b) => b.id == branch.id);
      if (index == -1) {
        return const Left(BranchNotFoundFailure(errMessage: 'branch_not_found'));
      }

      // If set as main, demote others
      if (branch.isMain == true) {
        for (int i = 0; i < _branches.length; i++) {
          if (i != index && _branches[i].isMain == true) {
            _branches[i] = _branches[i].copyWith(isMain: false);
          }
        }
      }

      final updated = branch.copyWith(
        updatedAt: DateTime.now(),
      );

      _branches[index] = updated;

      if (getIt.isRegistered<SettingsRepo>()) {
        final settingsRepo = getIt<SettingsRepo>();
        if (settingsRepo is SettingsRepoImpl) {
          settingsRepo.syncFromBranchModel(updated);
        }
      }

      auditLogger?.log(
        eventType: 'update_branch',
        performedByUserId: currentUserId,
        branchId: updated.id,
        details: 'name: ${updated.name}, isMain: ${updated.isMain}',
      );

      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, BranchModel>> toggleBranchStatus({
    required String branchId,
    required bool isActive,
    required String currentUserId,
    bool forceWithActiveBookings = false,
  }) async {
    try {
      final index = _branches.indexWhere((b) => b.id == branchId);
      if (index == -1) {
        return const Left(BranchNotFoundFailure(errMessage: 'branch_not_found'));
      }

      final branch = _branches[index];

      // Deactivation security rules
      if (!isActive) {
        // Rule 1: Cannot deactivate main branch
        if (branch.isMain == true) {
          return const Left(
            CannotDeactivateMainBranchFailure(
              errMessage: 'cannot_deactivate_main_branch',
            ),
          );
        }

        // Rule 2: Cannot deactivate the last active branch
        final activeCount = _branches.where((b) => b.isActive == true).length;
        if (activeCount <= 1) {
          return const Left(
            CannotDeactivateLastActiveBranchFailure(
              errMessage: 'cannot_deactivate_last_branch',
            ),
          );
        }

        // Rule 3: Check future active bookings
        if (activeBookingsProvider != null) {
          final bookingsCount = await activeBookingsProvider!
              .countActiveFutureBookingsForBranch(branchId);
          if (bookingsCount > 0 && !forceWithActiveBookings) {
            return Left(
              ActiveBookingsWarningFailure(
                errMessage: 'branch_has_future_bookings_warning',
                activeBookingsCount: bookingsCount,
              ),
            );
          }
        }
      }

      final updated = branch.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      _branches[index] = updated;

      if (getIt.isRegistered<SettingsRepo>()) {
        final settingsRepo = getIt<SettingsRepo>();
        if (settingsRepo is SettingsRepoImpl) {
          settingsRepo.syncFromBranchModel(updated);
        }
      }

      auditLogger?.log(
        eventType: 'toggle_branch_status',
        performedByUserId: currentUserId,
        branchId: branchId,
        details: 'newStatus: ${isActive ? 'active' : 'inactive'}, forced: $forceWithActiveBookings',
      );

      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, BranchModel>> setMainBranch({
    required String branchId,
    required String currentUserId,
  }) async {
    try {
      final index = _branches.indexWhere((b) => b.id == branchId);
      if (index == -1) {
        return const Left(BranchNotFoundFailure(errMessage: 'branch_not_found'));
      }

      final target = _branches[index];
      if (target.isActive == false) {
        return const Left(
          InvalidBranchOperationFailure(
            errMessage: 'cannot_set_inactive_as_main',
          ),
        );
      }

      for (int i = 0; i < _branches.length; i++) {
        _branches[i] = _branches[i].copyWith(
          isMain: i == index,
          updatedAt: DateTime.now(),
        );
      }

      auditLogger?.log(
        eventType: 'set_main_branch',
        performedByUserId: currentUserId,
        branchId: branchId,
      );

      return Right(_branches[index]);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, BranchModel>> copySettingsFromBranch(
    CopyBranchSettingsParam param, {
    required String currentUserId,
  }) async {
    try {
      final srcId = param.sourceBranchId;
      final targetId = param.targetBranchId;

      if (srcId == null || targetId == null) {
        return const Left(
          InvalidBranchOperationFailure(errMessage: 'missing_branch_ids'),
        );
      }

      if (srcId == targetId) {
        return const Left(
          InvalidBranchOperationFailure(errMessage: 'cannot_copy_to_same_branch'),
        );
      }

      final srcIndex = _branches.indexWhere((b) => b.id == srcId);
      final targetIndex = _branches.indexWhere((b) => b.id == targetId);

      if (srcIndex == -1 || targetIndex == -1) {
        return const Left(BranchNotFoundFailure(errMessage: 'branch_not_found'));
      }

      final source = _branches[srcIndex];
      var target = _branches[targetIndex];

      if (param.copyWorkingHours == true) {
        target = target.copyWith(
          openingTime: source.openingTime,
          closingTime: source.closingTime,
          workingDays: source.workingDays != null
              ? List<String>.from(source.workingDays!)
              : null,
        );
      }

      if (param.copySpecialHolidays == true) {
        target = target.copyWith(
          specialHolidays: source.specialHolidays != null
              ? List<SpecialHolidayModel>.from(source.specialHolidays!)
              : null,
        );
      }

      target = target.copyWith(updatedAt: DateTime.now());
      _branches[targetIndex] = target;

      if (getIt.isRegistered<SettingsRepo>()) {
        final settingsRepo = getIt<SettingsRepo>();
        if (settingsRepo is SettingsRepoImpl) {
          settingsRepo.copyBranchSettings(
            sourceBranchId: srcId,
            targetBranchId: targetId,
            copyWorkingHours: param.copyWorkingHours ?? false,
            copySpecialHolidays: param.copySpecialHolidays ?? false,
          );
        }
      }

      auditLogger?.log(
        eventType: 'copy_branch_settings',
        performedByUserId: currentUserId,
        branchId: targetId,
        details: 'sourceBranchId: $srcId, workingHours: ${param.copyWorkingHours}, holidays: ${param.copySpecialHolidays}',
      );

      return Right(target);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }
}
