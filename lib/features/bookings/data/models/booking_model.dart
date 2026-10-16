import 'package:eyadty/features/customers/data/models/customer_model.dart';
import 'package:eyadty/features/technicians/data/models/technician_model.dart';
import 'enums/booking_status_enum.dart';
import 'enums/booking_type_enum.dart';
import 'enums/payment_status_enum.dart';
import 'recurrence_rule_model.dart';

class BookingModel {
  final String? id;
  final int? queueNumber;
  final String? patientId;
  final String? patientName;
  final String? patientPhone;
  final String? fileNumber;
  final String? doctorId;
  final String? doctorName;
  final String? clinicRoom;
  final String? specialty;
  final BookingTypeEnum? visitType;
  final BookingStatusEnum? status;
  final PaymentStatusEnum? paymentStatus;
  final num? consultationFee;
  final num? paidAmount;
  final DateTime? appointmentTime;
  final DateTime? arrivalTime;
  final DateTime? consultationStartTime;
  final int? estimatedWaitMinutes;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RecurrenceRuleModel? recurrence;
  final num? hourlyRate;
  final int? durationMinutes;

  // Embedded legacy models & legacy parameters
  final CustomerModel? customer;
  final List<TechnicianModel> technicians;
  final String? serviceName;
  final BookingTypeEnum? bookingType;
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final num? totalPrice;
  final List<String> technicianIds;
  final List<String> technicianNames;
  final String? technicianId;
  final String? technicianName;

  const BookingModel({
    this.id,
    this.queueNumber,
    this.patientId,
    this.patientName,
    this.patientPhone,
    this.fileNumber,
    this.doctorId,
    this.doctorName,
    this.clinicRoom,
    this.specialty,
    this.visitType,
    this.status,
    this.paymentStatus,
    this.consultationFee,
    this.paidAmount,
    this.appointmentTime,
    this.arrivalTime,
    this.consultationStartTime,
    this.estimatedWaitMinutes,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.recurrence,
    this.hourlyRate,
    this.durationMinutes,
    this.customer,
    this.technicians = const [],
    this.serviceName,
    this.bookingType,
    this.date,
    this.startTime,
    this.endTime,
    this.totalPrice,
    this.technicianIds = const [],
    this.technicianNames = const [],
    this.technicianId,
    this.technicianName,
  });

  // ─── Convenience Getters ──────────────────────────────────────────────────
  String? get customerId => patientId ?? customer?.id;
  String? get customerName => patientName ?? customer?.name;
  String? get customerPhone => patientPhone ?? customer?.phone;
  String? get customerAddress => customer?.address;

  factory BookingModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BookingModel();

    CustomerModel? parsedCustomer;
    if (json['customer'] is Map<String, dynamic>) {
      parsedCustomer = CustomerModel.fromJson(json['customer'] as Map<String, dynamic>);
    }

