part of 'basic_cubit.dart';

class BasicState extends Equatable {
  final RequestStatusEnum profileStatus;
  final String? errMessage;
  final ProfileModel? profile;

  const BasicState({
    this.profileStatus = RequestStatusEnum.initial,
    this.errMessage,
    this.profile,
  });

  BasicState copyWith({
    RequestStatusEnum? profileStatus,
    String? errMessage,
    ProfileModel? profile,
  }) {
    return BasicState(
      profileStatus: profileStatus ?? this.profileStatus,
      errMessage: errMessage ?? this.errMessage,
      profile: profile ?? this.profile,
    );
  }

  @override
  List<Object?> get props => [
    profileStatus,
    errMessage,
    profile,
  ];
}
