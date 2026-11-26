import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../features/settings/data/models/company_settings_model.dart';
import '../../../features/settings/data/models/special_holiday_model.dart';
import '../../../features/settings/domain/repo/settings_repo.dart';
import '../data_mode_service.dart';
import '../models/local_entity_record.dart';
import '../models/outbox_entry.dart';
import '../models/sync_status.dart';
import '../store/transactional_local_store.dart';

class OfflineFirstSettingsRepo implements SettingsRepo {
  final TransactionalLocalStore localStore;
  final DataModeService dataModeService;
  final SettingsRepo remoteRepo;
  final String Function() getCurrentAccountId;
  final String Function() getCurrentBranchId;

  OfflineFirstSettingsRepo({
    required this.localStore,
    required this.dataModeService,
    required this.remoteRepo,
    required this.getCurrentAccountId,
    required this.getCurrentBranchId,
  });

  @override
  Future<Either<Failures, CompanySettingsModel>> getCompanySettings() async {
    final branchId = getCurrentBranchId();
    final localRec = await localStore.getEntity(
      localId: 'settings_$branchId',
      accountId: getCurrentAccountId(),
      branchId: branchId,
    );

    if (localRec != null && !localRec.isTombstone) {
      try {
        return Right(CompanySettingsModel.fromJson(localRec.payload));
      } catch (_) {}
    }

    return remoteRepo.getCompanySettings();
  }

  @override
  Future<Either<Failures, CompanySettingsModel>> updateCompanySettings(
    CompanySettingsModel settings,
  ) async {
    final branchId = getCurrentBranchId();
    final accountId = getCurrentAccountId();
    final now = DateTime.now();
    final isProvisional = !dataModeService.isOnline;

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: 'settings_$branchId',
          entityType: 'settings',
          accountId: accountId,
          branchId: branchId,
          payload: settings.toJson(),
          localRevision: 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_settings_${branchId}_${now.microsecondsSinceEpoch}',
          entityType: 'settings',
          localId: 'settings_$branchId',
          operation: OutboxOperationType.update,
          payload: settings.toJson(),
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.updateCompanySettings(settings);
    } catch (_) {}

    return Right(settings);
  }

  @override
  Future<Either<Failures, SpecialHolidayModel>> addSpecialHoliday(
    SpecialHolidayModel holiday,
  ) async {
    final branchId = getCurrentBranchId();
    final accountId = getCurrentAccountId();
    final now = DateTime.now();
    final isProvisional = !dataModeService.isOnline;

    final holId = holiday.id ?? 'HOL-${now.millisecondsSinceEpoch}';

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: holId,
          entityType: 'holiday',
          accountId: accountId,
          branchId: branchId,
          payload: holiday.toJson(),
          localRevision: 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_holiday_${holId}_${now.microsecondsSinceEpoch}',
          entityType: 'holiday',
          localId: holId,
          operation: OutboxOperationType.create,
          payload: holiday.toJson(),
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.addSpecialHoliday(holiday);
    } catch (_) {}

    return Right(holiday);
  }

  @override
  Future<Either<Failures, Unit>> deleteSpecialHoliday(String holidayId) async {
    final branchId = getCurrentBranchId();
    final accountId = getCurrentAccountId();
    final now = DateTime.now();

    await localStore.runInTransaction((txn) async {
      txn.markTombstone(holidayId);

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_holiday_del_${holidayId}_${now.microsecondsSinceEpoch}',
          entityType: 'holiday',
          localId: holidayId,
          operation: OutboxOperationType.delete,
          payload: {'id': holidayId},
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.deleteSpecialHoliday(holidayId);
    } catch (_) {}

    return const Right(unit);
  }

  @override
  Future<Either<Failures, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      remoteRepo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
}
