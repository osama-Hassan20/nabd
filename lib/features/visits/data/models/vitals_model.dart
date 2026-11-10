import 'package:equatable/equatable.dart';

abstract class VitalsThresholds {
  static const int minSystolicBp = 60;
  static const int maxSystolicBp = 200;

  static const int minDiastolicBp = 40;
  static const int maxDiastolicBp = 130;

  static const int minHeartRate = 30;
  static const int maxHeartRate = 200;

  static const double minTemperature = 34.0;
  static const double maxTemperature = 42.0;

  static const int minOxygenSaturation = 90;
  static const int maxOxygenSaturation = 100;

  static const double minWeightKg = 1.0;
  static const double maxWeightKg = 300.0;

  static const double minHeightCm = 30.0;
  static const double maxHeightCm = 250.0;
}

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

  String? get systolicBpWarning {
    if (systolicBp == null) return null;
    if (systolicBp! < VitalsThresholds.minSystolicBp) {
      return 'visits_vitals_warn_bp_low';
    }
    if (systolicBp! > VitalsThresholds.maxSystolicBp) {
      return 'visits_vitals_warn_bp_high';
    }
    return null;
  }

  String? get diastolicBpWarning {
    if (diastolicBp == null) return null;
    if (diastolicBp! < VitalsThresholds.minDiastolicBp) {
      return 'visits_vitals_warn_bp_low';
    }
    if (diastolicBp! > VitalsThresholds.maxDiastolicBp) {
      return 'visits_vitals_warn_bp_high';
    }
    return null;
  }

  String? get heartRateWarning {
    if (heartRate == null) return null;
    if (heartRate! < VitalsThresholds.minHeartRate) {
      return 'visits_vitals_warn_hr_low';
    }
    if (heartRate! > VitalsThresholds.maxHeartRate) {
      return 'visits_vitals_warn_hr_high';
    }
    return null;
  }

  String? get temperatureWarning {
    if (temperature == null) return null;
    if (temperature! < VitalsThresholds.minTemperature) {
      return 'visits_vitals_warn_temp_low';
    }
    if (temperature! > VitalsThresholds.maxTemperature) {
      return 'visits_vitals_warn_temp_high';
    }
    return null;
  }

  String? get oxygenSaturationWarning {
    if (oxygenSaturation == null) return null;
    if (oxygenSaturation! < VitalsThresholds.minOxygenSaturation) {
      return 'visits_vitals_warn_spo2_low';
    }
    if (oxygenSaturation! > VitalsThresholds.maxOxygenSaturation) {
      return 'visits_vitals_warn_spo2_high';
    }
    return null;
  }

  String? get weightWarning {
    if (weightKg == null) return null;
    if (weightKg! < VitalsThresholds.minWeightKg) {
      return 'visits_vitals_warn_weight_low';
    }
    if (weightKg! > VitalsThresholds.maxWeightKg) {
      return 'visits_vitals_warn_weight_high';
    }
    return null;
  }

  String? get heightWarning {
    if (heightCm == null) return null;
    if (heightCm! < VitalsThresholds.minHeightCm) {
      return 'visits_vitals_warn_height_low';
    }
    if (heightCm! > VitalsThresholds.maxHeightCm) {
      return 'visits_vitals_warn_height_high';
    }
    return null;
  }

  bool get hasAnyWarning =>
      systolicBpWarning != null ||
      diastolicBpWarning != null ||
      heartRateWarning != null ||
      temperatureWarning != null ||
      oxygenSaturationWarning != null ||
      weightWarning != null ||
      heightWarning != null;

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
