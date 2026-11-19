import 'package:equatable/equatable.dart';

class TreatmentSessionRecordModel extends Equatable {
  final String id;
  final int sessionNumber;
  final DateTime date;
  final String doctorNotes;
  final String performedBy;

  const TreatmentSessionRecordModel({
    required this.id,
    required this.sessionNumber,
    required this.date,
    required this.doctorNotes,
    required this.performedBy,
  });

  factory TreatmentSessionRecordModel.fromJson(Map<String, dynamic> json) {
    return TreatmentSessionRecordModel(
      id: json['id']?.toString() ?? '',
      sessionNumber: (json['sessionNumber'] as num?)?.toInt() ?? 1,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      doctorNotes: json['doctorNotes'] as String? ?? '',
      performedBy: json['performedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionNumber': sessionNumber,
      'date': date.toIso8601String(),
      'doctorNotes': doctorNotes,
      'performedBy': performedBy,
    };
  }

  @override
  List<Object?> get props => [id, sessionNumber, date, doctorNotes, performedBy];
}

class TreatmentPaymentRecordModel extends Equatable {
  final String id;
  final num amount;
  final DateTime date;
  final String paymentMethod; // نقدي، بطاقة بنكية، إنستاباي، فودافون كاش
  final String notes;

  const TreatmentPaymentRecordModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.notes = '',
  });

  factory TreatmentPaymentRecordModel.fromJson(Map<String, dynamic> json) {
    return TreatmentPaymentRecordModel(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?) ?? 0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      paymentMethod: json['paymentMethod'] as String? ?? 'نقدي',
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, amount, date, paymentMethod, notes];
}

class PatientTreatmentPlanModel extends Equatable {
  final String id;
  final String patientId;
  final String? serviceId;
  final String serviceName;
  final String category; // 'جلدية وليزر', 'طب الأسنان', 'علاج طبيعي', 'جراحة وباطنة'
  final String doctorName;
  final num totalAgreedPrice; // قابلة للتعديل والزيادة من الطبيب حسب الإجراء الإضافي
  final num totalPaidAmount;
  final int totalSessions;
  final int completedSessions;
  final String paymentMode; // 'flexibleInstallments', 'perSession', 'upfront'
  final String status; // 'active', 'completed', 'cancelled'
  final DateTime startDate;
  final String notes;
  final List<TreatmentSessionRecordModel> sessions;
  final List<TreatmentPaymentRecordModel> payments;

  const PatientTreatmentPlanModel({
    required this.id,
    required this.patientId,
    this.serviceId,
    required this.serviceName,
    this.category = 'عام',
    required this.doctorName,
    required this.totalAgreedPrice,
    this.totalPaidAmount = 0,
    required this.totalSessions,
    this.completedSessions = 0,
    this.paymentMode = 'flexibleInstallments',
    this.status = 'active',
    required this.startDate,
    this.notes = '',
    this.sessions = const [],
    this.payments = const [],
  });

  num get remainingBalance {
    final rem = totalAgreedPrice - totalPaidAmount;
    return rem < 0 ? 0 : rem;
  }

  int get remainingSessions {
    final rem = totalSessions - completedSessions;
    return rem < 0 ? 0 : rem;
  }

  double get progressRatio {
    if (totalSessions <= 0) return 1.0;
    return (completedSessions / totalSessions).clamp(0.0, 1.0);
  }

  bool get isPaidInFull => remainingBalance <= 0;
  bool get isCompleted => status == 'completed' || (totalSessions > 0 && completedSessions >= totalSessions);

  factory PatientTreatmentPlanModel.fromJson(Map<String, dynamic> json) {
    return PatientTreatmentPlanModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      serviceId: json['serviceId']?.toString(),
      serviceName: json['serviceName'] as String? ?? '',
      category: json['category'] as String? ?? 'عام',
      doctorName: json['doctorName'] as String? ?? '',
      totalAgreedPrice: (json['totalAgreedPrice'] as num?) ?? 0,
      totalPaidAmount: (json['totalPaidAmount'] as num?) ?? 0,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 1,
      completedSessions: (json['completedSessions'] as num?)?.toInt() ?? 0,
      paymentMode: json['paymentMode'] as String? ?? 'flexibleInstallments',
      status: json['status'] as String? ?? 'active',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] as String? ?? '',
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((e) => TreatmentSessionRecordModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => TreatmentPaymentRecordModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      if (serviceId != null) 'serviceId': serviceId,
      'serviceName': serviceName,
      'category': category,
      'doctorName': doctorName,
      'totalAgreedPrice': totalAgreedPrice,
      'totalPaidAmount': totalPaidAmount,
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'paymentMode': paymentMode,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'notes': notes,
      'sessions': sessions.map((e) => e.toJson()).toList(),
      'payments': payments.map((e) => e.toJson()).toList(),
    };
  }

  PatientTreatmentPlanModel copyWith({
    String? id,
    String? patientId,
    String? serviceId,
    String? serviceName,
    String? category,
    String? doctorName,
    num? totalAgreedPrice,
    num? totalPaidAmount,
    int? totalSessions,
    int? completedSessions,
    String? paymentMode,
    String? status,
    DateTime? startDate,
    String? notes,
    List<TreatmentSessionRecordModel>? sessions,
    List<TreatmentPaymentRecordModel>? payments,
  }) {
    return PatientTreatmentPlanModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      category: category ?? this.category,
      doctorName: doctorName ?? this.doctorName,
      totalAgreedPrice: totalAgreedPrice ?? this.totalAgreedPrice,
      totalPaidAmount: totalPaidAmount ?? this.totalPaidAmount,
      totalSessions: totalSessions ?? this.totalSessions,
      completedSessions: completedSessions ?? this.completedSessions,
      paymentMode: paymentMode ?? this.paymentMode,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      notes: notes ?? this.notes,
      sessions: sessions ?? this.sessions,
      payments: payments ?? this.payments,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patientId,
        serviceId,
        serviceName,
        category,
        doctorName,
        totalAgreedPrice,
        totalPaidAmount,
        totalSessions,
        completedSessions,
        paymentMode,
        status,
        startDate,
        notes,
        sessions,
        payments,
      ];
}
