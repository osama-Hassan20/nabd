import 'package:dio/dio.dart';
import 'package:eyadty/core/api/api_consumer.dart';

/// In-process local server simulation implementing [ApiConsumer].
///
/// Only registered in `BACKEND_MODE=local`.
/// Routes HTTP method + path requests to local handlers and returns the same
/// JSON envelope as the remote backend.
class LocalServerApiConsumer implements ApiConsumer {
  const LocalServerApiConsumer();

  @override
  Future<dynamic> get({
    required String path,
    Options? options,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    throw UnimplementedError('LocalServerApiConsumer.get($path) pending handler registration');
  }

  @override
  Future<dynamic> post({
    required String path,
    Object? body,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    throw UnimplementedError('LocalServerApiConsumer.post($path) pending handler registration');
  }

  @override
  Future<dynamic> put({
    required String path,
    Object? body,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    throw UnimplementedError('LocalServerApiConsumer.put($path) pending handler registration');
  }

  @override
  Future<dynamic> delete({
    required String path,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    throw UnimplementedError('LocalServerApiConsumer.delete($path) pending handler registration');
  }

  @override
  Future<dynamic> patch({
    required String path,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    throw UnimplementedError('LocalServerApiConsumer.patch($path) pending handler registration');
  }
}
