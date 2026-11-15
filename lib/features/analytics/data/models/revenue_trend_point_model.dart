import 'package:equatable/equatable.dart';

class RevenueTrendPointModel extends Equatable {
  final String? label;
  final DateTime? date;
  final int? revenuePiastres;
  final int? visitsCount;
  final int? doctorSharePiastres;
  final int? netProfitPiastres;

  const RevenueTrendPointModel({
    this.label,
    this.date,
    this.revenuePiastres,
    this.visitsCount,
    this.doctorSharePiastres,
    this.netProfitPiastres,
  });

  RevenueTrendPointModel copyWith({
    String? label,
    DateTime? date,
    int? revenuePiastres,
    int? visitsCount,
    int? doctorSharePiastres,
    int? netProfitPiastres,
  }) {
    return RevenueTrendPointModel(
      label: label ?? this.label,
      date: date ?? this.date,
      revenuePiastres: revenuePiastres ?? this.revenuePiastres,
      visitsCount: visitsCount ?? this.visitsCount,
      doctorSharePiastres: doctorSharePiastres ?? this.doctorSharePiastres,
      netProfitPiastres: netProfitPiastres ?? this.netProfitPiastres,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'date': date?.toIso8601String(),
      'revenuePiastres': revenuePiastres,
      'visitsCount': visitsCount,
      'doctorSharePiastres': doctorSharePiastres,
      'netProfitPiastres': netProfitPiastres,
    };
  }

  factory RevenueTrendPointModel.fromMap(Map<String, dynamic> map) {
    return RevenueTrendPointModel(
      label: map['label'] as String?,
      date: map['date'] != null ? DateTime.tryParse(map['date'] as String) : null,
      revenuePiastres: (map['revenuePiastres'] as num?)?.toInt(),
      visitsCount: (map['visitsCount'] as num?)?.toInt(),
      doctorSharePiastres: (map['doctorSharePiastres'] as num?)?.toInt(),
      netProfitPiastres: (map['netProfitPiastres'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [
        label,
        date,
        revenuePiastres,
        visitsCount,
        doctorSharePiastres,
        netProfitPiastres,
      ];
}
