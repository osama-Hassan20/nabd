import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/params.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/bookings_response_model.dart';
import '../repo/bookings_repo.dart';

class GetBookingsUseCase implements UseCase<BookingsResponseModel, PaginationParams> {
  final BookingsRepo repo;

  GetBookingsUseCase({required this.repo});

  @override
  Future<Either<Failures, BookingsResponseModel>> call(PaginationParams params) {
    return repo.getBookings(params);
  }
}
