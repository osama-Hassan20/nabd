import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../bookings/domain/repo/bookings_repo.dart';
import '../../data/models/refund_transaction_model.dart';
import '../helpers/payment_reconciliation_helper.dart';
import '../repo/cashier_repo.dart';

class RefundPaymentUseCase {
  final CashierRepo cashierRepo;
  final BookingsRepo bookingsRepo;
  final PaymentReconciliationHelper reconciliationHelper;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  const RefundPaymentUseCase({
    required this.cashierRepo,
    required this.bookingsRepo,
    this.reconciliationHelper = const PaymentReconciliationHelper(),
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  Future<Either<Failures, RefundTransactionModel>> call({
    required String clientRequestId,
    required String originalPaymentId,
    required String shiftId,
    required String branchId,
    required String bookingId,
    required String patientId,
    required int refundAmountPiastres,
    required String refundMethod,
    required String reason,
    String? authorizedByUserId,
    String? authorizedByName,
  }) async {
    // 1. Resolve authorizer
    final user = currentUserProvider?.currentUser;
    final effectiveUserId = authorizedByUserId ?? user?.id;
    final effectiveName = authorizedByName ?? user?.fullName ?? 'Authorized Manager';

    if (effectiveUserId == null) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_user_required'),
      );
    }

    // 2. Permission check: refundPayment (manager or owner)
    if (permissionEvaluator != null) {
      final canRefund = permissionEvaluator!.can(
        StaffPermissionEnum.refundPayment,
        branchId: branchId,
      );
      if (!canRefund) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    // 3. Delegate to Saga
    return reconciliationHelper.refundPaymentWithSaga(
      cashierRepo: cashierRepo,
      bookingsRepo: bookingsRepo,
      clientRequestId: clientRequestId,
      originalPaymentId: originalPaymentId,
      shiftId: shiftId,
      branchId: branchId,
      bookingId: bookingId,
      patientId: patientId,
      refundAmountPiastres: refundAmountPiastres,
      refundMethod: refundMethod,
      reason: reason,
      authorizedByUserId: effectiveUserId,
      authorizedByName: effectiveName,
      auditLogger: auditLogger,
    );
  }
}
