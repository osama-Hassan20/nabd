import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import '../repo/customers_repo.dart';

class DeleteCustomerUseCase extends UseCase<String, String> {
  final CustomersRepo repo;

  DeleteCustomerUseCase({required this.repo});

  @override
  Future<Either<Failures, String>> call(String id) {
    return repo.deleteCustomer(id: id);
  }
}
