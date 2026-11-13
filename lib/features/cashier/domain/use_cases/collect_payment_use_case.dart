import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../bookings/domain/repo/bookings_repo.dart';
import '../../data/models/payment_transaction_model.dart';
import '../helpers/payment_reconciliation_helper.dart';
import '../repo/cashier_repo.dart';

class CollectPaymentUseCase {
  final CashierRepo cashierRepo;
  final BookingsRepo bookingsRepo;
  final PaymentReconciliationHelper reconciliationHelper;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  const CollectPaymentUseCase({
    required this.cashierRepo,
    required this.bookingsRepo,
    this.reconciliationHelper = const PaymentReconciliationHelper(),
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  Future<Either<Failures, PaymentTransactionModel>> call({
    required String clientRequestId,
    required String shiftId,
    required String branchId,
    required String bookingId,
    required String patientId,
    required String patientName,
    required int amountPiastres,
    required String paymentMethod,
    String? cashierUserId,
    String? cashierName,
    String? referenceNumber,
    String? notes,
  }) async {
    // 1. Resolve actor
    final user = currentUserProvider?.currentUser;
    final effectiveUserId = cashierUserId ?? user?.id;
    final effectiveName = cashierName ?? user?.fullName ?? 'Unknown';

    if (effectiveUserId == null) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_user_required'),
      );
    }

    // 2. Permission check: collectPayment
    if (permissionEvaluator != null) {
      final canCollect = permissionEvaluator!.can(
        StaffPermissionEnum.collectPayment,
        branchId: branchId,
      );
      if (!canCollect) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    // 3. Delegate to Saga
    return reconciliationHelper.collectPaymentWithSaga(
      cashierRepo: cashierRepo,
      bookingsRepo: bookingsRepo,
      clientRequestId: clientRequestId,
      shiftId: shiftId,
      branchId: branchId,
      bookingId: bookingId,
      patientId: patientId,
      patientName: patientName,
      amountPiastres: amountPiastres,
      paymentMethod: paymentMethod,
      cashierUserId: effectiveUserId,
      cashierName: effectiveName,
      referenceNumber: referenceNumber,
      notes: notes,
      auditLogger: auditLogger,
    );
  }
}
