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
        if (doc.id != null && !tombstoneIds.contains(doc.id) && !localDoctors.containsKey(doc.id)) {
          localDoctors[doc.id!] = doc;
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
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
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
  }) =>
      remoteRepo.getDoctorLeaves(doctorId: doctorId);

  @override
  Future<Either<Failures, DoctorLeaveModel>> addDoctorLeave({
    required DoctorLeaveModel leave,
    bool force = false,
  }) =>
      remoteRepo.addDoctorLeave(leave: leave, force: force);

  @override
  Future<Either<Failures, bool>> deleteDoctorLeave({
    required String leaveId,
  }) =>
      remoteRepo.deleteDoctorLeave(leaveId: leaveId);

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
