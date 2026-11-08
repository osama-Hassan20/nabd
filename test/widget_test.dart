import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/enums/user_role_enum.dart';

void main() {
  test('Session and Role Smoke Test', () {
    final sessionCubit = SessionCubit(
      const SessionState(
        currentRole: UserRoleEnum.admin,
        userName: 'مسؤول النظام التجريبي',
      ),
    );

    expect(sessionCubit.state.currentRole, UserRoleEnum.admin);
    expect(sessionCubit.state.currentRole!.canApplyManualDiscount, isTrue);
    expect(sessionCubit.state.currentRole!.canViewAuditLogs, isTrue);

    // Switch to doctor
    sessionCubit.switchRole(UserRoleEnum.doctor);
    expect(sessionCubit.state.currentRole, UserRoleEnum.doctor);
    expect(sessionCubit.state.currentRole!.canApplyManualDiscount, isFalse);

    // Switch to reception
    sessionCubit.switchRole(UserRoleEnum.reception);
    expect(sessionCubit.state.currentRole, UserRoleEnum.reception);
    expect(sessionCubit.state.currentRole!.canApplyManualDiscount, isFalse);
  });
}
