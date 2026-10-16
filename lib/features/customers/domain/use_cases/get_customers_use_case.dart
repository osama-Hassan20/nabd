import 'package:dartz/dartz.dart';
import 'package:purexo/core/errors/failures.dart';
import 'package:purexo/core/uses_cases/params.dart';
import 'package:purexo/core/uses_cases/use_cases.dart';
import '../../data/models/customers_response_model.dart';
import '../repo/customers_repo.dart';

class GetCustomersUseCase
    extends UseCase<CustomersResponseModel, PaginationParams> {
  final CustomersRepo repo;

  GetCustomersUseCase({required this.repo});

  @override
  Future<Either<Failures, CustomersResponseModel>> call(
      PaginationParams params) {
    return repo.getCustomers(params: params);
  }
}
