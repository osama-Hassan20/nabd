import 'package:equatable/equatable.dart';

class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}

class PaginationParams extends Equatable {
  final int? page;
  final int? limit;
  final bool? isActive;
  final List<FilterParam> filterList;
  final List<FilterParam> bodyFilterList;

  // final CancelToken? cancelToken;

  const PaginationParams({
    this.limit = 20,
    this.page = 1,
    this.isActive = true,
    this.filterList = const [],
    this.bodyFilterList = const [],
    // this.cancelToken,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    };

    for (final filter in filterList) {
      filter.isActive && filter.value != null
          ? data[filter.key] = filter.value
          : null;
    }

    return data;
  }

  @override
  List<Object?> get props => [limit, page];
  //copyWith
  PaginationParams copyWith({
    int? page,
    int? limit,
    bool? isActive,
    List<FilterParam>? filterList,
  }) {
    return PaginationParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      isActive: isActive ?? this.isActive,
      filterList: filterList ?? this.filterList,
    );
  }
}

class ToggleTypeParam extends Equatable {
  final String type;
  final String id;

  const ToggleTypeParam({required this.type, required this.id});

  Map<String, dynamic> toJson() {
    return {'type': type, 'id': id};
  }

  @override
  List<Object?> get props => [type, id];
}

class FilterParam extends Equatable {
  final String key;
  final dynamic value;
  final bool isActive;

  const FilterParam({
    required this.key,
    required this.value,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [key, value];
}

class Params extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetAddressFromCoordinatesParams extends Equatable {
  final double latitude;
  final double longitude;

  const GetAddressFromCoordinatesParams(this.latitude, this.longitude);

  @override
  List<Object?> get props => [latitude, longitude];
}

class ReviewPassParam {
  final String id;
  final bool isStore;
  final String? name;
  final String? orderId;

  const ReviewPassParam({
    required this.id,
    required this.isStore,
    this.name,
    this.orderId,
  });
}

class PaginationModel {
  final int? page;
  final int? limit;
  final int? total;
  final int? pages;

  PaginationModel({this.page, this.limit, this.total, this.pages});

  factory PaginationModel.fromJson(Map<String, dynamic> json) =>
      PaginationModel(
        page: json['currentPage'],
        limit: json['limit'],
        total: json['total'],
        pages: json['numberOfPages'],
      );
}

class DateTimeParam {
  final DateTime? time;
  DateTimeParam({this.time});

  factory DateTimeParam.fromJson(dynamic json) {
    return DateTimeParam(
      time: json != null ? DateTime.parse(json).toLocal() : null,
    );
  }
}
