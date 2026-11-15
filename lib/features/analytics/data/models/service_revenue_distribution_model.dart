import 'package:equatable/equatable.dart';

class ServiceRevenueDistributionModel extends Equatable {
  final String? serviceName;
  final String? category;
  final int? count;
  final int? totalRevenuePiastres;
  final double? percentage;

  const ServiceRevenueDistributionModel({
    this.serviceName,
    this.category,
    this.count,
    this.totalRevenuePiastres,
    this.percentage,
  });

  ServiceRevenueDistributionModel copyWith({
    String? serviceName,
    String? category,
    int? count,
    int? totalRevenuePiastres,
    double? percentage,
  }) {
    return ServiceRevenueDistributionModel(
      serviceName: serviceName ?? this.serviceName,
      category: category ?? this.category,
      count: count ?? this.count,
      totalRevenuePiastres: totalRevenuePiastres ?? this.totalRevenuePiastres,
      percentage: percentage ?? this.percentage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceName': serviceName,
      'category': category,
      'count': count,
      'totalRevenuePiastres': totalRevenuePiastres,
      'percentage': percentage,
    };
  }

  factory ServiceRevenueDistributionModel.fromMap(Map<String, dynamic> map) {
    return ServiceRevenueDistributionModel(
      serviceName: map['serviceName'] as String?,
      category: map['category'] as String?,
      count: (map['count'] as num?)?.toInt(),
      totalRevenuePiastres: (map['totalRevenuePiastres'] as num?)?.toInt(),
      percentage: (map['percentage'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        serviceName,
        category,
        count,
        totalRevenuePiastres,
        percentage,
      ];
}
