import 'package:equatable/equatable.dart';

class SettlementPaymentEvent extends Equatable {
  final String eventId;
  final String transactionId;
  final String type; // 'payment' or 'refund'
  final int amountPiastres;
  final DateTime date;

  const SettlementPaymentEvent({
    required this.eventId,
    this.transactionId = '',
    required this.type,
    required this.amountPiastres,
    required this.date,
  });

  @override
  List<Object?> get props => [
    eventId,
    transactionId,
    type,
    amountPiastres,
    date,
  ];
}

class SettlementVisitCandidate extends Equatable {
  final String visitId;
  final String bookingId;
  final String doctorId;
  final String branchId;
  final DateTime finalizedAt;
  final String patientId;
  final String patientName;
  final String serviceName;
  final int grossFeePiastres;
  final int discountAmountPiastres;
  final int netAmountPiastres;
  final bool isFreeConsultation;
  final List<SettlementPaymentEvent> events;

  const SettlementVisitCandidate({
    required this.visitId,
    this.bookingId = '',
    this.doctorId = '',
    this.branchId = 'branch_1',
    required this.finalizedAt,
    this.patientId = '',
    this.patientName = '',
    this.serviceName = 'كشف عام',
    this.grossFeePiastres = 0,
    this.discountAmountPiastres = 0,
    required this.netAmountPiastres,
    this.isFreeConsultation = false,
    this.events = const [],
  });

  @override
  List<Object?> get props => [
    visitId,
    bookingId,
    doctorId,
    branchId,
    finalizedAt,
    patientId,
    patientName,
    serviceName,
    grossFeePiastres,
    discountAmountPiastres,
    netAmountPiastres,
    isFreeConsultation,
    events,
  ];
}

abstract class DoctorSettlementVisitsLookup {
  /// Retrieves visits candidates with their payment/refund events within a period for a doctor and branch.
  Future<List<SettlementVisitCandidate>> getSettlementVisitCandidates({
    required String doctorId,
    required String branchId,
    required DateTime periodStart,
    required DateTime periodEnd,
    List<String> excludedEventIds = const [],
  });
}
