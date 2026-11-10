import 'package:equatable/equatable.dart';

class UpdateRoleDiscountPolicyParams extends Equatable {
  final String roleId;
  final num? maxDiscountPercent;
  final bool? canGrantFreeConsultation;
  final String currentUserId;

  const UpdateRoleDiscountPolicyParams({
    required this.roleId,
    this.maxDiscountPercent,
    this.canGrantFreeConsultation,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [
        roleId,
        maxDiscountPercent,
        canGrantFreeConsultation,
        currentUserId,
      ];
}

