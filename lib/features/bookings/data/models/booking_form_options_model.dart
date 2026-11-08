import 'package:equatable/equatable.dart';

class BookingPatientOption extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String address;

  const BookingPatientOption({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  @override
  List<Object?> get props => [id, name, phone, address];
}

typedef BookingCustomerOption = BookingPatientOption;

class BookingDoctorOption extends Equatable {
  final String id;
  final String name;
  final bool isAvailable;
  final String? unavailableReason;

  const BookingDoctorOption({
    required this.id,
    required this.name,
    this.isAvailable = true,
    this.unavailableReason,
  });

  @override
  List<Object?> get props => [id, name, isAvailable, unavailableReason];
}

typedef BookingTechnicianOption = BookingDoctorOption;
