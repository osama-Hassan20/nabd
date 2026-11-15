import 'package:equatable/equatable.dart';
import 'enums/addendum_change_type_enum.dart';
import 'prescription_item_model.dart';

class VisitAddendumModel extends Equatable {
  final String? id;
  final String? visitId;
  final String? doctorId;
  final String? doctorName;
  final DateTime? createdAt;
  final String? reason;
  final AddendumChangeTypeEnum? changeType;
  final String? affectedItemId;
  final PrescriptionItemModel? oldItemSnapshot;
  final PrescriptionItemModel? newItemSnapshot;
  final String? diagnosisBefore;
  final String? diagnosisAfter;
  final String? notes;

  const VisitAddendumModel({
    this.id,
    this.visitId,
    this.doctorId,
    this.doctorName,
    this.createdAt,
    this.reason,
    this.changeType,
    this.affectedItemId,
    this.oldItemSnapshot,
    this.newItemSnapshot,
    this.diagnosisBefore,
    this.diagnosisAfter,
    this.notes,
  });

  factory VisitAddendumModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VisitAddendumModel();
    return VisitAddendumModel(
      id: json['id'] as String?,
      visitId: json['visitId'] as String?,
      doctorId: json['doctorId'] as String?,
      doctorName: json['doctorName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      reason: json['reason'] as String?,
      changeType: AddendumChangeTypeEnum.fromJson(json['changeType'] as String?),
      affectedItemId: json['affectedItemId'] as String?,
      oldItemSnapshot: json['oldItemSnapshot'] != null
          ? PrescriptionItemModel.fromJson(
              json['oldItemSnapshot'] as Map<String, dynamic>)
          : null,
      newItemSnapshot: json['newItemSnapshot'] != null
          ? PrescriptionItemModel.fromJson(
              json['newItemSnapshot'] as Map<String, dynamic>)
          : null,
      diagnosisBefore: json['diagnosisBefore'] as String?,
      diagnosisAfter: json['diagnosisAfter'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visitId': visitId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'createdAt': createdAt?.toIso8601String(),
      'reason': reason,
      'changeType': changeType?.toJson(),
      'affectedItemId': affectedItemId,
      'oldItemSnapshot': oldItemSnapshot?.toJson(),
      'newItemSnapshot': newItemSnapshot?.toJson(),
      'diagnosisBefore': diagnosisBefore,
      'diagnosisAfter': diagnosisAfter,
      'notes': notes,
    };
  }

  VisitAddendumModel copyWith({
    String? id,
    String? visitId,
    String? doctorId,
    String? doctorName,
    DateTime? createdAt,
    String? reason,
    AddendumChangeTypeEnum? changeType,
    String? affectedItemId,
    PrescriptionItemModel? oldItemSnapshot,
    PrescriptionItemModel? newItemSnapshot,
    String? diagnosisBefore,
    String? diagnosisAfter,
    String? notes,
  }) {
    return VisitAddendumModel(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      createdAt: createdAt ?? this.createdAt,
      reason: reason ?? this.reason,
      changeType: changeType ?? this.changeType,
      affectedItemId: affectedItemId ?? this.affectedItemId,
      oldItemSnapshot: oldItemSnapshot ?? this.oldItemSnapshot,
      newItemSnapshot: newItemSnapshot ?? this.newItemSnapshot,
      diagnosisBefore: diagnosisBefore ?? this.diagnosisBefore,
      diagnosisAfter: diagnosisAfter ?? this.diagnosisAfter,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        visitId,
        doctorId,
        doctorName,
        createdAt,
        reason,
        changeType,
        affectedItemId,
        oldItemSnapshot,
        newItemSnapshot,
        diagnosisBefore,
        diagnosisAfter,
        notes,
      ];
}

