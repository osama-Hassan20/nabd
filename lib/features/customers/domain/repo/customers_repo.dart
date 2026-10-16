import 'package:dartz/dartz.dart';
import 'package:purexo/core/errors/failures.dart';
import 'package:purexo/core/uses_cases/params.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/customers_response_model.dart';

abstract class CustomersRepo {
  Future<Either<Failures, CustomersResponseModel>> getCustomers({
    required PaginationParams params,
  });

  Future<Either<Failures, CustomerModel>> getCustomerById({
    required String id,
  });

  Future<Either<Failures, CustomerModel>> addCustomer({
    required CustomerModel customer,
  });

  Future<Either<Failures, CustomerModel>> updateCustomer({
    required CustomerModel customer,
  });

  Future<Either<Failures, String>> deleteCustomer({
    required String id,
  });
}
