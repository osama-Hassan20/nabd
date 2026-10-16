import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/params.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/booking_summary_model.dart';
import '../repo/bookings_repo.dart';

class GetBookingSummaryUseCase implements UseCase<BookingSummaryModel, NoParams> {
  final BookingsRepo repo;

  GetBookingSummaryUseCase({required this.repo});

  @override
  Future<Either<Failures, BookingSummaryModel>> call(NoParams params) {
    return repo.getBookingSummary();
  }
}
