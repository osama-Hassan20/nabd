import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

abstract class Failures extends Equatable {
  final String errMessage;

  const Failures({required this.errMessage});

  @override
  List<Object?> get props => [errMessage];

  @override
  String toString() => '$runtimeType: $errMessage';
}

class ServerFailure extends Failures {
  const ServerFailure({required super.errMessage});

  @override
  String toString() => 'ServerFailure: $errMessage';

  factory ServerFailure.fromDioException({required DioException dioException}) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return const ServerFailure(
          errMessage: 'No internet connection, please try again!',
        );
      case DioExceptionType.sendTimeout:
        return const ServerFailure(errMessage: 'Send timeout with ApiServer');
      case DioExceptionType.receiveTimeout:
        return const ServerFailure(
          errMessage: 'Receive timeout with ApiServer',
        );
      case DioExceptionType.badCertificate:
        return const ServerFailure(errMessage: 'badCertificate with ApiServer');
      case DioExceptionType.badResponse:
        return ServerFailure.fromResponse(
          statusCode: dioException.response!.statusCode,
          response: dioException.response!.data,
        );

      case DioExceptionType.cancel:
        return const ServerFailure(
          errMessage: 'Request to ApiServer was canceled',
        );
      case DioExceptionType.connectionError:
        {
          return const ServerFailure(
            errMessage: 'No internet connection, please try again!',
          );
        }
      case DioExceptionType.unknown:
      default:
        return const ServerFailure(
          errMessage: 'Unexpected error, please try later!',
        );
    }
  }

  factory ServerFailure.fromResponse({int? statusCode, dynamic response}) {
    if (statusCode == 400 ||
        statusCode == 401 ||
        statusCode == 422 ||
        statusCode == 406 ||
        statusCode == 409 ||
        statusCode == 424 ||
        statusCode == 404) {
      return ServerFailure(
        errMessage:
            response['message'] ??
            response['error'] ??
            'Unexpected error, please try later!',
      );
    } else if (statusCode == 500) {
      return ServerFailure(
        errMessage: response['message'] ?? 'Server error, please try later!',
      );
    } else if (statusCode == 406) {
      return const ServerFailure(
        errMessage: 'تم تعطيل حسابك من قبل الادمن او الادارة',
      );
    } else if (statusCode == 403) {
      //    Helper.expiredToken();
      String message = response['message'] ?? 'Forbidden';
      if (message.contains("Not Allowed")) {
        return ServerFailure(errMessage: response['message']);
      }
      return const ServerFailure(
        errMessage: 'Your session has expired, please login again!',
      );
    } else {
      return const ServerFailure(
        errMessage: 'Oops there was an error, please try later!',
      );
    }
  }

  @override
  List<Object?> get props => [];
}

class OfflineFailures extends Failures {
  const OfflineFailures({required super.errMessage});

  @override
  List<Object?> get props => [];
}

class CacheFailures extends Failures {
  const CacheFailures({required super.errMessage});

  @override
  List<Object?> get props => [];
}

class ValidationFailure extends Failures {
  const ValidationFailure({required super.errMessage});

  @override
  List<Object?> get props => [errMessage];
}

class ConflictingBookingsFailure extends Failures {
  final int conflictingCount;

  const ConflictingBookingsFailure({
    required super.errMessage,
    required this.conflictingCount,
  });

  @override
  List<Object?> get props => [errMessage, conflictingCount];
}

class DuplicatePhonePatientInfo extends Equatable {
  final String? id;
  final String? name;
  final String? fileNumber;
  final String? phone;

  const DuplicatePhonePatientInfo({
    this.id,
    this.name,
    this.fileNumber,
    this.phone,
  });

  @override
  List<Object?> get props => [id, name, fileNumber, phone];
}

class DuplicatePhoneWarningFailure extends Failures {
  final List<DuplicatePhonePatientInfo> matchingPatients;

  const DuplicatePhoneWarningFailure({
    required super.errMessage,
    required this.matchingPatients,
  });

  @override
  List<Object?> get props => [errMessage, matchingPatients];
}

class SlotConflictFailure extends Failures {
  final String? conflictingPatientName;
  final String? conflictingBookingId;

  const SlotConflictFailure({
    required super.errMessage,
    this.conflictingPatientName,
    this.conflictingBookingId,
  });

  @override
  List<Object?> get props => [
        errMessage,
        conflictingPatientName,
        conflictingBookingId,
      ];
}

typedef Failure = Failures;

class LastActiveOwnerFailure extends Failures {
  const LastActiveOwnerFailure({required super.errMessage});
}

class PrivilegeEscalationFailure extends Failures {
  const PrivilegeEscalationFailure({required super.errMessage});
}

class SelfDeactivationFailure extends Failures {
  const SelfDeactivationFailure({required super.errMessage});
}

class SelfDeletionFailure extends Failures {
  const SelfDeletionFailure({required super.errMessage});
}

class LinkedDoctorMissingFailure extends Failures {
  const LinkedDoctorMissingFailure({required super.errMessage});
}

class ActiveBookingsWarningFailure extends Failures {
  final int activeBookingsCount;

  const ActiveBookingsWarningFailure({
    required super.errMessage,
    required this.activeBookingsCount,
  });

  @override
  List<Object?> get props => [errMessage, activeBookingsCount];
}

class InvalidCredentialsFailure extends Failures {
  const InvalidCredentialsFailure({required super.errMessage});
}

class MustChangePasswordFailure extends Failures {
  final String? userId;

  const MustChangePasswordFailure({
    required super.errMessage,
    this.userId,
  });

  @override
  List<Object?> get props => [errMessage, userId];
}

class CannotDeactivateMainBranchFailure extends Failures {
  const CannotDeactivateMainBranchFailure({required super.errMessage});
}

class CannotDeactivateLastActiveBranchFailure extends Failures {
  const CannotDeactivateLastActiveBranchFailure({required super.errMessage});
}

class BranchNotFoundFailure extends Failures {
  const BranchNotFoundFailure({required super.errMessage});
}

class InvalidBranchOperationFailure extends Failures {
  const InvalidBranchOperationFailure({required super.errMessage});
}

class PermissionDeniedFailure extends Failures {
  const PermissionDeniedFailure({required super.errMessage});
}

