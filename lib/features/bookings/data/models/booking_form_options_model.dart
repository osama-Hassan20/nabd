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

  const BookingTechnicianOption({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}
