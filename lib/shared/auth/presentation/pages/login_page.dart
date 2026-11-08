import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/animation/fade_transition_animation.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/theme/app_animations.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo.dart';

import '../cubits/login/login_cubit.dart';
import '../widgets/login_widgets/login_body.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(
        staffUsersRepo: getIt<StaffUsersRepo>(),
        sessionCubit: getIt<SessionCubit>(),
      )..checkRemeberMe(),
      child: const Scaffold(
        body: FadeTransitionAnimation(
          duration: AppAnimations.medium,
          curve: AppAnimations.defaultCurve,
          child: LoginBody(),
        ),
      ),
    );
  }
}
