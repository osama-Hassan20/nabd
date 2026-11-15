import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import '../../data/models/drug_model.dart';
import '../repo/drugs_repo.dart';

class QuickAddDrugParams extends Equatable {
  final String name;
  final String visitId;
  final String doctorId;
  final String? concentration;
  final String? dosage;
  final String? frequency;
  final String? duration;

  const QuickAddDrugParams({
    required this.name,
    required this.visitId,
    required this.doctorId,
    this.concentration,
    this.dosage,
    this.frequency,
    this.duration,
  });

  @override
  List<Object?> get props => [
        name,
        visitId,
        doctorId,
        concentration,
        dosage,
        frequency,
        duration,
      ];
}

class QuickAddDrugUseCase {
  final DrugsRepo repo;
  final AuditLogger auditLogger;

  QuickAddDrugUseCase({
    required this.repo,
    required this.auditLogger,
  });

  Future<Either<Failures, DrugModel>> call(QuickAddDrugParams params) async {
    final res = await repo.quickAddDrug(
      name: params.name,
      visitId: params.visitId,
      doctorId: params.doctorId,
      concentration: params.concentration,
      dosage: params.dosage,
      frequency: params.frequency,
      duration: params.duration,
    );

    return res.fold(
      (failure) => Left(failure),
      (created) {
        auditLogger.log(
          eventType: 'drug_quick_added',
          performedByUserId: params.doctorId,
          details: jsonEncode({
            'drugId': created.id,
            'visitId': params.visitId,
            'doctorId': params.doctorId,
          }),
        );
        return Right(created);
      },
    );
  }
}
