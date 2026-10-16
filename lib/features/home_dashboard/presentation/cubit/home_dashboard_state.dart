import 'package:equatable/equatable.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';

class HomeDashboardState extends Equatable {
  final RequestStatusEnum status;
  final String? errMessage;

  const HomeDashboardState({
    this.status = RequestStatusEnum.initial,
    this.errMessage,
  });

  HomeDashboardState copyWith({
    RequestStatusEnum? status,
    String? errMessage,
  }) {
    return HomeDashboardState(
      status: status ?? this.status,
      errMessage: errMessage ?? this.errMessage,
    );
  }

  @override
  List<Object?> get props => [status, errMessage];
}
