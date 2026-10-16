class BookingSummaryModel {
  final int? totalBookings;
  final int? upcomingBookings;
  final int? completedBookings;
  final int? cancelledBookings;

  const BookingSummaryModel({
    this.totalBookings,
    this.upcomingBookings,
    this.completedBookings,
    this.cancelledBookings,
  });

  factory BookingSummaryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BookingSummaryModel();
    return BookingSummaryModel(
      totalBookings: json['totalBookings'] as int?,
      upcomingBookings: json['upcomingBookings'] as int?,
      completedBookings: json['completedBookings'] as int?,
      cancelledBookings: json['cancelledBookings'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (totalBookings != null) 'totalBookings': totalBookings,
      if (upcomingBookings != null) 'upcomingBookings': upcomingBookings,
      if (completedBookings != null) 'completedBookings': completedBookings,
      if (cancelledBookings != null) 'cancelledBookings': cancelledBookings,
    };
  }
}
