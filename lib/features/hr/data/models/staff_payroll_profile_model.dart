import 'package:equatable/equatable.dart';

class StaffPayrollProfileModel extends Equatable {
  final String? id;
  final String? staffUserId;
  final String? fullName;
  final String? jobTitle;
  final String? primaryBranchId;
  final int? baseSalaryPiastres;
  final int? housingAllowancePiastres;
  final int? transportationAllowancePiastres;
  final int? insuranceDeductionPiastres;
  final int? taxDeductionPiastres;
  final bool? isActive;
  final DateTime? updatedAt;

  const StaffPayrollProfileModel({
    this.id,
    this.staffUserId,
    this.fullName,
    this.jobTitle,
    this.primaryBranchId,
    this.baseSalaryPiastres,
    this.housingAllowancePiastres,
    this.transportationAllowancePiastres,
    this.insuranceDeductionPiastres,
    this.taxDeductionPiastres,
    this.isActive = true,
    this.updatedAt,
  });

  factory StaffPayrollProfileModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StaffPayrollProfileModel();
    return StaffPayrollProfileModel(
      id: json['id']?.toString(),
      staffUserId: json['staffUserId'] as String?,
      fullName: json['fullName'] as String?,
      jobTitle: json['jobTitle'] as String?,
      primaryBranchId: json['primaryBranchId'] as String?,
      baseSalaryPiastres: json['baseSalaryPiastres'] is num
          ? (json['baseSalaryPiastres'] as num).toInt()
          : null,
      housingAllowancePiastres: json['housingAllowancePiastres'] is num
          ? (json['housingAllowancePiastres'] as num).toInt()
          : null,
      transportationAllowancePiastres: json['transportationAllowancePiastres'] is num
          ? (json['transportationAllowancePiastres'] as num).toInt()
          : null,
      insuranceDeductionPiastres: json['insuranceDeductionPiastres'] is num
          ? (json['insuranceDeductionPiastres'] as num).toInt()
          : null,
      taxDeductionPiastres: json['taxDeductionPiastres'] is num
          ? (json['taxDeductionPiastres'] as num).toInt()
          : null,
      isActive: json['isActive'] as bool? ?? true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'staffUserId': staffUserId,
    'fullName': fullName,
    'jobTitle': jobTitle,
    'primaryBranchId': primaryBranchId,
    'baseSalaryPiastres': baseSalaryPiastres,
    'housingAllowancePiastres': housingAllowancePiastres,
    'transportationAllowancePiastres': transportationAllowancePiastres,
    'insuranceDeductionPiastres': insuranceDeductionPiastres,
    'taxDeductionPiastres': taxDeductionPiastres,
    'isActive': isActive,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  StaffPayrollProfileModel copyWith({
    String? id,
    String? staffUserId,
    String? fullName,
    String? jobTitle,
    String? primaryBranchId,
    int? baseSalaryPiastres,
    int? housingAllowancePiastres,
    int? transportationAllowancePiastres,
    int? insuranceDeductionPiastres,
    int? taxDeductionPiastres,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return StaffPayrollProfileModel(
      id: id ?? this.id,
      staffUserId: staffUserId ?? this.staffUserId,
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      primaryBranchId: primaryBranchId ?? this.primaryBranchId,
      baseSalaryPiastres: baseSalaryPiastres ?? this.baseSalaryPiastres,
      housingAllowancePiastres: housingAllowancePiastres ?? this.housingAllowancePiastres,
      transportationAllowancePiastres: transportationAllowancePiastres ?? this.transportationAllowancePiastres,
      insuranceDeductionPiastres: insuranceDeductionPiastres ?? this.insuranceDeductionPiastres,
      taxDeductionPiastres: taxDeductionPiastres ?? this.taxDeductionPiastres,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    staffUserId,
    fullName,
    jobTitle,
    primaryBranchId,
    baseSalaryPiastres,
    housingAllowancePiastres,
    transportationAllowancePiastres,
    insuranceDeductionPiastres,
    taxDeductionPiastres,
    isActive,
    updatedAt,
  ];
}
