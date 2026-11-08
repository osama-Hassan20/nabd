import 'package:equatable/equatable.dart';

class GetMedicalServicesParams extends Equatable {
  final bool? onlyActive;
  final String? doctorId;
  final String? query;

  const GetMedicalServicesParams({
    this.onlyActive,
    this.doctorId,
    this.query,
  });

  @override
  List<Object?> get props => [onlyActive, doctorId, query];
}

