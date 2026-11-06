import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/booking_summary_model.dart';
import '../repo/bookings_repo.dart';

class GetBookingSummaryParams {
  final DateTime? date;
  final String? branchId;

  const GetBookingSummaryParams({this.date, this.branchId});
}

class GetBookingSummaryUseCase
    implements UseCase<BookingSummaryModel, GetBookingSummaryParams> {
  final BookingsRepo repo;

  GetBookingSummaryUseCase({required this.repo});

  @override
  Future<Either<Failures, BookingSummaryModel>> call(
    GetBookingSummaryParams params,
  ) {
    return repo.getBookingSummary(
      date: params.date,
      branchId: params.branchId,
    );
  }
}
