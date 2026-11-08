import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/user_role_enum.dart';

export '../enums/user_role_enum.dart' show CurrentRoleProvider;

class SessionState extends Equatable {
  final UserRoleEnum? currentRole;
  final String? userId;
  final String? userName;

  const SessionState({
    this.currentRole,
    this.userId,
    this.userName,
  });

  SessionState copyWith({
    UserRoleEnum? currentRole,
    String? userId,
    String? userName,
  }) {
    return SessionState(
      currentRole: currentRole ?? this.currentRole,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
    );
  }

  @override
  List<Object?> get props => [currentRole, userId, userName];
}

class SessionCubit extends Cubit<SessionState> implements CurrentRoleProvider {
  SessionCubit(super.initialState);

  @override
  UserRoleEnum get currentRole => state.currentRole ?? UserRoleEnum.admin;

  void switchRole(UserRoleEnum role) {
    emit(state.copyWith(currentRole: role));
  }
}

