import 'package:purexo/core/animation/scale_transition_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/dependency_injection/dependency_injection.dart';
import '../../domain/repositories/login_repo.dart';
import '../../domain/use_cases/login/login_use_case.dart';
import '../cubits/login/login_cubit.dart';
import '../widgets/login_widgets/login_body.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(
        loginUseCase: LoginUseCase(loginRepo: getIt.get<LoginRepo>()),
      )..checkRemeberMe(),
      child: Scaffold(
        body: ScaleTransitionAnimation(
          duration: const Duration(milliseconds: 700),
          child: LoginBody(),
        ),
      ),
    );
  }
}
