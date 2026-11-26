import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../features/cashier/data/models/cash_movement_model.dart';
import '../../../features/cashier/data/models/cashier_shift_model.dart';
import '../../../features/cashier/data/models/cashier_summary_metrics_model.dart';
import '../../../features/cashier/data/models/payment_transaction_model.dart';
import '../../../features/cashier/data/models/refund_transaction_model.dart';
import '../../../features/cashier/domain/repo/cashier_repo.dart';
import '../data_mode_service.dart';
import '../models/local_entity_record.dart';
import '../models/outbox_entry.dart';
import '../models/sync_status.dart';
import '../policies/entity_mutation_policy.dart';
import '../store/transactional_local_store.dart';

class OfflineFirstCashierRepo implements CashierRepo {
  final TransactionalLocalStore localStore;
  final DataModeService dataModeService;
  final CashierRepo remoteRepo;
  final String Function() getCurrentAccountId;
  final String Function() getCurrentBranchId;
  final EntityMutationPolicy mutationPolicy;

  OfflineFirstCashierRepo({
    required this.localStore,
    required this.dataModeService,
    required this.remoteRepo,
    required this.getCurrentAccountId,
    required this.getCurrentBranchId,
    this.mutationPolicy = const FinancialEntryPolicy(),
  });

  @override
  Future<Either<Failures, CashierShiftModel?>> getCurrentShift({
    required String branchId,
    required String cashierUserId,
  }) async {
    final records = await localStore.getEntities(
      entityType: 'cashier_shift',
      accountId: getCurrentAccountId(),
      branchId: branchId,
    );

    for (final rec in records) {
      if (!rec.isTombstone) {
        try {
          final shift = CashierShiftModel.fromJson(rec.payload);
          if (shift.cashierUserId == cashierUserId && shift.isOpen) {
            return Right(shift);
          }
        } catch (_) {}
      }
    }

    return remoteRepo.getCurrentShift(
      branchId: branchId,
      cashierUserId: cashierUserId,
    );
  }

  @override
  Future<Either<Failures, List<CashierShiftModel>>> getShiftHistory({
    required String branchId,
    String? cashierUserId,
  }) async {
    final records = await localStore.getEntities(
      entityType: 'cashier_shift',
      accountId: getCurrentAccountId(),
      branchId: branchId,
    );

    final localShifts = <String, CashierShiftModel>{};
    for (final rec in records) {
      if (!rec.isTombstone) {
        try {
          final shift = CashierShiftModel.fromJson(rec.payload);
          if (shift.id != null && (cashierUserId == null || shift.cashierUserId == cashierUserId)) {
            localShifts[shift.id!] = shift;
          }
        } catch (_) {}
      }
    }

    final remoteRes = await remoteRepo.getShiftHistory(
      branchId: branchId,
      cashierUserId: cashierUserId,
    );

    remoteRes.fold((_) {}, (shifts) {
      for (final s in shifts) {
        if (s.id != null && !localShifts.containsKey(s.id!)) {
          localShifts[s.id!] = s;
        }
      }
    });

    final sorted = localShifts.values.toList()
      ..sort((a, b) => (b.openedAt ?? DateTime(2000)).compareTo(a.openedAt ?? DateTime(2000)));

    return Right(sorted);
  }

  @override
  Future<Either<Failures, CashierShiftModel>> openShift({
    required String branchId,
    required String cashierUserId,
    required String cashierName,
    required int openingBalancePiastres,
    String? suggestedOpeningBalanceDiffReason,
  }) async {
    final res = await remoteRepo.openShift(
      branchId: branchId,
      cashierUserId: cashierUserId,
      cashierName: cashierName,
      openingBalancePiastres: openingBalancePiastres,
      suggestedOpeningBalanceDiffReason: suggestedOpeningBalanceDiffReason,
    );

    return res.fold((failure) => Left(failure), (shift) async {
      await _persistShiftAtomic(shift: shift, isNew: true);
      return Right(shift);
    });
  }

