import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/doctor_settlement_model.dart';
import '../../data/models/enums/settlement_status_enum.dart';
import '../repo/hr_repo.dart';

class ConfirmDoctorSettlementUseCase {
  final HrRepo hrRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  const ConfirmDoctorSettlementUseCase({
    required this.hrRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  Future<Either<Failures, DoctorSettlementModel>> call({
    required String settlementId,
  }) async {
    final user = currentUserProvider?.currentUser;
    if (user == null || user.canAuthenticate == false) {
      return const Left(ValidationFailure(errMessage: 'permission_denied'));
    }

    // 1. Fetch existing settlement
    final existingRes = await hrRepo.getDoctorSettlementById(settlementId);
    if (existingRes.isLeft()) {
      return existingRes;
    }
    final settlement = existingRes.getOrElse(() => throw StateError('unreachable'));

    // 2. Validate current status
    if (settlement.status != SettlementStatusEnum.draft) {
      return const Left(ValidationFailure(errMessage: 'hr_settlement_already_confirmed_or_paid'));
    }

    // 3. Permission check: confirmDoctorSettlement
    if (permissionEvaluator != null) {
      final canConfirm = permissionEvaluator!.can(
        StaffPermissionEnum.confirmDoctorSettlement,
        branchId: settlement.branchId,
      );
      if (!canConfirm) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    // 4. Separation of duties check
    final isSelfDoctor = user.linkedDoctorId != null &&
        settlement.doctorId != null &&
        user.linkedDoctorId == settlement.doctorId;
    final isOwner = user.isOwner == true;

    if (isSelfDoctor && !isOwner) {
      return const Left(ValidationFailure(errMessage: 'hr_doctor_cannot_confirm_own_settlement'));
    }

    final isOwnerSelfConfirmed = isSelfDoctor && isOwner;

    // 5. Confirm in repo
    final confirmRes = await hrRepo.confirmDoctorSettlement(
      settlementId: settlementId,
      confirmedByUserId: user.id ?? 'unknown_user',
      isOwnerSelfConfirmed: isOwnerSelfConfirmed,
    );

    // 6. Security Audit logging on success ONLY
    confirmRes.fold(
      (failure) => null,
      (confirmed) {
        if (isOwnerSelfConfirmed) {
          auditLogger?.log(
            eventType: 'owner_self_confirmed',
            performedByUserId: user.id,
            performedByUserName: user.fullName ?? 'Unknown',
            branchId: confirmed.branchId,
            details:
                'settlementId: ${confirmed.id}, doctorId: ${confirmed.doctorId}, '
                'ownerUserId: ${user.id}, netPayablePiastres: ${confirmed.netPayablePiastres}, '
                'reason: owner_self_confirmed_single_operator',
          );
        } else {
          auditLogger?.log(
            eventType: 'doctor_settlement_confirmed',
            performedByUserId: user.id,
            performedByUserName: user.fullName ?? 'Unknown',
            branchId: confirmed.branchId,
            details:
                'settlementId: ${confirmed.id}, doctorId: ${confirmed.doctorId}, '
                'confirmedByUserId: ${user.id}, netPayablePiastres: ${confirmed.netPayablePiastres}, '
                'itemsCount: ${confirmed.totalVisitsCount ?? confirmed.items?.length ?? 0}',
          );
        }
      },
    );

    return confirmRes;
  }
}
