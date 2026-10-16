import 'package:equatable/equatable.dart';

class ReassignTechnicianParams extends Equatable {
  final String bookingId;
  final String? newTechnicianId;
  final String? newTechnicianName;
  final List<String> newTechnicianIds;
  final List<String> newTechnicianNames;

  ReassignTechnicianParams({
    required this.bookingId,
    this.newTechnicianId,
    this.newTechnicianName,
    List<String>? newTechnicianIds,
    List<String>? newTechnicianNames,
  }) : newTechnicianIds =
           newTechnicianIds ??
           (newTechnicianId != null ? [newTechnicianId] : const []),
       newTechnicianNames =
           newTechnicianNames ??
           (newTechnicianName != null ? [newTechnicianName] : const []);

  @override
  List<Object?> get props => [
    bookingId,
    newTechnicianId,
    newTechnicianName,
    newTechnicianIds,
    newTechnicianNames,
  ];
}
