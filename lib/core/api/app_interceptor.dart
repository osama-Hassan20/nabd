import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../routing/app_router.dart';
import '../routing/routes.dart';
import '../storage/cache_helper.dart';
import '../utils/constants/app_constants.dart';
import 'end_points.dart';
import 'status_code.dart';

class AppInterceptors extends Interceptor {
  final Dio dio;

  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  // 🆕 Snapshot of the original request body before the stream is consumed
  dynamic _pendingBodySnapshot;

  final List<String> _refreshExclusionList = [
    EndPoints.login,
    EndPoints.signup,
  ];

  AppInterceptors({required this.dio});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    String? authToken = AppSharedPreferences.getString(
      key: AppConstants.accessToken,
    );
    if (authToken != null && authToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $authToken';
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // log("response : ${response.data}");
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    log("err.response?.statusCode ${err.response?.statusCode}");

    if (err.response?.statusCode == StatusCode.unauthorized) {
      if (_refreshExclusionList.any(
        (path) => err.requestOptions.path.contains(path),
      )) {
        return super.onError(err, handler);
      }

      String? refreshToken = AppSharedPreferences.getString(
        key: AppConstants.refreshToken,
      );

      if (refreshToken != null && refreshToken.isNotEmpty) {
        // 🆕 Snapshot the body NOW before it gets consumed or invalidated
        _pendingBodySnapshot = _snapshotBody(err.requestOptions.data);

        if (_isRefreshing) {
          final success = await _refreshCompleter!.future;
          if (success) {
            return _retryRequest(err.requestOptions, handler);
          } else {
            return super.onError(err, handler);
          }
        }

        _isRefreshing = true;
        _refreshCompleter = Completer<bool>();

        try {
          final refreshDio = Dio();
          final response = await refreshDio.post(
            '${EndPoints.baseUrl}${EndPoints.refreshUserToken}',
            data: {"refreshToken": refreshToken},
          );

          log("Refresh success: ${response.data}");

          final String? newRefreshToken = response.data['data']['refreshToken'];
          final String? newAccessToken = response.data['data']['accessToken'];

          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await AppSharedPreferences.setString(
              value: newRefreshToken,
              key: AppConstants.refreshToken,
            );
          }
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await AppSharedPreferences.setString(
              value: newAccessToken,
              key: AppConstants.accessToken,
            );
          }

          _refreshCompleter!.complete(true);
          return await _retryRequest(err.requestOptions, handler);
        } catch (e) {
          log("Refresh token failed: $e");
          _refreshCompleter!.complete(false);

          await AppSharedPreferences.remove(key: AppConstants.accessToken);
          await AppSharedPreferences.remove(key: AppConstants.refreshToken);
          appRouter.go(AppRouter.login);

          return super.onError(err, handler);
        } finally {
          _isRefreshing = false;
          _pendingBodySnapshot = null; // 🆕 Clean up after retry
        }
      }
    } else if (err.response?.statusCode == StatusCode.forbidden) {
      if (err.response?.data != null) {
        if (err.response?.data['message'] != null) {
          String message = err.response?.data['message'];
          if (message.contains("Not Allowed")) {
            log("Not Allowed");
          } else {
            await AppSharedPreferences.remove(key: AppConstants.accessToken);
            await AppSharedPreferences.remove(key: AppConstants.refreshToken);
            appRouter.go(AppRouter.login);
          }
        }
      }
    }

    super.onError(err, handler);
  }

  /// 🆕 Snapshots the request body into a plain Map so it survives FormData invalidation.
  dynamic _snapshotBody(dynamic data) {
    if (data is FormData) {
      // Rebuild a plain Map from the FormData fields
      final Map<String, dynamic> fields = {};
      for (final entry in data.fields) {
        fields[entry.key] = entry.value;
      }
      // Also carry over files if needed
      // for (final file in data.files) { fields[file.key] = file.value; }
      return fields; // stored as Map, rebuilt into FormData on retry
    }
    // For JSON / Map bodies, they're already reusable — return as-is
    return data;
  }

  /// 🆕 Rebuilds the original body type for the retry request.
  dynamic _rebuildBody(RequestOptions original) {
    final snapshot = _pendingBodySnapshot;
    if (snapshot == null) return original.data;

    if (original.contentType?.contains('multipart/form-data') == true) {
      // Reconstruct FormData from the Map snapshot
      return FormData.fromMap(snapshot as Map<String, dynamic>);
    }

    return snapshot; // JSON/Map — already safe to reuse
  }

  Future<void> _retryRequest(
    RequestOptions requestOptions,
    ErrorInterceptorHandler handler,
  ) async {
    final accessToken = AppSharedPreferences.getString(
      key: AppConstants.accessToken,
    );

    // 🆕 Rebuild the body (fresh FormData if needed)
    requestOptions.data = _rebuildBody(requestOptions);
    requestOptions.headers['Authorization'] = 'Bearer $accessToken';

    handler.resolve(await dio.fetch(requestOptions));
  }
}
