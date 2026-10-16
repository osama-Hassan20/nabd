import '../../../../core/uses_cases/params.dart';
import 'booking_model.dart';

class BookingsResponseModel {
  final List<BookingModel>? bookings;
  final PaginationModel? pagination;

  const BookingsResponseModel({
    this.bookings,
    this.pagination,
  });

  factory BookingsResponseModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BookingsResponseModel();
    return BookingsResponseModel(
      bookings: (json['data'] as List<dynamic>?)
          ?.map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] != null
          ? PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (bookings != null) 'data': bookings?.map((e) => e.toJson()).toList(),
      if (pagination != null)
        'pagination': {
          'currentPage': pagination?.page,
          'limit': pagination?.limit,
          'total': pagination?.total,
          'numberOfPages': pagination?.pages,
        },
    };
  }
}
