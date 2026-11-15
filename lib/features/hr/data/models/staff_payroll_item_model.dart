import 'package:equatable/equatable.dart';

class StaffPayrollItemModel extends Equatable {
  final String? staffUserId;
  final String? employeeName;
  final String? jobTitle;
  final String? primaryBranchId;
  final int? baseSalaryPiastres;
  final int? housingAllowancePiastres;
  final int? transportationAllowancePiastres;
  final int? totalAllowancesPiastres;
  final int? insuranceDeductionPiastres;
  final int? taxDeductionPiastres;
  final int? ledgerDeductionsPiastres;
  final int? ledgerBonusesPiastres;
  final int? advancesDeductedPiastres;
  final int? totalDeductionsPiastres;
  final int? netSalaryPiastres;

  const StaffPayrollItemModel({
    this.staffUserId,
    this.employeeName,
    this.jobTitle,
    this.primaryBranchId,
    this.baseSalaryPiastres,
    this.housingAllowancePiastres,
    this.transportationAllowancePiastres,
    this.totalAllowancesPiastres,
    this.insuranceDeductionPiastres,
    this.taxDeductionPiastres,
    this.ledgerDeductionsPiastres,
    this.ledgerBonusesPiastres,
    this.advancesDeductedPiastres,
    this.totalDeductionsPiastres,
    this.netSalaryPiastres,
  });

  factory StaffPayrollItemModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StaffPayrollItemModel();
    return StaffPayrollItemModel(
      staffUserId: json['staffUserId'] as String?,
      employeeName: json['employeeName'] as String?,
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
      totalAllowancesPiastres: json['totalAllowancesPiastres'] is num
          ? (json['totalAllowancesPiastres'] as num).toInt()
          : null,
      insuranceDeductionPiastres: json['insuranceDeductionPiastres'] is num
          ? (json['insuranceDeductionPiastres'] as num).toInt()
          : null,
      taxDeductionPiastres: json['taxDeductionPiastres'] is num
          ? (json['taxDeductionPiastres'] as num).toInt()
          : null,
      ledgerDeductionsPiastres: json['ledgerDeductionsPiastres'] is num
          ? (json['ledgerDeductionsPiastres'] as num).toInt()
          : null,
      ledgerBonusesPiastres: json['ledgerBonusesPiastres'] is num
          ? (json['ledgerBonusesPiastres'] as num).toInt()
          : null,
      advancesDeductedPiastres: json['advancesDeductedPiastres'] is num
          ? (json['advancesDeductedPiastres'] as num).toInt()
          : null,
      totalDeductionsPiastres: json['totalDeductionsPiastres'] is num
          ? (json['totalDeductionsPiastres'] as num).toInt()
          : null,
      netSalaryPiastres: json['netSalaryPiastres'] is num
          ? (json['netSalaryPiastres'] as num).toInt()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'staffUserId': staffUserId,
    'employeeName': employeeName,
    'jobTitle': jobTitle,
    'primaryBranchId': primaryBranchId,
    'baseSalaryPiastres': baseSalaryPiastres,
    'housingAllowancePiastres': housingAllowancePiastres,
    'transportationAllowancePiastres': transportationAllowancePiastres,
    'totalAllowancesPiastres': totalAllowancesPiastres,
    'insuranceDeductionPiastres': insuranceDeductionPiastres,
    'taxDeductionPiastres': taxDeductionPiastres,
    'ledgerDeductionsPiastres': ledgerDeductionsPiastres,
    'ledgerBonusesPiastres': ledgerBonusesPiastres,
    'advancesDeductedPiastres': advancesDeductedPiastres,
    'totalDeductionsPiastres': totalDeductionsPiastres,
    'netSalaryPiastres': netSalaryPiastres,
  };

  StaffPayrollItemModel copyWith({
    String? staffUserId,
    String? employeeName,
    String? jobTitle,
    String? primaryBranchId,
    int? baseSalaryPiastres,
    int? housingAllowancePiastres,
    int? transportationAllowancePiastres,
    int? totalAllowancesPiastres,
    int? insuranceDeductionPiastres,
    int? taxDeductionPiastres,
    int? ledgerDeductionsPiastres,
    int? ledgerBonusesPiastres,
    int? advancesDeductedPiastres,
    int? totalDeductionsPiastres,
    int? netSalaryPiastres,
  }) {
    return StaffPayrollItemModel(
      staffUserId: staffUserId ?? this.staffUserId,
      employeeName: employeeName ?? this.employeeName,
      jobTitle: jobTitle ?? this.jobTitle,
      primaryBranchId: primaryBranchId ?? this.primaryBranchId,
      baseSalaryPiastres: baseSalaryPiastres ?? this.baseSalaryPiastres,
      housingAllowancePiastres: housingAllowancePiastres ?? this.housingAllowancePiastres,
      transportationAllowancePiastres: transportationAllowancePiastres ?? this.transportationAllowancePiastres,
      totalAllowancesPiastres: totalAllowancesPiastres ?? this.totalAllowancesPiastres,
      insuranceDeductionPiastres: insuranceDeductionPiastres ?? this.insuranceDeductionPiastres,
      taxDeductionPiastres: taxDeductionPiastres ?? this.taxDeductionPiastres,
      ledgerDeductionsPiastres: ledgerDeductionsPiastres ?? this.ledgerDeductionsPiastres,
      ledgerBonusesPiastres: ledgerBonusesPiastres ?? this.ledgerBonusesPiastres,
      advancesDeductedPiastres: advancesDeductedPiastres ?? this.advancesDeductedPiastres,
      totalDeductionsPiastres: totalDeductionsPiastres ?? this.totalDeductionsPiastres,
      netSalaryPiastres: netSalaryPiastres ?? this.netSalaryPiastres,
    );
  }

  @override
  List<Object?> get props => [
    staffUserId,
    employeeName,
    jobTitle,
    primaryBranchId,
    baseSalaryPiastres,
    housingAllowancePiastres,
    transportationAllowancePiastres,
    totalAllowancesPiastres,
    insuranceDeductionPiastres,
    taxDeductionPiastres,
    ledgerDeductionsPiastres,
    ledgerBonusesPiastres,
    advancesDeductedPiastres,
    totalDeductionsPiastres,
    netSalaryPiastres,
  ];
}