  @override
  Future<Either<Failures, CashierShiftModel>> closeShift({
    required String shiftId,
    required int actualCashCountPiastres,
    String? closingNotes,
    String? shortageReason,
  }) async {
    final res = await remoteRepo.closeShift(
      shiftId: shiftId,
      actualCashCountPiastres: actualCashCountPiastres,
      closingNotes: closingNotes,
      shortageReason: shortageReason,
    );

    return res.fold((failure) => Left(failure), (shift) async {
      await _persistShiftAtomic(shift: shift, isNew: false);
      return Right(shift);
    });
  }

  @override
  Future<Either<Failures, CashierShiftModel>> forceCloseShift({
    required String shiftId,
    required String performedByUserId,
    required String reason,
  }) async {
    final res = await remoteRepo.forceCloseShift(
      shiftId: shiftId,
      performedByUserId: performedByUserId,
      reason: reason,
    );

    return res.fold((failure) => Left(failure), (shift) async {
      await _persistShiftAtomic(shift: shift, isNew: false);
      return Right(shift);
    });
  }

  @override
  Future<Either<Failures, CashierShiftModel>> approveShortage({
    required String shiftId,
    required String approvedByUserId,
    required String reason,
    bool isOwnerSelfApproved = false,
  }) async {
    final res = await remoteRepo.approveShortage(
      shiftId: shiftId,
      approvedByUserId: approvedByUserId,
      reason: reason,
      isOwnerSelfApproved: isOwnerSelfApproved,
    );

    return res.fold((failure) => Left(failure), (shift) async {
      await _persistShiftAtomic(shift: shift, isNew: false);
      return Right(shift);
    });
  }

  @override
  Future<Either<Failures, PaymentTransactionModel>> recordPayment({
    required String clientRequestId,
    required String shiftId,
    required String branchId,
    required String bookingId,
    required String patientId,
    required String patientName,
    required int amountPiastres,
    required String paymentMethod,
    String? referenceNumber,
    required String cashierUserId,
    required String cashierName,
    String? notes,
  }) async {
    final accountId = getCurrentAccountId();

    // 1. Check idempotency record in localStore
    final existingIdemp = await localStore.getEntity(
      localId: 'idemp_pay_$clientRequestId',
      accountId: accountId,
      branchId: branchId,
    );

    if (existingIdemp != null && !existingIdemp.isTombstone) {
      try {
        final paymentId = existingIdemp.payload['paymentId'] as String;
        final paymentRec = await localStore.getEntity(
          localId: paymentId,
          accountId: accountId,
          branchId: branchId,
        );
        if (paymentRec != null && !paymentRec.isTombstone) {
          return Right(PaymentTransactionModel.fromJson(paymentRec.payload));
        }
      } catch (_) {}
    }

    // 2. Delegate to remote mock for calculation and business validation
    final remoteRes = await remoteRepo.recordPayment(
      clientRequestId: clientRequestId,
      shiftId: shiftId,
      branchId: branchId,
      bookingId: bookingId,
      patientId: patientId,
      patientName: patientName,
      amountPiastres: amountPiastres,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      cashierUserId: cashierUserId,
      cashierName: cashierName,
      notes: notes,
    );

    return remoteRes.fold((failure) => Left(failure), (payment) async {
      final now = DateTime.now();
      final isProvisional = !dataModeService.isOnline;
      final payId = payment.id ?? 'PAY-${now.millisecondsSinceEpoch}';

      // 3. Retrieve updated shift from remote
      final shiftRes = await remoteRepo.getCurrentShift(
        branchId: branchId,
        cashierUserId: cashierUserId,
      );
      final updatedShift = shiftRes.fold((_) => null, (s) => s);

      // 4. Atomic write: payment + updated shift + idempotency record + outbox entry
      await localStore.runInTransaction((txn) async {
        txn.upsertEntity(
          LocalEntityRecord(
            localId: payId,
            entityType: 'cashier_payment',
            accountId: accountId,
            branchId: branchId,
            payload: payment.toJson(),
            localRevision: 1,
            syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
            isProvisional: isProvisional,
            createdAt: payment.createdAt ?? now,
            updatedAt: now,
          ),
        );

        if (updatedShift != null && updatedShift.id != null) {
          txn.upsertEntity(
            LocalEntityRecord(
              localId: updatedShift.id!,
              entityType: 'cashier_shift',
              accountId: accountId,
              branchId: updatedShift.branchId ?? branchId,
              payload: updatedShift.toJson(),
              localRevision: 1,
              syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
              isProvisional: isProvisional,
              createdAt: updatedShift.openedAt ?? now,
              updatedAt: now,
            ),
          );
        }

        txn.upsertEntity(
          LocalEntityRecord(
            localId: 'idemp_pay_$clientRequestId',
            entityType: 'cashier_idempotency',
            accountId: accountId,
            branchId: branchId,
            payload: {'paymentId': payId, 'clientRequestId': clientRequestId},
            localRevision: 1,
            syncStatus: SyncStatus.synced,
            isProvisional: false,
            createdAt: now,
            updatedAt: now,
          ),
        );

        txn.insertOutbox(
          OutboxEntry(
            operationId: 'op_pay_${payId}_${now.microsecondsSinceEpoch}',
            entityType: 'cashier_payment',
            localId: payId,
            operation: OutboxOperationType.create,
            payload: payment.toJson(),
            baseRevision: 1,
            createdAt: now,
            status: OutboxStatus.pending,
            dependencyRefs: ['shift:$shiftId', 'booking:$bookingId', 'patient:$patientId'],
          ),
        );
      });

      return Right(payment);
    });
  }

