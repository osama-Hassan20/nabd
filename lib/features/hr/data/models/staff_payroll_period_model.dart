import 'package:equatable/equatable.dart';
import 'enums/payroll_status_enum.dart';
import 'staff_payroll_item_model.dart';

class StaffPayrollPeriodModel extends Equatable {
  final String? id;
  final String? payrollNumber;
  final String? primaryBranchId;
  final int? month;
  final int? year;
  final PayrollStatusEnum? status;
  final int? totalEmployeesCount;
  final int? totalBaseSalaryPiastres;
  final int? totalAllowancesPiastres;
  final int? totalDeductionsPiastres;
  final int? totalNetPayablePiastres;
  final List<StaffPayrollItemModel>? items;
  final String? confirmedByUserId;
  final DateTime? confirmedAt;
  final DateTime? paidAt;
  final DateTime? createdAt;

  const StaffPayrollPeriodModel({
    this.id,
    this.payrollNumber,
    this.primaryBranchId,
    this.month,
    this.year,
    this.status = PayrollStatusEnum.draft,
    this.totalEmployeesCount,
    this.totalBaseSalaryPiastres,
    this.totalAllowancesPiastres,
    this.totalDeductionsPiastres,
    this.totalNetPayablePiastres,
    this.items,
    this.confirmedByUserId,
    this.confirmedAt,
    this.paidAt,
    this.createdAt,
  });

  factory StaffPayrollPeriodModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StaffPayrollPeriodModel();
    return StaffPayrollPeriodModel(
      id: json['id']?.toString(),
      payrollNumber: json['payrollNumber'] as String?,
      primaryBranchId: json['primaryBranchId'] as String?,
      month: json['month'] is num ? (json['month'] as num).toInt() : null,
      year: json['year'] is num ? (json['year'] as num).toInt() : null,
      status: PayrollStatusEnum.fromJson(json['status'] as String?),
      totalEmployeesCount: json['totalEmployeesCount'] is num
          ? (json['totalEmployeesCount'] as num).toInt()
          : null,
      totalBaseSalaryPiastres: json['totalBaseSalaryPiastres'] is num
          ? (json['totalBaseSalaryPiastres'] as num).toInt()
          : null,
      totalAllowancesPiastres: json['totalAllowancesPiastres'] is num
          ? (json['totalAllowancesPiastres'] as num).toInt()
          : null,
      totalDeductionsPiastres: json['totalDeductionsPiastres'] is num
          ? (json['totalDeductionsPiastres'] as num).toInt()
          : null,
      totalNetPayablePiastres: json['totalNetPayablePiastres'] is num
          ? (json['totalNetPayablePiastres'] as num).toInt()
          : null,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => StaffPayrollItemModel.fromJson(e as Map<String, dynamic>?))
          .toList(),
      confirmedByUserId: json['confirmedByUserId'] as String?,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.tryParse(json['confirmedAt'].toString())
          : null,
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'payrollNumber': payrollNumber,
    'primaryBranchId': primaryBranchId,
    'month': month,
    'year': year,
    'status': status?.toJson(),
    'totalEmployeesCount': totalEmployeesCount,
    'totalBaseSalaryPiastres': totalBaseSalaryPiastres,
    'totalAllowancesPiastres': totalAllowancesPiastres,
    'totalDeductionsPiastres': totalDeductionsPiastres,
    'totalNetPayablePiastres': totalNetPayablePiastres,
    'items': items?.map((e) => e.toJson()).toList(),
    'confirmedByUserId': confirmedByUserId,
    'confirmedAt': confirmedAt?.toIso8601String(),
    'paidAt': paidAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
  };

  StaffPayrollPeriodModel copyWith({
    String? id,
    String? payrollNumber,
    String? primaryBranchId,
    int? month,
    int? year,
    PayrollStatusEnum? status,
    int? totalEmployeesCount,
    int? totalBaseSalaryPiastres,
    int? totalAllowancesPiastres,
    int? totalDeductionsPiastres,
    int? totalNetPayablePiastres,
    List<StaffPayrollItemModel>? items,
    String? confirmedByUserId,
    DateTime? confirmedAt,
    DateTime? paidAt,
    DateTime? createdAt,
  }) {
    return StaffPayrollPeriodModel(
      id: id ?? this.id,
      payrollNumber: payrollNumber ?? this.payrollNumber,
      primaryBranchId: primaryBranchId ?? this.primaryBranchId,
      month: month ?? this.month,
      year: year ?? this.year,
      status: status ?? this.status,
      totalEmployeesCount: totalEmployeesCount ?? this.totalEmployeesCount,
      totalBaseSalaryPiastres: totalBaseSalaryPiastres ?? this.totalBaseSalaryPiastres,
      totalAllowancesPiastres: totalAllowancesPiastres ?? this.totalAllowancesPiastres,
      totalDeductionsPiastres: totalDeductionsPiastres ?? this.totalDeductionsPiastres,
      totalNetPayablePiastres: totalNetPayablePiastres ?? this.totalNetPayablePiastres,
      items: items ?? this.items,
      confirmedByUserId: confirmedByUserId ?? this.confirmedByUserId,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    payrollNumber,
    primaryBranchId,
    month,
    year,
    status,
    totalEmployeesCount,
    totalBaseSalaryPiastres,
    totalAllowancesPiastres,
    totalDeductionsPiastres,
    totalNetPayablePiastres,
    items,
    confirmedByUserId,
    confirmedAt,
    paidAt,
    createdAt,
  ];
}
