import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'enums/booking_status_enum.dart';
import 'enums/booking_type_enum.dart';
import 'enums/discount_type_enum.dart';
import 'enums/payment_status_enum.dart';

typedef CustomerModel = PatientModel;
typedef TechnicianModel = DoctorModel;

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
  final MedicalSpecialty? specialtyCode;
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
  final int? durationMinutes;

  // Multi-branch & cancellation / postponement fields
  final String? branchId;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final String? cancelledBy; // 'patient' or 'clinic'
  final DateTime? originalAppointmentTime;
  final DateTime? rescheduledTo;
  final DateTime? postponedAt;
  final String? postponeReason;

  // Embedded models & legacy parameters
  final PatientModel? patient;
  final CustomerModel? customer;
  final List<TechnicianModel> technicians;
  final String? serviceId;
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

  // Discount fields (all nullable)
  final DiscountTypeEnum? discountType;
  final num? discountValue;
  final String? discountReason;
  final String? discountApprovedByUserId;
  final DateTime? discountApprovedAt;
  final String? discountRemovedReason;

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
    this.specialtyCode,
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
    this.durationMinutes,
    this.branchId = 'branch_1',
    this.cancelReason,
    this.cancelledAt,
    this.cancelledBy,
    this.originalAppointmentTime,
    this.rescheduledTo,
    this.postponedAt,
    this.postponeReason,
    this.patient,
    this.customer,
    this.technicians = const [],
    this.serviceId,
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
    this.discountType,
    this.discountValue,
    this.discountReason,
    this.discountApprovedByUserId,
    this.discountApprovedAt,
    this.discountRemovedReason,
  });

  // ─── Convenience Getters ──────────────────────────────────────────────────
  String? get customerId => patientId ?? patient?.id ?? customer?.id;
  String? get customerName => patientName ?? patient?.name ?? customer?.name;
  String? get customerPhone => patientPhone ?? patient?.phone ?? customer?.phone;
  String? get customerAddress => patient?.address ?? customer?.address;
  String? get patientAddress => patient?.address ?? customer?.address;

  // ─── Computed Getters (Discount & Effective Payment) ──────────────────────
  num get discountAmount {
    final fee = consultationFee ?? 0;
    final type = discountType ?? DiscountTypeEnum.none;
    if (type == DiscountTypeEnum.none) return 0;
    if (type == DiscountTypeEnum.free) return fee;
    if (type == DiscountTypeEnum.percentage) {
      final pct = (discountValue ?? 0).clamp(0, 100);
      return (fee * pct / 100);
    }
    if (type == DiscountTypeEnum.fixedAmount) {
      return (discountValue ?? 0).clamp(0, fee);
    }
    return 0;
  }

  num get netAmount =>
      ((consultationFee ?? 0) - discountAmount).clamp(0, double.infinity);

  bool get isFreeConsultation {
    final type = discountType ?? DiscountTypeEnum.none;
    if (type == DiscountTypeEnum.free) {
      return true;
    }
    if (type == DiscountTypeEnum.percentage && (discountValue ?? 0) >= 100) {
      return true;
    }
    if (type == DiscountTypeEnum.fixedAmount &&
        (discountValue ?? 0) >= (consultationFee ?? 0) &&
        (consultationFee ?? 0) > 0) {
      return true;
    }
    return false;
  }

  PaymentStatusEnum get effectivePaymentStatus {
    if (isFreeConsultation && netAmount <= 0) {
      return PaymentStatusEnum.paid;
    }
    return paymentStatus ?? PaymentStatusEnum.unpaid;
  }

  factory BookingModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BookingModel();

    PatientModel? parsedPatient;
    if (json['patient'] is Map<String, dynamic>) {
      parsedPatient =
          PatientModel.fromJson(json['patient'] as Map<String, dynamic>);
    } else if (json['customer'] is Map<String, dynamic>) {
      parsedPatient =
          PatientModel.fromJson(json['customer'] as Map<String, dynamic>);
    }

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

    final pName = json['patientName'] as String? ?? json['customerName'] as String? ?? parsedPatient?.name ?? parsedCustomer?.name;
    final pPhone = json['patientPhone'] as String? ?? json['customerPhone'] as String? ?? parsedPatient?.phone ?? parsedCustomer?.phone;
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
      specialtyCode: json['specialtyCode'] != null
          ? MedicalSpecialty.fromValue(json['specialtyCode']?.toString())
          : (json['specialty'] != null
              ? MedicalSpecialty.fromValue(json['specialty']?.toString())
              : null),
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
      durationMinutes: json['durationMinutes'] is int
          ? json['durationMinutes'] as int
          : int.tryParse(json['durationMinutes']?.toString() ?? ''),
      branchId: json['branchId']?.toString() ?? 'branch_1',
      cancelReason: json['cancelReason'] as String?,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'].toString())
          : null,
      cancelledBy: json['cancelledBy'] as String?,
      originalAppointmentTime: json['originalAppointmentTime'] != null
          ? DateTime.tryParse(json['originalAppointmentTime'].toString())
          : null,
      rescheduledTo: json['rescheduledTo'] != null
          ? DateTime.tryParse(json['rescheduledTo'].toString())
          : null,
      postponedAt: json['postponedAt'] != null
          ? DateTime.tryParse(json['postponedAt'].toString())
          : null,
      postponeReason: json['postponeReason'] as String?,
      patient: parsedPatient,
      customer: parsedCustomer,
      technicians: parsedTechs,
      serviceId: json['serviceId']?.toString(),
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
      discountType: DiscountTypeEnum.fromValue(json['discountType']?.toString()),
      discountValue: json['discountValue'] as num?,
      discountReason: json['discountReason'] as String?,
      discountApprovedByUserId: json['discountApprovedByUserId'] as String?,
      discountApprovedAt: json['discountApprovedAt'] != null
          ? DateTime.tryParse(json['discountApprovedAt'].toString())
          : null,
      discountRemovedReason: json['discountRemovedReason'] as String?,
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
      if (specialtyCode != null) 'specialtyCode': specialtyCode?.value,
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
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (branchId != null) 'branchId': branchId,
      if (cancelReason != null) 'cancelReason': cancelReason,
      if (cancelledAt != null) 'cancelledAt': cancelledAt?.toIso8601String(),
      if (cancelledBy != null) 'cancelledBy': cancelledBy,
      if (originalAppointmentTime != null)
        'originalAppointmentTime': originalAppointmentTime?.toIso8601String(),
      if (rescheduledTo != null)
        'rescheduledTo': rescheduledTo?.toIso8601String(),
      if (postponedAt != null)
        'postponedAt': postponedAt?.toIso8601String(),
      if (postponeReason != null) 'postponeReason': postponeReason,
      if (serviceId != null) 'serviceId': serviceId,
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
      if (patient != null) 'patient': patient?.toJson(),
      if (discountType != null) 'discountType': discountType?.value,
      if (discountValue != null) 'discountValue': discountValue,
      if (discountReason != null) 'discountReason': discountReason,
      if (discountApprovedByUserId != null)
        'discountApprovedByUserId': discountApprovedByUserId,
      if (discountApprovedAt != null)
        'discountApprovedAt': discountApprovedAt?.toIso8601String(),
      if (discountRemovedReason != null)
        'discountRemovedReason': discountRemovedReason,
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
    MedicalSpecialty? specialtyCode,
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
    int? durationMinutes,
    String? branchId,
    String? cancelReason,
    DateTime? cancelledAt,
    String? cancelledBy,
    DateTime? originalAppointmentTime,
    DateTime? rescheduledTo,
    DateTime? postponedAt,
    String? postponeReason,
    PatientModel? patient,
    CustomerModel? customer,
    List<TechnicianModel>? technicians,
    String? serviceId,
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
    DiscountTypeEnum? discountType,
    num? discountValue,
    String? discountReason,
    bool clearDiscountReason = false,
    String? discountApprovedByUserId,
    DateTime? discountApprovedAt,
    String? discountRemovedReason,
    bool clearDiscountRemovedReason = false,
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
      specialtyCode: specialtyCode ?? this.specialtyCode,
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
      durationMinutes: durationMinutes ?? this.durationMinutes,
      branchId: branchId ?? this.branchId,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      originalAppointmentTime:
          originalAppointmentTime ?? this.originalAppointmentTime,
      rescheduledTo: rescheduledTo ?? this.rescheduledTo,
      postponedAt: postponedAt ?? this.postponedAt,
      postponeReason: postponeReason ?? this.postponeReason,
      patient: patient ?? this.patient,
      customer: customer ?? this.customer,
      technicians: technicians ?? this.technicians,
      serviceId: serviceId ?? this.serviceId,
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
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountReason: clearDiscountReason
          ? null
          : (discountReason ?? this.discountReason),
      discountApprovedByUserId:
          discountApprovedByUserId ?? this.discountApprovedByUserId,
      discountApprovedAt: discountApprovedAt ?? this.discountApprovedAt,
      discountRemovedReason: clearDiscountRemovedReason
          ? null
          : (discountRemovedReason ?? this.discountRemovedReason),
    );
  }
}
