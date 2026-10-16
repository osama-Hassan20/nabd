import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/uses_cases/use_cases.dart';
import '../../data/models/customer_model.dart';
import '../repo/customers_repo.dart';

class GetCustomerByIdUseCase extends UseCase<CustomerModel, String> {
  final CustomersRepo repo;

  GetCustomerByIdUseCase({required this.repo});

  @override
  Future<Either<Failures, CustomerModel>> call(String id) {
    return repo.getCustomerById(id: id);
  }
}
