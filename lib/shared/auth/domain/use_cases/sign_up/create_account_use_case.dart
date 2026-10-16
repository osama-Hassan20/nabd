import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/uses_cases/use_cases.dart';
import '../../../data/models/sign_up/sign_up_params.dart';
import '../../../data/models/user_model.dart';
import '../../repositories/sign_up_repo.dart';

class CreateAccountUseCase extends UseCase<AdminModel, SignUpParams> {
  final SignUpRepo signUpRepo;

  CreateAccountUseCase({required this.signUpRepo});

  @override
  Future<Either<Failures, AdminModel>> call(SignUpParams params) async {
    return await signUpRepo.createAccount(params: params);
  }
}
