import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import '../repo/patients_repo.dart';

class ArchivePatientParams extends Equatable {
  final String id;
  final String? reason;

  const ArchivePatientParams({
    required this.id,
    this.reason,
  });

  @override
  List<Object?> get props => [id, reason];
}

class ArchivePatientUseCase extends UseCase<String, ArchivePatientParams> {
  final PatientsRepo repo;

  ArchivePatientUseCase({required this.repo});

  @override
  Future<Either<Failures, String>> call(ArchivePatientParams params) {
    return repo.archivePatient(id: params.id, reason: params.reason);
  }
}