  @override
  Future<Either<Failures, RefundTransactionModel>> refundPayment({
    required String clientRequestId,
    required String originalPaymentId,
    required String shiftId,
    required String branchId,
    required String bookingId,
    required String patientId,
    required int refundAmountPiastres,
    required String refundMethod,
    required String reason,
    required String authorizedByUserId,
    required String authorizedByName,
  }) async {
    final accountId = getCurrentAccountId();

    // 1. Check idempotency record
    final existingIdemp = await localStore.getEntity(
      localId: 'idemp_ref_$clientRequestId',
      accountId: accountId,
      branchId: branchId,
    );

    if (existingIdemp != null && !existingIdemp.isTombstone) {
      try {
        final refundId = existingIdemp.payload['refundId'] as String;
        final refundRec = await localStore.getEntity(
          localId: refundId,
          accountId: accountId,
          branchId: branchId,
        );
        if (refundRec != null && !refundRec.isTombstone) {
          return Right(RefundTransactionModel.fromJson(refundRec.payload));
        }
      } catch (_) {}
    }

    final res = await remoteRepo.refundPayment(
      clientRequestId: clientRequestId,
      originalPaymentId: originalPaymentId,
      shiftId: shiftId,
      branchId: branchId,
      bookingId: bookingId,
      patientId: patientId,
      refundAmountPiastres: refundAmountPiastres,
      refundMethod: refundMethod,
      reason: reason,
      authorizedByUserId: authorizedByUserId,
      authorizedByName: authorizedByName,
    );

    return res.fold((failure) => Left(failure), (refund) async {
      final now = DateTime.now();
      final isProvisional = !dataModeService.isOnline;
      final refId = refund.id ?? 'REF-${now.millisecondsSinceEpoch}';

      await localStore.runInTransaction((txn) async {
        txn.upsertEntity(
          LocalEntityRecord(
            localId: refId,
            entityType: 'cashier_refund',
            accountId: accountId,
            branchId: branchId,
            payload: refund.toJson(),
            localRevision: 1,
            syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
            isProvisional: isProvisional,
            createdAt: refund.createdAt ?? now,
            updatedAt: now,
          ),
        );

        txn.upsertEntity(
          LocalEntityRecord(
            localId: 'idemp_ref_$clientRequestId',
            entityType: 'cashier_idempotency',
            accountId: accountId,
            branchId: branchId,
            payload: {'refundId': refId, 'clientRequestId': clientRequestId},
            localRevision: 1,
            syncStatus: SyncStatus.synced,
            isProvisional: false,
            createdAt: now,
            updatedAt: now,
          ),
        );

        txn.insertOutbox(
          OutboxEntry(
            operationId: 'op_ref_${refId}_${now.microsecondsSinceEpoch}',
            entityType: 'cashier_refund',
            localId: refId,
            operation: OutboxOperationType.reverseFinancial,
            payload: refund.toJson(),
            baseRevision: 1,
            createdAt: now,
            status: OutboxStatus.pending,
            dependencyRefs: ['payment:$originalPaymentId', 'shift:$shiftId'],
          ),
        );
      });

      return Right(refund);
    });
  }