    List<TechnicianModel> parsedTechs = [];
    if (json['technicians'] is List) {
      parsedTechs = (json['technicians'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => TechnicianModel.fromJson(e))
          .toList();
    }

    RecurrenceRuleModel? parsedRecurrence;
    if (json['recurrence'] is Map<String, dynamic>) {
      parsedRecurrence = RecurrenceRuleModel.fromJson(json['recurrence'] as Map<String, dynamic>);
    }

    final pName = json['patientName'] as String? ?? json['customerName'] as String? ?? parsedCustomer?.name;
    final pPhone = json['patientPhone'] as String? ?? json['customerPhone'] as String? ?? parsedCustomer?.phone;
    final dName = json['doctorName'] as String? ?? json['technicianName'] as String?;
    final cFee = json['consultationFee'] as num? ?? json['totalPrice'] as num?;
    final vType = BookingTypeEnum.fromValue(json['visitType']?.toString() ?? json['bookingType']?.toString());
    final parsedDate = json['appointmentTime'] != null
        ? DateTime.tryParse(json['appointmentTime'].toString())
        : (json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null);

    return BookingModel(
      id: json['id']?.toString(),
      queueNumber: json['queueNumber'] is int
          ? json['queueNumber'] as int
          : int.tryParse(json['queueNumber']?.toString() ?? ''),
      patientId: json['patientId']?.toString() ?? json['customerId']?.toString(),
      patientName: pName,
      patientPhone: pPhone,
      fileNumber: json['fileNumber']?.toString(),
      doctorId: json['doctorId']?.toString() ?? json['technicianId']?.toString(),
      doctorName: dName,
      clinicRoom: json['clinicRoom'] as String? ?? 'عيادة 1',
      specialty: json['specialty'] as String? ?? json['serviceName'] as String?,
      visitType: vType,
      status: BookingStatusEnum.fromValue(json['status']?.toString()),
      paymentStatus: PaymentStatusEnum.fromValue(json['paymentStatus']?.toString()),
      consultationFee: cFee,
      paidAmount: json['paidAmount'] as num?,
      appointmentTime: parsedDate,
      arrivalTime: json['arrivalTime'] != null
          ? DateTime.tryParse(json['arrivalTime'].toString())
          : null,
      consultationStartTime: json['consultationStartTime'] != null
          ? DateTime.tryParse(json['consultationStartTime'].toString())
          : null,
      estimatedWaitMinutes: json['estimatedWaitMinutes'] is int
          ? json['estimatedWaitMinutes'] as int
          : int.tryParse(json['estimatedWaitMinutes']?.toString() ?? '15'),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      recurrence: parsedRecurrence,
      hourlyRate: json['hourlyRate'] as num?,
      durationMinutes: json['durationMinutes'] is int
          ? json['durationMinutes'] as int
          : int.tryParse(json['durationMinutes']?.toString() ?? ''),
      customer: parsedCustomer,
      technicians: parsedTechs,
      serviceName: json['serviceName'] as String? ?? json['specialty'] as String?,
      bookingType: vType,
      date: parsedDate,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      totalPrice: cFee,
      technicianIds: (json['technicianIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      technicianNames: (json['technicianNames'] as List?)?.map((e) => e.toString()).toList() ?? [],
      technicianId: json['technicianId']?.toString() ?? json['doctorId']?.toString(),
      technicianName: dName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (queueNumber != null) 'queueNumber': queueNumber,
      if (patientId != null) 'patientId': patientId,
      if (patientName != null) 'patientName': patientName,
      if (patientPhone != null) 'patientPhone': patientPhone,
      if (fileNumber != null) 'fileNumber': fileNumber,
      if (doctorId != null) 'doctorId': doctorId,
      if (doctorName != null) 'doctorName': doctorName,
      if (clinicRoom != null) 'clinicRoom': clinicRoom,
      if (specialty != null) 'specialty': specialty,
      if (visitType != null) 'visitType': visitType?.value,
      if (status != null) 'status': status?.value,
      if (paymentStatus != null) 'paymentStatus': paymentStatus?.value,
      if (consultationFee != null) 'consultationFee': consultationFee,
      if (paidAmount != null) 'paidAmount': paidAmount,
      if (appointmentTime != null) 'appointmentTime': appointmentTime?.toIso8601String(),
      if (arrivalTime != null) 'arrivalTime': arrivalTime?.toIso8601String(),
      if (consultationStartTime != null) 'consultationStartTime': consultationStartTime?.toIso8601String(),
      if (estimatedWaitMinutes != null) 'estimatedWaitMinutes': estimatedWaitMinutes,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
      if (recurrence != null) 'recurrence': recurrence?.toJson(),
      if (hourlyRate != null) 'hourlyRate': hourlyRate,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (serviceName != null) 'serviceName': serviceName,
      if (bookingType != null) 'bookingType': bookingType?.value,
      if (date != null) 'date': date?.toIso8601String(),
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (totalPrice != null) 'totalPrice': totalPrice,
      if (technicianIds.isNotEmpty) 'technicianIds': technicianIds,
      if (technicianNames.isNotEmpty) 'technicianNames': technicianNames,
      if (technicianId != null) 'technicianId': technicianId,
      if (technicianName != null) 'technicianName': technicianName,
    };
  }

  BookingModel copyWith({
    String? id,
    int? queueNumber,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? fileNumber,
    String? doctorId,
    String? doctorName,
    String? clinicRoom,
    String? specialty,
    BookingTypeEnum? visitType,
    BookingStatusEnum? status,
    PaymentStatusEnum? paymentStatus,
    num? consultationFee,
    num? paidAmount,
    DateTime? appointmentTime,
    DateTime? arrivalTime,
    DateTime? consultationStartTime,
    int? estimatedWaitMinutes,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    RecurrenceRuleModel? recurrence,
    num? hourlyRate,
    int? durationMinutes,
    CustomerModel? customer,
    List<TechnicianModel>? technicians,
    String? serviceName,
    BookingTypeEnum? bookingType,
    DateTime? date,
    String? startTime,
    String? endTime,
    num? totalPrice,
    List<String>? technicianIds,
    List<String>? technicianNames,
    String? technicianId,
    String? technicianName,
  }) {
    return BookingModel(
      id: id ?? this.id,
      queueNumber: queueNumber ?? this.queueNumber,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      fileNumber: fileNumber ?? this.fileNumber,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      clinicRoom: clinicRoom ?? this.clinicRoom,
      specialty: specialty ?? this.specialty,
      visitType: visitType ?? this.visitType,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      consultationFee: consultationFee ?? this.consultationFee,
      paidAmount: paidAmount ?? this.paidAmount,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      consultationStartTime: consultationStartTime ?? this.consultationStartTime,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recurrence: recurrence ?? this.recurrence,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      customer: customer ?? this.customer,
      technicians: technicians ?? this.technicians,
      serviceName: serviceName ?? this.serviceName,
      bookingType: bookingType ?? this.bookingType,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalPrice: totalPrice ?? this.totalPrice,
      technicianIds: technicianIds ?? this.technicianIds,
      technicianNames: technicianNames ?? this.technicianNames,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
    );
  }
}
