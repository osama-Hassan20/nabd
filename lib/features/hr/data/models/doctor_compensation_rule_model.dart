import 'package:equatable/equatable.dart';
import 'enums/compensation_type_enum.dart';

class DoctorCompensationRuleModel extends Equatable {
  final String? id;
  final String? doctorId;
  final String? branchId;
  final CompensationTypeEnum? compensationType;
  final num? commissionPercentage;
  final int? fixedAmountPerVisitPiastres;
  final int? monthlyBaseSalaryPiastres;
  final DateTime? effectiveFrom;
  final DateTime? createdAt;
  final bool? isActive;
  final bool? payForFreeVisits;
  final String? notes;

  const DoctorCompensationRuleModel({
    this.id,
    this.doctorId,
    this.branchId,
    this.compensationType = CompensationTypeEnum.percentage,
    this.commissionPercentage,
    this.fixedAmountPerVisitPiastres,
    this.monthlyBaseSalaryPiastres,
    this.effectiveFrom,
    this.createdAt,
    this.isActive = true,
    this.payForFreeVisits = false,
    this.notes,
  });

  factory DoctorCompensationRuleModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DoctorCompensationRuleModel();
    return DoctorCompensationRuleModel(
      id: json['id']?.toString(),
      doctorId: json['doctorId'] as String?,
      branchId: json['branchId'] as String?,
      compensationType: CompensationTypeEnum.fromJson(json['compensationType'] as String?),
      commissionPercentage: json['commissionPercentage'] as num?,
      fixedAmountPerVisitPiastres: json['fixedAmountPerVisitPiastres'] is num
          ? (json['fixedAmountPerVisitPiastres'] as num).toInt()
          : null,
      monthlyBaseSalaryPiastres: json['monthlyBaseSalaryPiastres'] is num
          ? (json['monthlyBaseSalaryPiastres'] as num).toInt()
          : null,
      effectiveFrom: json['effectiveFrom'] != null
          ? DateTime.tryParse(json['effectiveFrom'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      isActive: json['isActive'] as bool? ?? true,
      payForFreeVisits: json['payForFreeVisits'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'doctorId': doctorId,
    'branchId': branchId,
    'compensationType': compensationType?.toJson(),
    'commissionPercentage': commissionPercentage,
    'fixedAmountPerVisitPiastres': fixedAmountPerVisitPiastres,
    'monthlyBaseSalaryPiastres': monthlyBaseSalaryPiastres,
    'effectiveFrom': effectiveFrom?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'isActive': isActive,
    'payForFreeVisits': payForFreeVisits,
    'notes': notes,
  };

  DoctorCompensationRuleModel copyWith({
    String? id,
    String? doctorId,
    String? branchId,
    CompensationTypeEnum? compensationType,
    num? commissionPercentage,
    int? fixedAmountPerVisitPiastres,
    int? monthlyBaseSalaryPiastres,
    DateTime? effectiveFrom,
    DateTime? createdAt,
    bool? isActive,
    bool? payForFreeVisits,
    String? notes,
  }) {
    return DoctorCompensationRuleModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      branchId: branchId ?? this.branchId,
      compensationType: compensationType ?? this.compensationType,
      commissionPercentage: commissionPercentage ?? this.commissionPercentage,
      fixedAmountPerVisitPiastres: fixedAmountPerVisitPiastres ?? this.fixedAmountPerVisitPiastres,
      monthlyBaseSalaryPiastres: monthlyBaseSalaryPiastres ?? this.monthlyBaseSalaryPiastres,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      payForFreeVisits: payForFreeVisits ?? this.payForFreeVisits,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    doctorId,
    branchId,
    compensationType,
    commissionPercentage,
    fixedAmountPerVisitPiastres,
    monthlyBaseSalaryPiastres,
    effectiveFrom,
    createdAt,
    isActive,
    payForFreeVisits,
    notes,
  ];
}
