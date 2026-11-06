import 'package:equatable/equatable.dart';

class BookingCustomerOption extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String address;

  const BookingCustomerOption({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  @override
  List<Object?> get props => [id, name, phone, address];
}

class BookingTechnicianOption extends Equatable {
  final String id;
  final String name;
  final bool isAvailable;
  final String? unavailableReason;

  const BookingTechnicianOption({
    required this.id,
    required this.name,
    this.isAvailable = true,
    this.unavailableReason,
  });

  @override
  List<Object?> get props => [id, name, isAvailable, unavailableReason];
}
