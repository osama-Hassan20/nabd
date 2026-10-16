import 'package:eyadty/features/customers/data/models/customer_model.dart';
import 'package:eyadty/features/technicians/data/models/technician_model.dart';
import 'enums/booking_status_enum.dart';
import 'enums/booking_type_enum.dart';
import 'enums/payment_status_enum.dart';
import 'recurrence_rule_model.dart';

class BookingModel {
  final String? id;
  final CustomerModel? customer;
  final List<TechnicianModel> technicians;
  final String? serviceName; // Plain text e.g. "تنظيف منازل", "صيانة تكييف"
  final BookingTypeEnum? bookingType;
  final DateTime? date; // Target date
  final RecurrenceRuleModel? recurrence;
  final String? startTime; // e.g. "10:00"
  final String? endTime; // e.g. "13:00"
  final int? durationMinutes;
  final num? hourlyRate;
  final num? totalPrice;
  final BookingStatusEnum? status;
  final PaymentStatusEnum? paymentStatus;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookingModel({
    this.id,
    this.customer,
    this.technicians = const [],
    this.serviceName,
    this.bookingType,
    this.date,
    this.recurrence,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.hourlyRate,
    this.totalPrice,
    this.status,
    this.paymentStatus,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // ─── Convenience Getters ──────────────────────────────────────────────────
  String? get customerId => customer?.id;
  String? get customerName => customer?.name;
  String? get customerPhone => customer?.phone;
  String? get customerAddress => customer?.address;

  List<String> get technicianIds =>
      technicians.map((t) => t.id ?? '').where((id) => id.isNotEmpty).toList();
  List<String> get technicianNames =>
      technicians.map((t) => t.name ?? '').where((n) => n.isNotEmpty).toList();
  String? get technicianId =>
      technicians.isNotEmpty ? technicians.first.id : null;
  String? get technicianName => technicians.isNotEmpty
      ? technicians.map((t) => t.name ?? '').where((n) => n.isNotEmpty).join('، ')
      : null;

  factory BookingModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BookingModel();

    // 1. Resolve CustomerModel
    CustomerModel? customer;
    if (json['customer'] is Map<String, dynamic>) {
      customer =
          CustomerModel.fromJson(json['customer'] as Map<String, dynamic>?);
    } else if (json['customerId'] != null || json['customerName'] != null) {
      customer = CustomerModel(
        id: json['customerId']?.toString(),
        name: json['customerName'] as String?,
        phone: json['customerPhone'] as String?,
        address: json['customerAddress'] as String?,
      );
    }

    // 2. Resolve List<TechnicianModel>
    List<TechnicianModel> technicians = [];
    if (json['technicians'] is List<dynamic>) {
      technicians = (json['technicians'] as List<dynamic>)
          .map((e) => TechnicianModel.fromJson(e as Map<String, dynamic>?))
          .toList();
    } else {
      final techId = json['technicianId']?.toString();
      final techName = json['technicianName'] as String?;
      final techIds = (json['technicianIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (techId != null ? [techId] : const <String>[]);
      final techNames = (json['technicianNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (techName != null ? [techName] : const <String>[]);

      for (int i = 0; i < techIds.length; i++) {
        final id = techIds[i];
        final name = i < techNames.length ? techNames[i] : null;
        technicians.add(TechnicianModel(id: id, name: name));
      }
    }

    return BookingModel(
      id: json['id']?.toString(),
      customer: customer,
      technicians: technicians,
      serviceName: json['serviceName'] as String?,
      bookingType: BookingTypeEnum.fromValue(json['bookingType']?.toString()),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      recurrence: json['recurrence'] != null
          ? RecurrenceRuleModel.fromJson(
              json['recurrence'] as Map<String, dynamic>)
          : null,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      hourlyRate: json['hourlyRate'] as num?,
      totalPrice: json['totalPrice'] as num?,
      status: BookingStatusEnum.fromValue(json['status']?.toString()),
      paymentStatus:
          PaymentStatusEnum.fromValue(json['paymentStatus']?.toString()),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (customer != null) 'customer': customer!.toJson(),
      'technicians': technicians.map((t) => t.toJson()).toList(),
      // Backward compatibility fields
      if (customerId != null) 'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerAddress != null) 'customerAddress': customerAddress,
      if (technicianId != null) 'technicianId': technicianId,
      if (technicianName != null) 'technicianName': technicianName,
      'technicianIds': technicianIds,
      'technicianNames': technicianNames,
      if (serviceName != null) 'serviceName': serviceName,
      if (bookingType != null) 'bookingType': bookingType?.value,
      if (date != null) 'date': date?.toIso8601String(),
      if (recurrence != null) 'recurrence': recurrence?.toJson(),
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (hourlyRate != null) 'hourlyRate': hourlyRate,
      if (totalPrice != null) 'totalPrice': totalPrice,
      if (status != null) 'status': status?.value,
      if (paymentStatus != null) 'paymentStatus': paymentStatus?.value,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  BookingModel copyWith({
    String? id,
    CustomerModel? customer,
    List<TechnicianModel>? technicians,
    // Optional compatibility parameters
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? technicianId,
    String? technicianName,
    List<String>? technicianIds,
    List<String>? technicianNames,
    String? serviceName,
    BookingTypeEnum? bookingType,
    DateTime? date,
    RecurrenceRuleModel? recurrence,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    num? hourlyRate,
    num? totalPrice,
    BookingStatusEnum? status,
    PaymentStatusEnum? paymentStatus,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    CustomerModel? updatedCustomer = customer ?? this.customer;
    if (customer == null &&
        (customerId != null ||
            customerName != null ||
            customerPhone != null ||
            customerAddress != null)) {
      updatedCustomer = CustomerModel(
        id: customerId ?? this.customerId,
        name: customerName ?? this.customerName,
        phone: customerPhone ?? this.customerPhone,
        address: customerAddress ?? this.customerAddress,
      );
    }

    List<TechnicianModel> updatedTechnicians =
        technicians ?? this.technicians;
    if (technicians == null &&
        (technicianIds != null ||
            technicianNames != null ||
            technicianId != null ||
            technicianName != null)) {
      final ids = technicianIds ??
          (technicianId != null ? [technicianId] : this.technicianIds);
      final names = technicianNames ??
          (technicianName != null ? [technicianName] : this.technicianNames);
      updatedTechnicians = [
        for (int i = 0; i < ids.length; i++)
          TechnicianModel(
            id: ids[i],
            name: i < names.length ? names[i] : null,
          ),
      ];
    }

    return BookingModel(
      id: id ?? this.id,
      customer: updatedCustomer,
      technicians: updatedTechnicians,
      serviceName: serviceName ?? this.serviceName,
      bookingType: bookingType ?? this.bookingType,
      date: date ?? this.date,
      recurrence: recurrence ?? this.recurrence,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
