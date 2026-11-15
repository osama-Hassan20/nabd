import 'package:equatable/equatable.dart';
import 'drug_model.dart';

class DrugImportErrorModel extends Equatable {
  final int? rowIndex;
  final String? rawText;
  final String? reason;

  const DrugImportErrorModel({
    this.rowIndex,
    this.rawText,
    this.reason,
  });

  factory DrugImportErrorModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DrugImportErrorModel();
    return DrugImportErrorModel(
      rowIndex: json['rowIndex'] is num ? (json['rowIndex'] as num).toInt() : null,
      rawText: json['rawText'] as String?,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'rowIndex': rowIndex,
    'rawText': rawText,
    'reason': reason,
  };

  DrugImportErrorModel copyWith({
    int? rowIndex,
    String? rawText,
    String? reason,
  }) {
    return DrugImportErrorModel(
      rowIndex: rowIndex ?? this.rowIndex,
      rawText: rawText ?? this.rawText,
      reason: reason ?? this.reason,
    );
  }

  @override
  List<Object?> get props => [rowIndex, rawText, reason];
}

class DrugImportPreviewModel extends Equatable {
  final int? totalRows;
  final List<DrugModel>? validRows;
  final List<DrugImportErrorModel>? invalidRows;
  final List<DrugModel>? duplicateRows;
  final List<DrugModel>? previewRows;

  const DrugImportPreviewModel({
    this.totalRows,
    this.validRows,
    this.invalidRows,
    this.duplicateRows,
    this.previewRows,
  });

  int get validCount => validRows?.length ?? 0;
  int get invalidCount => invalidRows?.length ?? 0;
  int get duplicateCount => duplicateRows?.length ?? 0;

  factory DrugImportPreviewModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DrugImportPreviewModel();
    return DrugImportPreviewModel(
      totalRows: json['totalRows'] is num ? (json['totalRows'] as num).toInt() : null,
      validRows: (json['validRows'] as List<dynamic>?)
          ?.map((e) => DrugModel.fromJson(e as Map<String, dynamic>?))
          .toList(),
      invalidRows: (json['invalidRows'] as List<dynamic>?)
          ?.map((e) => DrugImportErrorModel.fromJson(e as Map<String, dynamic>?))
          .toList(),
      duplicateRows: (json['duplicateRows'] as List<dynamic>?)
          ?.map((e) => DrugModel.fromJson(e as Map<String, dynamic>?))
          .toList(),
      previewRows: (json['previewRows'] as List<dynamic>?)
          ?.map((e) => DrugModel.fromJson(e as Map<String, dynamic>?))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalRows': totalRows,
    'validRows': validRows?.map((e) => e.toJson()).toList(),
    'invalidRows': invalidRows?.map((e) => e.toJson()).toList(),
    'duplicateRows': duplicateRows?.map((e) => e.toJson()).toList(),
    'previewRows': previewRows?.map((e) => e.toJson()).toList(),
  };

  DrugImportPreviewModel copyWith({
    int? totalRows,
    List<DrugModel>? validRows,
    List<DrugImportErrorModel>? invalidRows,
    List<DrugModel>? duplicateRows,
    List<DrugModel>? previewRows,
  }) {
    return DrugImportPreviewModel(
      totalRows: totalRows ?? this.totalRows,
      validRows: validRows ?? this.validRows,
      invalidRows: invalidRows ?? this.invalidRows,
      duplicateRows: duplicateRows ?? this.duplicateRows,
      previewRows: previewRows ?? this.previewRows,
    );
  }

  @override
  List<Object?> get props => [
    totalRows,
    validRows,
    invalidRows,
    duplicateRows,
    previewRows,
  ];
}
