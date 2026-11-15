import 'package:equatable/equatable.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'doctor_compensation_rule_model.dart';
import 'doctor_settlement_item_model.dart';
import 'enums/settlement_status_enum.dart';

class DoctorSettlementModel extends Equatable {
  final String? id;
  final String? settlementNumber;
  final String? doctorId;
  final String? doctorName;
  final String? branchId;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final SettlementStatusEnum? status;
  final int? totalVisitsCount;
  final int? totalNetRevenuePiastres;
  final int? totalDoctorCommissionPiastres;
  final int? totalClinicSharePiastres;
  final int? baseSalaryPiastres;
  final int? totalBonusesPiastres;
  final int? totalDeductionsPiastres;
  final int? totalAdvancesDeductedPiastres;
  final int? netPayablePiastres;
  final DoctorCompensationRuleModel? compensationRuleSnapshot;
  final List<DoctorSettlementItemModel>? items;
  final List<String>? consumedEventIds;
  final List<String>? consumedAdvanceEntryIds;
  final String? confirmedByUserId;
  final DateTime? confirmedAt;
  final DateTime? paidAt;
  final PaymentMethod? paymentMethod;
  final String? paymentReferenceNumber;
  final bool? isOwnerSelfConfirmed;
  final String? source;
  final DateTime? createdAt;

  const DoctorSettlementModel({
    this.id,
    this.settlementNumber,
    this.doctorId,
    this.doctorName,
    this.branchId,
    this.periodStart,
    this.periodEnd,
    this.status = SettlementStatusEnum.draft,
    this.totalVisitsCount,
    this.totalNetRevenuePiastres,
    this.totalDoctorCommissionPiastres,
    this.totalClinicSharePiastres,
    this.baseSalaryPiastres,
    this.totalBonusesPiastres,
    this.totalDeductionsPiastres,
    this.totalAdvancesDeductedPiastres,
    this.netPayablePiastres,
    this.compensationRuleSnapshot,
    this.items,
    this.consumedEventIds,
    this.consumedAdvanceEntryIds,
    this.confirmedByUserId,
    this.confirmedAt,
    this.paidAt,
    this.paymentMethod,
    this.paymentReferenceNumber,
    this.isOwnerSelfConfirmed,
    this.source,
    this.createdAt,
  });

