import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/visit_model.dart';
import '../repo/visits_repo.dart';

class GetVisitByBookingIdUseCase implements UseCase<VisitModel?, String> {
  final VisitsRepo repo;

  GetVisitByBookingIdUseCase({required this.repo});

  @override
  Future<Either<Failures, VisitModel?>> call(String bookingId) {
    return repo.getVisitByBookingId(bookingId: bookingId);
  }
}
