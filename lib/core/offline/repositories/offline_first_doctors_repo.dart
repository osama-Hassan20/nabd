import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/params.dart';
import '../../../features/doctors/data/models/doctor_leave_model.dart';
import '../../../features/doctors/data/models/doctor_model.dart';
import '../../../features/doctors/data/models/doctor_schedule_model.dart';
import '../../../features/doctors/data/models/doctors_response_model.dart';
import '../../../features/doctors/domain/repo/doctors_repo.dart';
import '../data_mode_service.dart';
import '../models/local_entity_record.dart';
import '../models/outbox_entry.dart';
import '../models/sync_status.dart';
import '../store/transactional_local_store.dart';

class OfflineFirstDoctorsRepo implements DoctorsRepo {
  final TransactionalLocalStore localStore;
  final DataModeService dataModeService;
  final DoctorsRepo remoteRepo;
  final String Function() getCurrentAccountId;
  final String Function() getCurrentBranchId;

  OfflineFirstDoctorsRepo({
    required this.localStore,
    required this.dataModeService,
    required this.remoteRepo,
    required this.getCurrentAccountId,
    required this.getCurrentBranchId,
  });

  @override
  Future<Either<Failures, DoctorsResponseModel>> getDoctors({
    required PaginationParams params,
  }) async {
    final records = await localStore.getEntities(
      entityType: 'doctor',
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    final localDoctors = <String, DoctorModel>{};
    final tombstoneIds = <String>{};

    for (final rec in records) {
      if (rec.isTombstone) {
        tombstoneIds.add(rec.localId);
      } else {
        try {
          final doc = DoctorModel.fromJson(rec.payload);
          if (doc.id != null) localDoctors[doc.id!] = doc;
        } catch (_) {}
      }
    }

    final remoteRes = await remoteRepo.getDoctors(params: params);
    remoteRes.fold((_) {}, (response) {
      for (final doc in response.doctors) {
        if (doc.id != null && !tombstoneIds.contains(doc.id)) {
          // Check if localDoctors already has this doctor by id or by name/phone to prevent duplicate
          final alreadyPresent = localDoctors.containsKey(doc.id) ||
              localDoctors.values.any((d) =>
                  ((d.name?.trim().isNotEmpty ?? false) && d.name?.trim().toLowerCase() == doc.name?.trim().toLowerCase()) &&
                  ((d.phone?.trim().isNotEmpty ?? false) && d.phone?.trim() == doc.phone?.trim()));
          if (!alreadyPresent) {
            localDoctors[doc.id!] = doc;
          }
        }
      }
    });

    final list = localDoctors.values.toList();
    return Right(
      DoctorsResponseModel(
        items: list,
        totalCount: list.length,
        totalPages: 1,
        currentPage: 1,
      ),
    );
  }

  @override
  Future<Either<Failures, DoctorModel>> getDoctorById({required String id}) async {
    final localRec = await localStore.getEntity(
      localId: id,
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    if (localRec != null && !localRec.isTombstone) {
      try {
        return Right(DoctorModel.fromJson(localRec.payload));
      } catch (_) {}
    }

    return remoteRepo.getDoctorById(id: id);
  }

  @override
  Future<Either<Failures, DoctorModel>> addDoctor({required DoctorModel doctor}) async {
    final now = DateTime.now();
    final docId = doctor.id ?? 'DOC-${now.millisecondsSinceEpoch}';
    final toSave = doctor.copyWith(id: docId);

    await _persistDoctorAtomic(toSave, OutboxOperationType.create);

    try {
      await remoteRepo.addDoctor(doctor: toSave);
    } catch (_) {}

    return Right(toSave);
  }

  @override
  Future<Either<Failures, DoctorModel>> updateDoctor({required DoctorModel doctor}) async {
    await _persistDoctorAtomic(doctor, OutboxOperationType.update);

    try {
      await remoteRepo.updateDoctor(doctor: doctor);
    } catch (_) {}

    return Right(doctor);
  }

  @override
  Future<Either<Failures, bool>> deleteDoctor({required String id}) async {
    final now = DateTime.now();

    await localStore.runInTransaction((txn) async {
      txn.markTombstone(id);

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_doc_del_${id}_${now.microsecondsSinceEpoch}',
          entityType: 'doctor',
          localId: id,
          operation: OutboxOperationType.delete,
          payload: {'id': id},
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.deleteDoctor(id: id);
    } catch (_) {}

    return const Right(true);
  }

  @override
  Future<Either<Failures, DoctorScheduleModel?>> getDoctorSchedule({
    required String doctorId,
  }) =>
      remoteRepo.getDoctorSchedule(doctorId: doctorId);

  @override
  Future<Either<Failures, DoctorScheduleModel>> saveDoctorSchedule({
    required DoctorScheduleModel schedule,
  }) =>
      remoteRepo.saveDoctorSchedule(schedule: schedule);

  @override
  Future<Either<Failures, List<DoctorLeaveModel>>> getDoctorLeaves({
    required String doctorId,
  }) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();

    final records = await localStore.getEntities(
      entityType: 'doctor_leave',
      accountId: accountId,
      branchId: branchId,
    );

    final localLeaves = <String, DoctorLeaveModel>{};
    for (final rec in records) {
      if (!rec.isTombstone) {
        try {
          final leave = DoctorLeaveModel.fromJson(rec.payload);
          if (leave.id != null && (leave.doctorId == doctorId || leave.technicianId == doctorId)) {
            localLeaves[leave.id!] = leave;
          }
        } catch (_) {}
      }
    }

    final remoteRes = await remoteRepo.getDoctorLeaves(doctorId: doctorId);
    remoteRes.fold((_) {}, (items) {
      for (final l in items) {
        final existing = records.where((r) => r.localId == l.id).firstOrNull;
        if (existing != null && existing.isTombstone) {
          continue;
        }
        if (l.id != null && !localLeaves.containsKey(l.id!)) {
          localLeaves[l.id!] = l;
        }
      }
    });

    final sorted = localLeaves.values.toList();
    sorted.sort((a, b) => (b.startDate ?? DateTime.now()).compareTo(a.startDate ?? DateTime.now()));
    return Right(sorted);
  }

  @override
  Future<Either<Failures, DoctorLeaveModel>> addDoctorLeave({
    required DoctorLeaveModel leave,
    bool force = false,
  }) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();
    final isProvisional = !dataModeService.isOnline;
    final leaveId = leave.id ?? 'LV-${now.millisecondsSinceEpoch}';
    final toSave = leave.id == null ? DoctorLeaveModel.fromJson({...leave.toJson(), 'id': leaveId}) : leave;

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: leaveId,
          entityType: 'doctor_leave',
          accountId: accountId,
          branchId: branchId,
          payload: toSave.toJson(),
          localRevision: 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: toSave.createdAt ?? now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_doc_lv_${leaveId}_${now.microsecondsSinceEpoch}',
          entityType: 'doctor_leave',
          localId: leaveId,
          operation: OutboxOperationType.create,
          payload: toSave.toJson(),
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.addDoctorLeave(leave: toSave, force: force);
    } catch (_) {}

    return Right(toSave);
  }

