import 'package:equatable/equatable.dart';

class PrescriptionTemplateItemModel extends Equatable {
  final String? drugId;
  final String? drugName;
  final String? scientificName;
  final String? concentration;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? instructions;
  final int? orderIndex;

  const PrescriptionTemplateItemModel({
    this.drugId,
    this.drugName,
    this.scientificName,
    this.concentration,
    this.dosage,
    this.frequency,
    this.duration,
    this.instructions,
    this.orderIndex,
  });

  factory PrescriptionTemplateItemModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PrescriptionTemplateItemModel();
    return PrescriptionTemplateItemModel(
      drugId: json['drugId']?.toString(),
      drugName: json['drugName'] as String?,
      scientificName: json['scientificName'] as String?,
      concentration: json['concentration'] as String?,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      duration: json['duration'] as String?,
      instructions: json['instructions'] as String?,
      orderIndex: json['orderIndex'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (drugId != null) 'drugId': drugId,
      if (drugName != null) 'drugName': drugName,
      if (scientificName != null) 'scientificName': scientificName,
      if (concentration != null) 'concentration': concentration,
      if (dosage != null) 'dosage': dosage,
      if (frequency != null) 'frequency': frequency,
      if (duration != null) 'duration': duration,
      if (instructions != null) 'instructions': instructions,
      if (orderIndex != null) 'orderIndex': orderIndex,
    };
  }

  PrescriptionTemplateItemModel copyWith({
    String? drugId,
    String? drugName,
    String? scientificName,
    String? concentration,
    String? dosage,
    String? frequency,
    String? duration,
    String? instructions,
    int? orderIndex,
  }) {
    return PrescriptionTemplateItemModel(
      drugId: drugId ?? this.drugId,
      drugName: drugName ?? this.drugName,
      scientificName: scientificName ?? this.scientificName,
      concentration: concentration ?? this.concentration,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  List<Object?> get props => [
        drugId,
        drugName,
        scientificName,
        concentration,
        dosage,
        frequency,
        duration,
        instructions,
        orderIndex,
      ];
}

