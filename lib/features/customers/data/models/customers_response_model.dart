import 'customer_model.dart';

class CustomersResponseModel {
  final List<CustomerModel> items;
  final int totalCount;
  final int totalPages;
  final int currentPage;

  const CustomersResponseModel({
    this.items = const [],
    this.totalCount = 0,
    this.totalPages = 1,
    this.currentPage = 1,
  });

  factory CustomersResponseModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CustomersResponseModel();

    final rawList = json['data'] as List<dynamic>? ??
        json['items'] as List<dynamic>? ??
        const [];

    final items = rawList
        .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>?))
        .toList();

    return CustomersResponseModel(
      items: items,
      totalCount: json['totalCount'] as int? ?? items.length,
      totalPages: json['totalPages'] as int? ?? 1,
      currentPage: json['currentPage'] as int? ?? 1,
    );
  }
}
