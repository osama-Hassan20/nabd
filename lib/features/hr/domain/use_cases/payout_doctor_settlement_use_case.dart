import 'package:dartz/dartz.dart';
import '../../../../core/enums/payment_method.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/doctor_settlement_model.dart';
import '../../data/models/enums/settlement_status_enum.dart';
import '../repo/hr_repo.dart';

class PayoutDoctorSettlementUseCase {
  final HrRepo hrRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  const PayoutDoctorSettlementUseCase({
    required this.hrRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  Future<Either<Failures, DoctorSettlementModel>> call({
    required String settlementId,
    required PaymentMethod paymentMethod,
    String? paymentReferenceNumber,
  }) async {
    final user = currentUserProvider?.currentUser;
    if (user == null || user.canAuthenticate == false) {
      return const Left(ValidationFailure(errMessage: 'permission_denied'));
    }

    // 1. Fetch settlement
    final existingRes = await hrRepo.getDoctorSettlementById(settlementId);
    if (existingRes.isLeft()) {
      return existingRes;
    }
    final settlement = existingRes.getOrElse(() => throw StateError('unreachable'));

    // 2. Status validation: must be confirmed
    if (settlement.status == SettlementStatusEnum.draft) {
      return const Left(ValidationFailure(errMessage: 'hr_settlement_not_confirmed_cannot_payout'));
    }
    if (settlement.status == SettlementStatusEnum.paid) {
      return const Left(ValidationFailure(errMessage: 'hr_settlement_already_paid'));
    }

    // 3. Permission check: payoutSettlement (Accountant / Owner only)
    if (permissionEvaluator != null) {
      final canPayout = permissionEvaluator!.can(
        StaffPermissionEnum.payoutSettlement,
        branchId: settlement.branchId,
      );
      if (!canPayout) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    // 4. Payout in repo
    final payoutRes = await hrRepo.payoutDoctorSettlement(
      settlementId: settlementId,
      paidByUserId: user.id ?? 'unknown_user',
      method: paymentMethod,
      refNumber: paymentReferenceNumber,
    );

    // 5. Security Audit logging on success ONLY
    payoutRes.fold(
      (failure) => null,
      (paid) {
        auditLogger?.log(
          eventType: 'doctor_settlement_paid',
          performedByUserId: user.id,
          performedByUserName: user.fullName ?? 'Unknown',
          branchId: paid.branchId,
          details:
              'settlementId: ${paid.id}, doctorId: ${paid.doctorId}, '
              'paidAmountPiastres: ${paid.netPayablePiastres}, paymentMethod: ${paymentMethod.name}, '
              'paidByUserId: ${user.id}',
        );
      },
    );

    return payoutRes;
  }
}