  factory DoctorSettlementModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DoctorSettlementModel();
    return DoctorSettlementModel(
      id: json['id']?.toString(),
      settlementNumber: json['settlementNumber'] as String?,
      doctorId: json['doctorId'] as String?,
      doctorName: json['doctorName'] as String?,
      branchId: json['branchId'] as String?,
      periodStart: json['periodStart'] != null
          ? DateTime.tryParse(json['periodStart'].toString())
          : null,
      periodEnd: json['periodEnd'] != null
          ? DateTime.tryParse(json['periodEnd'].toString())
          : null,
      status: SettlementStatusEnum.fromJson(json['status'] as String?),
      totalVisitsCount: json['totalVisitsCount'] is num
          ? (json['totalVisitsCount'] as num).toInt()
          : null,
      totalNetRevenuePiastres: json['totalNetRevenuePiastres'] is num
          ? (json['totalNetRevenuePiastres'] as num).toInt()
          : null,
      totalDoctorCommissionPiastres: json['totalDoctorCommissionPiastres'] is num
          ? (json['totalDoctorCommissionPiastres'] as num).toInt()
          : null,
      totalClinicSharePiastres: json['totalClinicSharePiastres'] is num
          ? (json['totalClinicSharePiastres'] as num).toInt()
          : null,
      baseSalaryPiastres: json['baseSalaryPiastres'] is num
          ? (json['baseSalaryPiastres'] as num).toInt()
          : null,
      totalBonusesPiastres: json['totalBonusesPiastres'] is num
          ? (json['totalBonusesPiastres'] as num).toInt()
          : null,
      totalDeductionsPiastres: json['totalDeductionsPiastres'] is num
          ? (json['totalDeductionsPiastres'] as num).toInt()
          : null,
      totalAdvancesDeductedPiastres: json['totalAdvancesDeductedPiastres'] is num
          ? (json['totalAdvancesDeductedPiastres'] as num).toInt()
          : null,
      netPayablePiastres: json['netPayablePiastres'] is num
          ? (json['netPayablePiastres'] as num).toInt()
          : null,
      compensationRuleSnapshot: DoctorCompensationRuleModel.fromJson(
        json['compensationRuleSnapshot'] as Map<String, dynamic>?,
      ),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => DoctorSettlementItemModel.fromJson(e as Map<String, dynamic>?))
          .toList(),
      consumedEventIds: (json['consumedEventIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      consumedAdvanceEntryIds: (json['consumedAdvanceEntryIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      confirmedByUserId: json['confirmedByUserId'] as String?,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.tryParse(json['confirmedAt'].toString())
          : null,
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString())
          : null,
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.fromValue(json['paymentMethod'] as String?)
          : null,
      paymentReferenceNumber: json['paymentReferenceNumber'] as String?,
      isOwnerSelfConfirmed: json['isOwnerSelfConfirmed'] as bool?,
      source: json['source'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'settlementNumber': settlementNumber,
    'doctorId': doctorId,
    'doctorName': doctorName,
    'branchId': branchId,
    'periodStart': periodStart?.toIso8601String(),
    'periodEnd': periodEnd?.toIso8601String(),
    'status': status?.toJson(),
    'totalVisitsCount': totalVisitsCount,
    'totalNetRevenuePiastres': totalNetRevenuePiastres,
    'totalDoctorCommissionPiastres': totalDoctorCommissionPiastres,
    'totalClinicSharePiastres': totalClinicSharePiastres,
    'baseSalaryPiastres': baseSalaryPiastres,
    'totalBonusesPiastres': totalBonusesPiastres,
    'totalDeductionsPiastres': totalDeductionsPiastres,
    'totalAdvancesDeductedPiastres': totalAdvancesDeductedPiastres,
    'netPayablePiastres': netPayablePiastres,
    'compensationRuleSnapshot': compensationRuleSnapshot?.toJson(),
    'items': items?.map((e) => e.toJson()).toList(),
    'consumedEventIds': consumedEventIds,
    'consumedAdvanceEntryIds': consumedAdvanceEntryIds,
    'confirmedByUserId': confirmedByUserId,
    'confirmedAt': confirmedAt?.toIso8601String(),
    'paidAt': paidAt?.toIso8601String(),
    'paymentMethod': paymentMethod?.value,
    'paymentReferenceNumber': paymentReferenceNumber,
    'isOwnerSelfConfirmed': isOwnerSelfConfirmed,
    'source': source,
    'createdAt': createdAt?.toIso8601String(),
  };

  DoctorSettlementModel copyWith({
    String? id,
    String? settlementNumber,
    String? doctorId,
    String? doctorName,
    String? branchId,
    DateTime? periodStart,
    DateTime? periodEnd,
    SettlementStatusEnum? status,
    int? totalVisitsCount,
    int? totalNetRevenuePiastres,
    int? totalDoctorCommissionPiastres,
    int? totalClinicSharePiastres,
    int? baseSalaryPiastres,
    int? totalBonusesPiastres,
    int? totalDeductionsPiastres,
    int? totalAdvancesDeductedPiastres,
    int? netPayablePiastres,
    DoctorCompensationRuleModel? compensationRuleSnapshot,
    List<DoctorSettlementItemModel>? items,
    List<String>? consumedEventIds,
    List<String>? consumedAdvanceEntryIds,
    String? confirmedByUserId,
    DateTime? confirmedAt,
    DateTime? paidAt,
    PaymentMethod? paymentMethod,
    String? paymentReferenceNumber,
    bool? isOwnerSelfConfirmed,
    String? source,
    DateTime? createdAt,
  }) {
    return DoctorSettlementModel(
      id: id ?? this.id,
      settlementNumber: settlementNumber ?? this.settlementNumber,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      branchId: branchId ?? this.branchId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      status: status ?? this.status,
      totalVisitsCount: totalVisitsCount ?? this.totalVisitsCount,
      totalNetRevenuePiastres: totalNetRevenuePiastres ?? this.totalNetRevenuePiastres,
      totalDoctorCommissionPiastres: totalDoctorCommissionPiastres ?? this.totalDoctorCommissionPiastres,
      totalClinicSharePiastres: totalClinicSharePiastres ?? this.totalClinicSharePiastres,
      baseSalaryPiastres: baseSalaryPiastres ?? this.baseSalaryPiastres,
      totalBonusesPiastres: totalBonusesPiastres ?? this.totalBonusesPiastres,
      totalDeductionsPiastres: totalDeductionsPiastres ?? this.totalDeductionsPiastres,
      totalAdvancesDeductedPiastres: totalAdvancesDeductedPiastres ?? this.totalAdvancesDeductedPiastres,
      netPayablePiastres: netPayablePiastres ?? this.netPayablePiastres,
      compensationRuleSnapshot: compensationRuleSnapshot ?? this.compensationRuleSnapshot,
      items: items ?? this.items,
      consumedEventIds: consumedEventIds ?? this.consumedEventIds,
      consumedAdvanceEntryIds: consumedAdvanceEntryIds ?? this.consumedAdvanceEntryIds,
      confirmedByUserId: confirmedByUserId ?? this.confirmedByUserId,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReferenceNumber: paymentReferenceNumber ?? this.paymentReferenceNumber,
      isOwnerSelfConfirmed: isOwnerSelfConfirmed ?? this.isOwnerSelfConfirmed,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    settlementNumber,
    doctorId,
    doctorName,
    branchId,
    periodStart,
    periodEnd,
    status,
    totalVisitsCount,
    totalNetRevenuePiastres,
    totalDoctorCommissionPiastres,
    totalClinicSharePiastres,
    baseSalaryPiastres,
    totalBonusesPiastres,
    totalDeductionsPiastres,
    totalAdvancesDeductedPiastres,
    netPayablePiastres,
    compensationRuleSnapshot,
    items,
    consumedEventIds,
    consumedAdvanceEntryIds,
    confirmedByUserId,
    confirmedAt,
    paidAt,
    paymentMethod,
    paymentReferenceNumber,
    isOwnerSelfConfirmed,
    source,
    createdAt,
  ];
}

