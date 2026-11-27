import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:eyadty/core/local_server/local_server_db.dart';
import '../../domain/repo/cashier_repo.dart';
import '../models/cash_movement_model.dart';
import '../models/cashier_shift_model.dart';
import '../models/cashier_summary_metrics_model.dart';
import '../models/payment_transaction_model.dart';
import '../models/refund_transaction_model.dart';

class CashierRepoImpl implements CashierRepo {
  final ApiConsumer _api;

  CashierRepoImpl({bool seedInitialData = true, ApiConsumer? apiConsumer})
      : _api = apiConsumer ??
            (seedInitialData
                ? (getIt.isRegistered<ApiConsumer>()
                    ? getIt<ApiConsumer>()
                    : LocalServerApiConsumer())
                : LocalServerApiConsumer(db: LocalServerDb()));

  @override
  Future<Either<Failures, CashierShiftModel?>> getCurrentShift({
    required String branchId,
    required String cashierUserId,
  }) async {
    try {
      final res = await _api.get(
        path: 'cashier/shifts/current',
        queryParameters: {
          'branchId': branchId,
          'cashierUserId': cashierUserId,
        },
      );
      final data = res is Map ? res['data'] : res;
      if (data == null) return const Right(null);
      return Right(
        CashierShiftModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<CashierShiftModel>>> getShiftHistory({
    required String branchId,
    String? cashierUserId,
  }) async {
    try {
      final res = await _api.get(
        path: 'cashier/shifts',
        queryParameters: {
          'branchId': branchId,
          if (cashierUserId != null) 'cashierUserId': cashierUserId,
        },
      );
      final list = (res is Map ? res['data'] : res) as List? ?? const [];
      return Right(
        list
            .map((e) =>
                CashierShiftModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, CashierShiftModel>> openShift({
    required String branchId,
    required String cashierUserId,
    required String cashierName,
    required int openingBalancePiastres,
    String? suggestedOpeningBalanceDiffReason,
  }) async {
    try {
      final res = await _api.post(
        path: 'cashier/shifts/open',
        body: {
          'branchId': branchId,
          'cashierUserId': cashierUserId,
          'cashierName': cashierName,
          'openingBalancePiastres': openingBalancePiastres,
          if (suggestedOpeningBalanceDiffReason != null)
            'suggestedOpeningBalanceDiffReason':
                suggestedOpeningBalanceDiffReason,
        },
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        CashierShiftModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, CashierShiftModel>> closeShift({
    required String shiftId,
    required int actualCashCountPiastres,
    String? closingNotes,
    String? shortageReason,
  }) async {
    try {
      final res = await _api.post(
        path: 'cashier/shifts/$shiftId/close',
        body: {
          'actualCashCountPiastres': actualCashCountPiastres,
          if (closingNotes != null) 'closingNotes': closingNotes,
          if (shortageReason != null) 'shortageReason': shortageReason,
        },
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        CashierShiftModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, CashierShiftModel>> forceCloseShift({
    required String shiftId,
    required String performedByUserId,
    required String reason,
  }) async {
    try {
      final res = await _api.post(
        path: 'cashier/shifts/$shiftId/force-close',
        body: {
          'performedByUserId': performedByUserId,
          'reason': reason,
        },
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        CashierShiftModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, CashierShiftModel>> approveShortage({
    required String shiftId,
    required String approvedByUserId,
    required String reason,
    bool isOwnerSelfApproved = false,
  }) async {
    try {
      final res = await _api.post(
        path: 'cashier/shifts/$shiftId/approve-shortage',
        body: {
          'approvedByUserId': approvedByUserId,
          'reason': reason,
          'isOwnerSelfApproved': isOwnerSelfApproved,
        },
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        CashierShiftModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, PaymentTransactionModel>> recordPayment({
    required String clientRequestId,
    required String shiftId,
    required String branchId,
    required String bookingId,
    required String patientId,
    required String patientName,
    required int amountPiastres,
    required String paymentMethod,
    String? referenceNumber,
    required String cashierUserId,
    required String cashierName,
    String? notes,
  }) async {
    try {
      final res = await _api.post(
        path: 'cashier/payments',
        body: {
          'clientRequestId': clientRequestId,
          'shiftId': shiftId,
          'branchId': branchId,
          'bookingId': bookingId,
          'patientId': patientId,
          'patientName': patientName,
          'amountPiastres': amountPiastres,
          'paymentMethod': paymentMethod,
          if (referenceNumber != null) 'referenceNumber': referenceNumber,
          'cashierUserId': cashierUserId,
          'cashierName': cashierName,
          if (notes != null) 'notes': notes,
        },
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        PaymentTransactionModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, RefundTransactionModel>> refundPayment({
    required String clientRequestId,
    required String originalPaymentId,
    required String shiftId,
    required String branchId,
    required String bookingId,
    required String patientId,
    required int refundAmountPiastres,
    required String refundMethod,
    required String reason,
    required String authorizedByUserId,
    required String authorizedByName,
  }) async {
    try {
      final res = await _api.post(
        path: 'cashier/payments/$originalPaymentId/refund',
        body: {
          'clientRequestId': clientRequestId,
          'shiftId': shiftId,
          'branchId': branchId,
          'bookingId': bookingId,
          'patientId': patientId,
          'refundAmountPiastres': refundAmountPiastres,
          'refundMethod': refundMethod,
          'reason': reason,
          'authorizedByUserId': authorizedByUserId,
          'authorizedByName': authorizedByName,
        },
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        RefundTransactionModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, CashMovementModel>> recordCashMovement({
    required String clientRequestId,
    required String shiftId,
    required String branchId,
    required String movementType,
    required int amountPiastres,
    required String reason,
    String? recipientName,
    required String performedByUserId,
  }) async {
    try {
      final res = await _api.post(
        path: 'cashier/movements',
        body: {
          'clientRequestId': clientRequestId,
          'shiftId': shiftId,
          'branchId': branchId,
          'movementType': movementType,
          'amountPiastres': amountPiastres,
          'reason': reason,
          if (recipientName != null) 'recipientName': recipientName,
          'performedByUserId': performedByUserId,
        },
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        CashMovementModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, CashierSummaryMetricsModel>> getShiftMetrics({
    required String shiftId,
  }) async {
    try {
      final res = await _api.get(path: 'cashier/shifts/$shiftId/metrics');
      final data = res is Map ? res['data'] : res;
      return Right(
        CashierSummaryMetricsModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<PaymentTransactionModel>>> getPaymentsForShift({
    required String shiftId,
    bool includeVoided = false,
  }) async {
    try {
      final res = await _api.get(
        path: 'cashier/shifts/$shiftId/payments',
        queryParameters: {'includeVoided': includeVoided},
      );
      final list = (res is Map ? res['data'] : res) as List? ?? const [];
      return Right(
        list
            .map((e) => PaymentTransactionModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<PaymentTransactionModel>>> getPaymentsByBookingId({
    required String bookingId,
  }) async {
    try {
      final res = await _api.get(path: 'bookings/$bookingId/payments');
      final list = (res is Map ? res['data'] : res) as List? ?? const [];
      return Right(
        list
            .map((e) => PaymentTransactionModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<PaymentTransactionModel>>> getPaymentsByPatientId({
    required String patientId,
  }) async {
    try {
      final res = await _api.get(path: 'patients/$patientId/payments');
      final list = (res is Map ? res['data'] : res) as List? ?? const [];
      return Right(
        list
            .map((e) => PaymentTransactionModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, void>> voidPaymentRollback({
    required String paymentId,
    required String reason,
  }) async {
    try {
      await _api.post(
        path: 'cashier/payments/$paymentId/void',
        body: {'reason': reason},
      );
      return const Right(null);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }
}
