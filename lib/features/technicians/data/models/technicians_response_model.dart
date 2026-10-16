import 'technician_model.dart';

class TechniciansResponseModel {
  final List<TechnicianModel> items;
  final int totalCount;
  final int totalPages;
  final int currentPage;

  const TechniciansResponseModel({
    this.items = const [],
    this.totalCount = 0,
    this.totalPages = 1,
    this.currentPage = 1,
  });

  factory TechniciansResponseModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TechniciansResponseModel();

    final rawList = json['data'] as List<dynamic>? ??
        json['items'] as List<dynamic>? ??
        const [];

    final items = rawList
        .map((e) => TechnicianModel.fromJson(e as Map<String, dynamic>?))
        .toList();

    return TechniciansResponseModel(
      items: items,
      totalCount: json['totalCount'] as int? ?? items.length,
      totalPages: json['totalPages'] as int? ?? 1,
      currentPage: json['currentPage'] as int? ?? 1,
    );
  }
}
