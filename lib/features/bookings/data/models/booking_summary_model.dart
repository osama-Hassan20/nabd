class BookingSummaryModel {
  final int? totalBookings;
  final int? upcomingBookings;
  final int? completedBookings;
  final int? cancelledBookings;
  final int? inWaitingCount;
  final int? inConsultationCount;
  final int? noShowCount;
  final int? postponedCount;

  const BookingSummaryModel({
    this.totalBookings,
    this.upcomingBookings,
    this.completedBookings,
    this.cancelledBookings,
    this.inWaitingCount,
    this.inConsultationCount,
    this.noShowCount,
    this.postponedCount,
  });

  int get visitsToday => totalBookings ?? 0;
  int get inWaiting => inWaitingCount ?? upcomingBookings ?? 0;
  int get inConsultation => inConsultationCount ?? 0;
  int get completedToday => completedBookings ?? 0;
  int get noShow => noShowCount ?? 0;
  int get cancelledToday => cancelledBookings ?? 0;
  int get postponedToOther => postponedCount ?? 0;

  factory BookingSummaryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BookingSummaryModel();
    return BookingSummaryModel(
      totalBookings: json['totalBookings'] as int?,
      upcomingBookings: json['upcomingBookings'] as int?,
      completedBookings: json['completedBookings'] as int?,
      cancelledBookings: json['cancelledBookings'] as int?,
      inWaitingCount: json['inWaitingCount'] as int?,
      inConsultationCount: json['inConsultationCount'] as int?,
      noShowCount: json['noShowCount'] as int?,
      postponedCount: json['postponedCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (totalBookings != null) 'totalBookings': totalBookings,
      if (upcomingBookings != null) 'upcomingBookings': upcomingBookings,
      if (completedBookings != null) 'completedBookings': completedBookings,
      if (cancelledBookings != null) 'cancelledBookings': cancelledBookings,
      if (inWaitingCount != null) 'inWaitingCount': inWaitingCount,
      if (inConsultationCount != null)
        'inConsultationCount': inConsultationCount,
      if (noShowCount != null) 'noShowCount': noShowCount,
      if (postponedCount != null) 'postponedCount': postponedCount,
    };
  }
}
