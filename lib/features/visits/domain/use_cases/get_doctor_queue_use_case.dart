import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/consultation_queue_item_model.dart';
import '../repo/visits_repo.dart';

class GetDoctorQueueParams {
  final String? doctorId;
  final String branchId;
  final DateTime date;

  const GetDoctorQueueParams({
    this.doctorId,
    required this.branchId,
    required this.date,
  });
}

class GetDoctorQueueUseCase
    implements UseCase<List<ConsultationQueueItemModel>, GetDoctorQueueParams> {
  final VisitsRepo repo;

  GetDoctorQueueUseCase({required this.repo});

  @override
  Future<Either<Failures, List<ConsultationQueueItemModel>>> call(
    GetDoctorQueueParams params,
  ) {
    return repo.getDoctorQueue(
      doctorId: params.doctorId,
      branchId: params.branchId,
      date: params.date,
    );
  }
}