  @override
  Future<Either<Failures, bool>> deleteDoctorLeave({
    required String leaveId,
  }) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();

    final existing = await localStore.getEntity(
      localId: leaveId,
      accountId: accountId,
      branchId: branchId,
    );

    await localStore.runInTransaction((txn) async {
      txn.markTombstone(leaveId);

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_doc_lv_del_${leaveId}_${now.microsecondsSinceEpoch}',
          entityType: 'doctor_leave',
          localId: leaveId,
          operation: OutboxOperationType.delete,
          payload: {'id': leaveId},
          previousPayload: existing?.payload,
          baseRevision: existing?.localRevision ?? 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.deleteDoctorLeave(leaveId: leaveId);
    } catch (_) {}

    return const Right(true);
  }

  @override
  Future<Either<Failures, int>> countConflictingBookings({
    required String doctorId,
    required DateTime startDate,
    required DateTime endDate,
  }) =>
      remoteRepo.countConflictingBookings(
        doctorId: doctorId,
        startDate: startDate,
        endDate: endDate,
      );

  Future<void> _persistDoctorAtomic(DoctorModel doctor, OutboxOperationType operation) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();
    final isProvisional = !dataModeService.isOnline;
    final docId = doctor.id ?? 'DOC-${now.millisecondsSinceEpoch}';

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: docId,
          entityType: 'doctor',
          accountId: accountId,
          branchId: branchId,
          payload: doctor.toJson(),
          localRevision: 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_doc_${docId}_${now.microsecondsSinceEpoch}',
          entityType: 'doctor',
          localId: docId,
          operation: operation,
          payload: doctor.toJson(),
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });
  }
}
