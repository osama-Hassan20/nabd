import 'doctor_model.dart';

class DoctorsResponseModel {
  final List<DoctorModel>? items;
  final int? totalCount;
  final int? totalPages;
  final int? currentPage;

  List<DoctorModel> get doctors => items ?? const [];

  const DoctorsResponseModel({
    this.items,
    this.totalCount,
    this.totalPages,
    this.currentPage,
  });

  factory DoctorsResponseModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DoctorsResponseModel();

    final rawList = json['data'] as List<dynamic>? ??
        json['items'] as List<dynamic>? ??
        const [];

    final items = rawList
        .map((e) => DoctorModel.fromJson(e as Map<String, dynamic>?))
        .toList();

    return DoctorsResponseModel(
      items: items,
      totalCount: json['totalCount'] as int? ?? items.length,
      totalPages: json['totalPages'] as int? ?? 1,
      currentPage: json['currentPage'] as int? ?? 1,
    );
  }
}

