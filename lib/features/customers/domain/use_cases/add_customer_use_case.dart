import 'package:dartz/dartz.dart';
import 'package:purexo/core/errors/failures.dart';
import 'package:purexo/core/uses_cases/use_cases.dart';
import '../../data/models/customer_model.dart';
import '../repo/customers_repo.dart';

class AddCustomerUseCase extends UseCase<CustomerModel, CustomerModel> {
  final CustomersRepo repo;

  AddCustomerUseCase({required this.repo});

  @override
  Future<Either<Failures, CustomerModel>> call(CustomerModel customer) {
    return repo.addCustomer(customer: customer);
  }
}
