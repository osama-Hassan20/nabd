import 'package:equatable/equatable.dart';

class PrescriptionItemModel extends Equatable {
  final String? id;
  final String? drugId;
  final String? tradeName;
  final String? scientificName;
  final String? concentration;
  final String? dosage;
  final String? frequency;
  final String? frequencyPreset;
  final String? frequencyCustom;
  final String? duration;
  final String? durationPreset;
  final String? durationCustom;
  final String? instructions;
  final int? orderIndex;
  final DateTime? createdAt;

  const PrescriptionItemModel({
    this.id,
    this.drugId,
    this.tradeName,
    this.scientificName,
    this.concentration,
    this.dosage,
    this.frequency,
    this.frequencyPreset,
    this.frequencyCustom,
    this.duration,
    this.durationPreset,
    this.durationCustom,
    this.instructions,
    this.orderIndex,
    this.createdAt,
  });

  factory PrescriptionItemModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PrescriptionItemModel();
    return PrescriptionItemModel(
      id: json['id'] as String?,
      drugId: json['drugId'] as String?,
      tradeName: json['tradeName'] as String?,
      scientificName: json['scientificName'] as String?,
      concentration: json['concentration'] as String?,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      frequencyPreset: json['frequencyPreset'] as String?,
      frequencyCustom: json['frequencyCustom'] as String?,
      duration: json['duration'] as String?,
      durationPreset: json['durationPreset'] as String?,
      durationCustom: json['durationCustom'] as String?,
      instructions: json['instructions'] as String?,
      orderIndex: json['orderIndex'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'drugId': drugId,
      'tradeName': tradeName,
      'scientificName': scientificName,
      'concentration': concentration,
      'dosage': dosage,
      'frequency': frequency,
      'frequencyPreset': frequencyPreset,
      'frequencyCustom': frequencyCustom,
      'duration': duration,
      'durationPreset': durationPreset,
      'durationCustom': durationCustom,
      'instructions': instructions,
      'orderIndex': orderIndex,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  PrescriptionItemModel copyWith({
    String? id,
    String? drugId,
    String? tradeName,
    String? scientificName,
    String? concentration,
    String? dosage,
    String? frequency,
    String? frequencyPreset,
    String? frequencyCustom,
    String? duration,
    String? durationPreset,
    String? durationCustom,
    String? instructions,
    int? orderIndex,
    DateTime? createdAt,
  }) {
    return PrescriptionItemModel(
      id: id ?? this.id,
      drugId: drugId ?? this.drugId,
      tradeName: tradeName ?? this.tradeName,
      scientificName: scientificName ?? this.scientificName,
      concentration: concentration ?? this.concentration,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      frequencyPreset: frequencyPreset ?? this.frequencyPreset,
      frequencyCustom: frequencyCustom ?? this.frequencyCustom,
      duration: duration ?? this.duration,
      durationPreset: durationPreset ?? this.durationPreset,
      durationCustom: durationCustom ?? this.durationCustom,
      instructions: instructions ?? this.instructions,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        drugId,
        tradeName,
        scientificName,
        concentration,
        dosage,
        frequency,
        frequencyPreset,
        frequencyCustom,
        duration,
        durationPreset,
        durationCustom,
        instructions,
        orderIndex,
        createdAt,
      ];
}