  @override
  Future<Either<Failures, CashMovementModel>> recordCashMovement({
    required String clientRequestId,
    required String shiftId,
    required String branchId,
    required String movementType,
    required int amountPiastres,
    required String reason,
    String? recipientName,
    required String performedByUserId,
  }) async {
    final accountId = getCurrentAccountId();

    // Idempotency check
    final existingIdemp = await localStore.getEntity(
      localId: 'idemp_mov_$clientRequestId',
      accountId: accountId,
      branchId: branchId,
    );

    if (existingIdemp != null && !existingIdemp.isTombstone) {
      try {
        final movementId = existingIdemp.payload['movementId'] as String;
        final movRec = await localStore.getEntity(
          localId: movementId,
          accountId: accountId,
          branchId: branchId,
        );
        if (movRec != null && !movRec.isTombstone) {
          return Right(CashMovementModel.fromJson(movRec.payload));
        }
      } catch (_) {}
    }

    final res = await remoteRepo.recordCashMovement(
      clientRequestId: clientRequestId,
      shiftId: shiftId,
      branchId: branchId,
      movementType: movementType,
      amountPiastres: amountPiastres,
      reason: reason,
      recipientName: recipientName,
      performedByUserId: performedByUserId,
    );

    return res.fold((failure) => Left(failure), (movement) async {
      final now = DateTime.now();
      final isProvisional = !dataModeService.isOnline;
      final movId = movement.id ?? 'MOV-${now.millisecondsSinceEpoch}';

      await localStore.runInTransaction((txn) async {
        txn.upsertEntity(
          LocalEntityRecord(
            localId: movId,
            entityType: 'cashier_movement',
            accountId: accountId,
            branchId: branchId,
            payload: movement.toJson(),
            localRevision: 1,
            syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
            isProvisional: isProvisional,
            createdAt: movement.createdAt ?? now,
            updatedAt: now,
          ),
        );

        txn.upsertEntity(
          LocalEntityRecord(
            localId: 'idemp_mov_$clientRequestId',
            entityType: 'cashier_idempotency',
            accountId: accountId,
            branchId: branchId,
            payload: {'movementId': movId, 'clientRequestId': clientRequestId},
            localRevision: 1,
            syncStatus: SyncStatus.synced,
            isProvisional: false,
            createdAt: now,
            updatedAt: now,
          ),
        );

        txn.insertOutbox(
          OutboxEntry(
            operationId: 'op_mov_${movId}_${now.microsecondsSinceEpoch}',
            entityType: 'cashier_movement',
            localId: movId,
            operation: OutboxOperationType.create,
            payload: movement.toJson(),
            baseRevision: 1,
            createdAt: now,
            status: OutboxStatus.pending,
            dependencyRefs: ['shift:$shiftId'],
          ),
        );
      });

      return Right(movement);
    });
  }

  @override
  Future<Either<Failures, CashierSummaryMetricsModel>> getShiftMetrics({
    required String shiftId,
  }) =>
      remoteRepo.getShiftMetrics(shiftId: shiftId);

