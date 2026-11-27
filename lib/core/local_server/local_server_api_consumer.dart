import 'package:dio/dio.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/local_server/handlers/auth_local_handler.dart';
import 'package:eyadty/core/local_server/handlers/bookings_local_handler.dart';
import 'package:eyadty/core/local_server/handlers/doctors_local_handler.dart';
import 'package:eyadty/core/local_server/handlers/patients_local_handler.dart';
import 'package:eyadty/core/local_server/handlers/visits_local_handler.dart';
import 'package:eyadty/core/local_server/local_server_db.dart';
import 'package:eyadty/core/local_server/local_server_router.dart';
import 'package:eyadty/core/local_server/local_server_seeds.dart';

/// In-process local server simulation implementing [ApiConsumer].
///
/// Only registered in `BACKEND_MODE=local`.
/// Routes HTTP method + path requests to local handlers and returns the same
/// JSON envelope as the remote backend.
class LocalServerApiConsumer implements ApiConsumer {
  final LocalServerDb db;
  late final LocalServerRouter router;

  LocalServerApiConsumer({LocalServerDb? db})
      : db = db ?? LocalServerDb(onSeed: LocalServerSeeds.seedAll) {
    router = LocalServerRouter(db: this.db);
    AuthLocalHandler.register(router);
    PatientsLocalHandler.register(router);
    DoctorsLocalHandler.register(router);
    BookingsLocalHandler.register(router);
    VisitsLocalHandler.register(router);
  }

  Future<void> resetLocalData() => db.resetToSeeds();

  @override
  Future<dynamic> get({
    required String path,
    Options? options,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return router.dispatch(
      method: 'GET',
      path: path,
      options: options,
      body: body,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<dynamic> post({
    required String path,
    Object? body,
    Options? options,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return router.dispatch(
      method: 'POST',
      path: path,
      options: options,
      body: body,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<dynamic> put({
    required String path,
    Object? body,
    Options? options,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return router.dispatch(
      method: 'PUT',
      path: path,
      options: options,
      body: body,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<dynamic> delete({
    required String path,
    Map<String, dynamic>? body,
    Options? options,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return router.dispatch(
      method: 'DELETE',
      path: path,
      options: options,
      body: body,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<dynamic> patch({
    required String path,
    Map<String, dynamic>? body,
    Options? options,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return router.dispatch(
      method: 'PATCH',
      path: path,
      options: options,
      body: body,
      queryParameters: queryParameters,
    );
  }
}
