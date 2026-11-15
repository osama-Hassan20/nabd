import 'package:equatable/equatable.dart';
import 'enums/employee_type_enum.dart';
import 'enums/ledger_entry_type_enum.dart';

class EmployeeLedgerEntryModel extends Equatable {
  final String? id;
  final String? employeeId;
  final EmployeeTypeEnum? employeeType;
  final String? branchId;
  final LedgerEntryTypeEnum? entryType;
  final int? amountPiastres;
  final String? reason;
  final DateTime? date;
  final String? performedByUserId;
  final String? clientRequestId;
  final String? reversesEntryId;
  final DateTime? createdAt;

  const EmployeeLedgerEntryModel({
    this.id,
    this.employeeId,
    this.employeeType = EmployeeTypeEnum.doctor,
    this.branchId,
    this.entryType,
    this.amountPiastres,
    this.reason,
    this.date,
    this.performedByUserId,
    this.clientRequestId,
    this.reversesEntryId,
    this.createdAt,
  });

  factory EmployeeLedgerEntryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EmployeeLedgerEntryModel();
    return EmployeeLedgerEntryModel(
      id: json['id']?.toString(),
      employeeId: json['employeeId'] as String?,
      employeeType: EmployeeTypeEnum.fromJson(json['employeeType'] as String?),
      branchId: json['branchId'] as String?,
      entryType: LedgerEntryTypeEnum.fromJson(json['entryType'] as String?),
      amountPiastres: json['amountPiastres'] is num
          ? (json['amountPiastres'] as num).toInt()
          : null,
      reason: json['reason'] as String?,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      performedByUserId: json['performedByUserId'] as String?,
      clientRequestId: json['clientRequestId'] as String?,
      reversesEntryId: json['reversesEntryId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'employeeType': employeeType?.toJson(),
    'branchId': branchId,
    'entryType': entryType?.toJson(),
    'amountPiastres': amountPiastres,
    'reason': reason,
    'date': date?.toIso8601String(),
    'performedByUserId': performedByUserId,
    'clientRequestId': clientRequestId,
    'reversesEntryId': reversesEntryId,
    'createdAt': createdAt?.toIso8601String(),
  };

  EmployeeLedgerEntryModel copyWith({
    String? id,
    String? employeeId,
    EmployeeTypeEnum? employeeType,
    String? branchId,
    LedgerEntryTypeEnum? entryType,
    int? amountPiastres,
    String? reason,
    DateTime? date,
    String? performedByUserId,
    String? clientRequestId,
    String? reversesEntryId,
    DateTime? createdAt,
  }) {
    return EmployeeLedgerEntryModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeType: employeeType ?? this.employeeType,
      branchId: branchId ?? this.branchId,
      entryType: entryType ?? this.entryType,
      amountPiastres: amountPiastres ?? this.amountPiastres,
      reason: reason ?? this.reason,
      date: date ?? this.date,
      performedByUserId: performedByUserId ?? this.performedByUserId,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      reversesEntryId: reversesEntryId ?? this.reversesEntryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeType,
    branchId,
    entryType,
    amountPiastres,
    reason,
    date,
    performedByUserId,
    clientRequestId,
    reversesEntryId,
    createdAt,
  ];
}