  @override
  Future<Either<Failures, List<PaymentTransactionModel>>> getPaymentsForShift({
    required String shiftId,
    bool includeVoided = false,
  }) async {
    final records = await localStore.getEntities(
      entityType: 'cashier_payment',
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    final localPayments = <String, PaymentTransactionModel>{};
    for (final rec in records) {
      if (!rec.isTombstone) {
        try {
          final payment = PaymentTransactionModel.fromJson(rec.payload);
          final pId = payment.id ?? rec.localId;
          final isVoided = payment.isVoidedBySystem ?? false;
          if (payment.shiftId == shiftId && (includeVoided || !isVoided)) {
            localPayments[pId] = payment;
          }
        } catch (_) {}
      }
    }

    final remoteRes = await remoteRepo.getPaymentsForShift(
      shiftId: shiftId,
      includeVoided: includeVoided,
    );

    remoteRes.fold((_) {}, (payments) {
      for (final p in payments) {
        final pId = p.id;
        if (pId != null && !localPayments.containsKey(pId)) {
          localPayments[pId] = p;
        }
      }
    });

    return Right(localPayments.values.toList());
  }

  @override
  Future<Either<Failures, List<PaymentTransactionModel>>> getPaymentsByBookingId({
    required String bookingId,
  }) async {
    final records = await localStore.getEntities(
      entityType: 'cashier_payment',
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    final localPayments = <String, PaymentTransactionModel>{};
    for (final rec in records) {
      if (!rec.isTombstone) {
        try {
          final payment = PaymentTransactionModel.fromJson(rec.payload);
          final pId = payment.id ?? rec.localId;
          if (payment.bookingId == bookingId) {
            localPayments[pId] = payment;
          }
        } catch (_) {}
      }
    }

    final remoteRes = await remoteRepo.getPaymentsByBookingId(bookingId: bookingId);
    remoteRes.fold((_) {}, (payments) {
      for (final p in payments) {
        final pId = p.id;
        if (pId != null && !localPayments.containsKey(pId)) {
          localPayments[pId] = p;
        }
      }
    });

    return Right(localPayments.values.toList());
  }

  @override
  Future<Either<Failures, List<PaymentTransactionModel>>> getPaymentsByPatientId({
    required String patientId,
  }) async {
    final records = await localStore.getEntities(
      entityType: 'cashier_payment',
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    final localPayments = <String, PaymentTransactionModel>{};
    for (final rec in records) {
      if (!rec.isTombstone) {
        try {
          final payment = PaymentTransactionModel.fromJson(rec.payload);
          final pId = payment.id ?? rec.localId;
          if (payment.patientId == patientId) {
            localPayments[pId] = payment;
          }
        } catch (_) {}
      }
    }

    final remoteRes = await remoteRepo.getPaymentsByPatientId(patientId: patientId);
    remoteRes.fold((_) {}, (payments) {
      for (final p in payments) {
        final pId = p.id;
        if (pId != null && !localPayments.containsKey(pId)) {
          localPayments[pId] = p;
        }
      }
    });

    return Right(localPayments.values.toList());
  }

  @override
  Future<Either<Failures, void>> voidPaymentRollback({
    required String paymentId,
    required String reason,
  }) =>
      remoteRepo.voidPaymentRollback(paymentId: paymentId, reason: reason);

  Future<void> _persistShiftAtomic({
    required CashierShiftModel shift,
    required bool isNew,
  }) async {
    final accountId = getCurrentAccountId();
    final branchId = shift.branchId ?? getCurrentBranchId();
    final now = DateTime.now();
    final isProvisional = !dataModeService.isOnline;
    final shiftId = shift.id ?? 'SHIFT-${now.millisecondsSinceEpoch}';

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: shiftId,
          entityType: 'cashier_shift',
          accountId: accountId,
          branchId: branchId,
          payload: shift.toJson(),
          localRevision: 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: shift.openedAt ?? now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_shift_${shiftId}_${now.microsecondsSinceEpoch}',
          entityType: 'cashier_shift',
          localId: shiftId,
          operation: isNew ? OutboxOperationType.create : OutboxOperationType.update,
          payload: shift.toJson(),
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
          dependencyRefs: [],
        ),
      );
    });
  }
}
