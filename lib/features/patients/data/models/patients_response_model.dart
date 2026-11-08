import 'patient_model.dart';

class PatientsResponseModel {
  final List<PatientModel>? items;
  final int? totalCount;
  final int? totalPages;
  final int? currentPage;

  const PatientsResponseModel({
    this.items,
    this.totalCount,
    this.totalPages,
    this.currentPage,
  });

  factory PatientsResponseModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PatientsResponseModel();

    final rawList = json['data'] as List<dynamic>? ??
        json['items'] as List<dynamic>? ??
        const [];

    final items = rawList
        .map((e) => PatientModel.fromJson(e as Map<String, dynamic>?))
        .toList();

    return PatientsResponseModel(
      items: items,
      totalCount: json['totalCount'] as int? ?? items.length,
      totalPages: json['totalPages'] as int? ?? 1,
      currentPage: json['currentPage'] as int? ?? 1,
    );
  }
}

