import 'package:equatable/equatable.dart';

class VitalsModel extends Equatable {
  final int? systolicBp;
  final int? diastolicBp;
  final int? heartRate;
  final double? temperature;
  final int? oxygenSaturation;
  final double? weightKg;
  final double? heightCm;
  final DateTime? recordedAt;
  final String? recordedByUserId;

  const VitalsModel({
    this.systolicBp,
    this.diastolicBp,
    this.heartRate,
    this.temperature,
    this.oxygenSaturation,
    this.weightKg,
    this.heightCm,
    this.recordedAt,
    this.recordedByUserId,
  });

  double? get bmi {
    if (weightKg != null && heightCm != null && heightCm! > 0) {
      final hM = heightCm! / 100.0;
      final rawBmi = weightKg! / (hM * hM);
      return double.parse(rawBmi.toStringAsFixed(1));
    }
    return null;
  }

  bool get systolicBpWarning =>
      systolicBp != null && (systolicBp! > 140 || systolicBp! < 90);

  bool get diastolicBpWarning =>
      diastolicBp != null && (diastolicBp! > 90 || diastolicBp! < 60);

  bool get heartRateWarning =>
      heartRate != null && (heartRate! > 100 || heartRate! < 60);

  bool get temperatureWarning =>
      temperature != null && (temperature! > 38.0 || temperature! < 36.0);

  bool get oxygenSaturationWarning =>
      oxygenSaturation != null && oxygenSaturation! < 95;

  bool get hasAnyWarning =>
      systolicBpWarning ||
      diastolicBpWarning ||
      heartRateWarning ||
      temperatureWarning ||
      oxygenSaturationWarning;

  factory VitalsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VitalsModel();
    return VitalsModel(
      systolicBp: json['systolicBp'] as int?,
      diastolicBp: json['diastolicBp'] as int?,
      heartRate: json['heartRate'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      oxygenSaturation: json['oxygenSaturation'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'] as String)
          : null,
      recordedByUserId: json['recordedByUserId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'systolicBp': systolicBp,
      'diastolicBp': diastolicBp,
      'heartRate': heartRate,
      'temperature': temperature,
      'oxygenSaturation': oxygenSaturation,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'recordedAt': recordedAt?.toIso8601String(),
      'recordedByUserId': recordedByUserId,
    };
  }

  VitalsModel copyWith({
    int? systolicBp,
    int? diastolicBp,
    int? heartRate,
    double? temperature,
    int? oxygenSaturation,
    double? weightKg,
    double? heightCm,
    DateTime? recordedAt,
    String? recordedByUserId,
  }) {
    return VitalsModel(
      systolicBp: systolicBp ?? this.systolicBp,
      diastolicBp: diastolicBp ?? this.diastolicBp,
      heartRate: heartRate ?? this.heartRate,
      temperature: temperature ?? this.temperature,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      recordedAt: recordedAt ?? this.recordedAt,
      recordedByUserId: recordedByUserId ?? this.recordedByUserId,
    );
  }

  @override
  List<Object?> get props => [
        systolicBp,
        diastolicBp,
        heartRate,
        temperature,
        oxygenSaturation,
        weightKg,
        heightCm,
        recordedAt,
        recordedByUserId,
      ];
}
