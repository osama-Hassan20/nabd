import 'package:equatable/equatable.dart';

class BranchAssignmentModel extends Equatable {
  final String? branchId;
  final bool? isPrimary;
  final List<String>? roleIds;

  const BranchAssignmentModel({
    this.branchId,
    this.isPrimary,
    this.roleIds,
  });

  BranchAssignmentModel copyWith({
    String? branchId,
    bool? isPrimary,
    List<String>? roleIds,
  }) {
    return BranchAssignmentModel(
      branchId: branchId ?? this.branchId,
      isPrimary: isPrimary ?? this.isPrimary,
      roleIds: roleIds ?? this.roleIds,
    );
  }

  factory BranchAssignmentModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BranchAssignmentModel();
    return BranchAssignmentModel(
      branchId: json['branchId'] as String?,
      isPrimary: json['isPrimary'] as bool?,
      roleIds: (json['roleIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'isPrimary': isPrimary,
      'roleIds': roleIds,
    };
  }

  @override
  List<Object?> get props => [branchId, isPrimary, roleIds];
}

