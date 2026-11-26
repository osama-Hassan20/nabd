import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../features/users_management/data/models/role_definition_model.dart';
import '../../../features/users_management/data/models/staff_user_model.dart';
import '../../../features/users_management/data/repositories/staff_users_repo.dart';
import '../data_mode_service.dart';
import '../models/local_entity_record.dart';
import '../models/outbox_entry.dart';
import '../models/sync_status.dart';
import '../store/transactional_local_store.dart';

class OfflineFirstStaffUsersRepo implements StaffUsersRepo {
  final TransactionalLocalStore localStore;
  final DataModeService dataModeService;
  final StaffUsersRepo remoteRepo;
  final String Function() getCurrentAccountId;
  final String Function() getCurrentBranchId;

  OfflineFirstStaffUsersRepo({
    required this.localStore,
    required this.dataModeService,
    required this.remoteRepo,
    required this.getCurrentAccountId,
    required this.getCurrentBranchId,
  });

  @override
  Future<Either<Failure, StaffUserModel>> authenticate({
    required String identifier,
    required String password,
  }) =>
      remoteRepo.authenticate(identifier: identifier, password: password);

  @override
  Future<Either<Failure, List<StaffUserModel>>> getStaffUsers({
    String? branchId,
    String? roleId,
    bool? isActive,
    String? searchQuery,
  }) async {
    final bId = branchId ?? getCurrentBranchId();
    final records = await localStore.getEntities(
      entityType: 'staff_user',
      accountId: getCurrentAccountId(),
      branchId: bId,
    );

    final localUsers = <String, StaffUserModel>{};
    final tombstoneIds = <String>{};

    for (final rec in records) {
      if (rec.isTombstone) {
        tombstoneIds.add(rec.localId);
      } else {
        try {
          final u = StaffUserModel.fromJson(rec.payload);
          if (u.id != null) localUsers[u.id!] = u;
        } catch (_) {}
      }
    }

    final remoteRes = await remoteRepo.getStaffUsers(
      branchId: bId,
      roleId: roleId,
      isActive: isActive,
      searchQuery: searchQuery,
    );

    remoteRes.fold((_) {}, (users) {
      for (final u in users) {
        if (u.id != null && !tombstoneIds.contains(u.id!) && !localUsers.containsKey(u.id!)) {
          localUsers[u.id!] = u;
        }
      }
    });

    var results = localUsers.values.toList();
    if (roleId != null) {
      results = results.where((u) => u.branchAssignments?.any((b) => b.roleIds?.contains(roleId) ?? false) ?? false).toList();
    }
    if (isActive != null) {
      results = results.where((u) => u.isActive == isActive).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      results = results.where((u) =>
          (u.fullName ?? '').toLowerCase().contains(q) ||
          (u.email ?? '').toLowerCase().contains(q) ||
          (u.phone ?? '').contains(q)).toList();
    }

    return Right(results);
  }

  @override
  Future<Either<Failure, StaffUserModel>> getStaffUserById(String id) async {
    final localRec = await localStore.getEntity(
      localId: id,
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    if (localRec != null && !localRec.isTombstone) {
      try {
        return Right(StaffUserModel.fromJson(localRec.payload));
      } catch (_) {}
    }

    return remoteRepo.getStaffUserById(id);
  }

  @override
  Future<Either<Failure, StaffUserModel>> createStaffUser({
    required StaffUserModel user,
    required String temporaryPassword,
    required String currentUserId,
  }) async {
    final res = await remoteRepo.createStaffUser(
      user: user,
      temporaryPassword: temporaryPassword,
      currentUserId: currentUserId,
    );

    return res.fold((failure) => Left(failure), (created) async {
      await _persistUserAtomic(created, OutboxOperationType.create);
      return Right(created);
    });
  }

  @override
  Future<Either<Failure, StaffUserModel>> updateStaffUser({
    required StaffUserModel user,
    required String currentUserId,
  }) async {
    final res = await remoteRepo.updateStaffUser(
      user: user,
      currentUserId: currentUserId,
    );

    return res.fold((failure) => Left(failure), (updated) async {
      await _persistUserAtomic(updated, OutboxOperationType.update);
      return Right(updated);
    });
  }

  @override
  Future<Either<Failure, Unit>> toggleStaffUserStatus({
    required String userId,
    required bool isActive,
    required String currentUserId,
  }) async {
    final res = await remoteRepo.toggleStaffUserStatus(
      userId: userId,
      isActive: isActive,
      currentUserId: currentUserId,
    );

    return res.fold((failure) => Left(failure), (_) async {
      final userRes = await getStaffUserById(userId);
      userRes.fold((_) {}, (u) async {
        await _persistUserAtomic(u.copyWith(isActive: isActive), OutboxOperationType.update);
      });
      return const Right(unit);
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteStaffUser({
    required String userId,
    required String currentUserId,
    bool forceWithActiveBookings = false,
  }) async {
    final res = await remoteRepo.deleteStaffUser(
      userId: userId,
      currentUserId: currentUserId,
      forceWithActiveBookings: forceWithActiveBookings,
    );

    return res.fold((failure) => Left(failure), (_) async {
      final accountId = getCurrentAccountId();
      final branchId = getCurrentBranchId();
      final now = DateTime.now();

      await localStore.runInTransaction((txn) async {
        txn.markTombstone(userId);
        txn.insertOutbox(
          OutboxEntry(
            operationId: 'op_user_del_${userId}_${now.microsecondsSinceEpoch}',
            entityType: 'staff_user',
            localId: userId,
            operation: OutboxOperationType.delete,
            payload: {'id': userId},
            baseRevision: 1,
            createdAt: now,
            status: OutboxStatus.pending,
          ),
        );
      });

      return const Right(unit);
    });
  }

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String userId,
    required String newTemporaryPassword,
    required String currentUserId,
  }) =>
      remoteRepo.resetPassword(
        userId: userId,
        newTemporaryPassword: newTemporaryPassword,
        currentUserId: currentUserId,
      );

  @override
  Future<Either<Failure, Unit>> changePasswordOnFirstLogin({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) =>
      remoteRepo.changePasswordOnFirstLogin(
        userId: userId,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  @override
  Future<Either<Failure, List<RoleDefinitionModel>>> getRoles() =>
      remoteRepo.getRoles();

  @override
  Future<Either<Failure, RoleDefinitionModel>> saveRole({
    required RoleDefinitionModel role,
    required String currentUserId,
  }) =>
      remoteRepo.saveRole(role: role, currentUserId: currentUserId);

  Future<void> _persistUserAtomic(StaffUserModel user, OutboxOperationType operation) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();
    final isProvisional = !dataModeService.isOnline;

    final uId = user.id ?? 'USER-${now.millisecondsSinceEpoch}';

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: uId,
          entityType: 'staff_user',
          accountId: accountId,
          branchId: branchId,
          payload: user.toJson(),
          localRevision: 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: user.createdAt ?? now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_user_${uId}_${now.microsecondsSinceEpoch}',
          entityType: 'staff_user',
          localId: uId,
          operation: operation,
          payload: user.toJson(),
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });
  }
}
