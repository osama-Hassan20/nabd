class BookingSummaryModel {
  final int? totalBookings;
  final int? upcomingBookings;
  final int? completedBookings;
  final int? cancelledBookings;
  final int? inWaitingCount;
  final int? inConsultationCount;

  const BookingSummaryModel({
    this.totalBookings,
    this.upcomingBookings,
    this.completedBookings,
    this.cancelledBookings,
    this.inWaitingCount,
    this.inConsultationCount,
  });

  int get visitsToday => totalBookings ?? 0;
  int get inWaiting => inWaitingCount ?? upcomingBookings ?? 0;
  int get inConsultation => inConsultationCount ?? 0;
  int get completedToday => completedBookings ?? 0;

  factory BookingSummaryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BookingSummaryModel();
    return BookingSummaryModel(
      totalBookings: json['totalBookings'] as int?,
      upcomingBookings: json['upcomingBookings'] as int?,
      completedBookings: json['completedBookings'] as int?,
      cancelledBookings: json['cancelledBookings'] as int?,
      inWaitingCount: json['inWaitingCount'] as int?,
      inConsultationCount: json['inConsultationCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (totalBookings != null) 'totalBookings': totalBookings,
      if (upcomingBookings != null) 'upcomingBookings': upcomingBookings,
      if (completedBookings != null) 'completedBookings': completedBookings,
      if (cancelledBookings != null) 'cancelledBookings': cancelledBookings,
      if (inWaitingCount != null) 'inWaitingCount': inWaitingCount,
      if (inConsultationCount != null) 'inConsultationCount': inConsultationCount,
    };
  }
}
