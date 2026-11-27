import 'package:dio/dio.dart';
import 'package:eyadty/core/local_server/local_server_config.dart';
import 'package:eyadty/core/local_server/local_server_db.dart';

class LocalServerRequest {
  final String method;
  final String path;
  final Map<String, String> pathParams;
  final Map<String, dynamic> queryParameters;
  final Map<String, dynamic> body;
  final String? idempotencyKey;
  final String? authHeader;

  const LocalServerRequest({
    required this.method,
    required this.path,
    required this.pathParams,
    required this.queryParameters,
    required this.body,
    this.idempotencyKey,
    this.authHeader,
  });
}

typedef LocalRouteHandler = Future<dynamic> Function(LocalServerRequest req);

class _RouteEntry {
  final String method;
  final List<String> segments;
  final LocalRouteHandler handler;

  _RouteEntry(this.method, String pattern, this.handler)
      : segments = _normalize(pattern).split('/').where((s) => s.isNotEmpty).toList();

  static String _normalize(String path) {
    var p = path.split('?').first.trim();
    if (p.startsWith('/')) p = p.substring(1);
    if (p.startsWith('api/v1/')) p = p.substring('api/v1/'.length);
    if (p.endsWith('/') && p.length > 1) p = p.substring(0, p.length - 1);
    return p;
  }

  Map<String, String>? match(String reqMethod, List<String> reqSegments) {
    if (method != reqMethod.toUpperCase()) return null;
    if (segments.length != reqSegments.length) return null;
    final params = <String, String>{};
    for (var i = 0; i < segments.length; i++) {
      final pat = segments[i];
      final val = reqSegments[i];
      if (pat.startsWith('{') && pat.endsWith('}')) {
        params[pat.substring(1, pat.length - 1)] = Uri.decodeComponent(val);
      } else if (pat != val) {
        return null;
      }
    }
    return params;
  }
}

/// Routes HTTP-shaped requests to local handlers and wraps responses in the
/// standard JSON envelope `{data, meta}` or throws [DioException] with `{error}`.
class LocalServerRouter {
  final LocalServerDb db;
  final List<_RouteEntry> _routes = [];

  LocalServerRouter({required this.db});

  void register(String method, String pathPattern, LocalRouteHandler handler) {
    _routes.add(_RouteEntry(method.toUpperCase(), pathPattern, handler));
  }

  static Map<String, dynamic> ok(dynamic data, {Map<String, dynamic>? meta}) {
    return {
      'data': data,
      if (meta != null) 'meta': meta,
    };
  }

  static Map<String, dynamic> paginated(
    List<Map<String, dynamic>> allItems, {
    int page = 1,
    int limit = 20,
  }) {
    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit < 1 ? 20 : limit;
    final start = (safePage - 1) * safeLimit;
    final paged = start >= allItems.length
        ? <Map<String, dynamic>>[]
        : allItems.skip(start).take(safeLimit).toList();
    return {
      'data': paged,
      'meta': {
        'page': safePage,
        'limit': safeLimit,
        'total': allItems.length,
      },
    };
  }

  static Never throwHttpError(
    String path,
    int statusCode,
    String code,
    String message, {
    Map<String, dynamic>? fields,
  }) {
    final reqOptions = RequestOptions(path: path);
    throw DioException(
      requestOptions: reqOptions,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: reqOptions,
        statusCode: statusCode,
        data: {
          'error': {
            'code': code,
            'message': message,
            if (fields != null) 'fields': fields,
          },
        },
      ),
    );
  }

  Future<dynamic> dispatch({
    required String method,
    required String path,
    Options? options,
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (LocalServerConfig.latency > Duration.zero) {
      await Future.delayed(LocalServerConfig.latency);
    }

    final injected = LocalServerConfig.injectedFailureStatusCode;
    if (injected != null) {
      if (LocalServerConfig.resetFailureAfterNextCall) {
        LocalServerConfig.injectedFailureStatusCode = null;
      }
      if (injected == -1) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionTimeout,
          message: 'Simulated connection timeout',
        );
      }
      throwHttpError(
        path,
        injected,
        'INJECTED_$injected',
        'Simulated HTTP $injected error',
      );
    }

    final normalizedPath = _RouteEntry._normalize(path);
    final reqSegments =
        normalizedPath.split('/').where((s) => s.isNotEmpty).toList();

    final mergedQuery = <String, dynamic>{};
    final qIndex = path.indexOf('?');
    if (qIndex != -1) {
      mergedQuery.addAll(Uri.splitQueryString(path.substring(qIndex + 1)));
    }
    if (queryParameters != null) {
      mergedQuery.addAll(queryParameters);
    }

    final idempotencyKey =
        options?.headers?['Idempotency-Key']?.toString() ??
            options?.headers?['idempotency-key']?.toString();

    if (method.toUpperCase() != 'GET' && idempotencyKey != null) {
      final cached = db.getIdempotentResponse(idempotencyKey);
      if (cached != null) return cached;
    }

    final bodyMap = body is Map<String, dynamic>
        ? body
        : (body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{});

    for (final route in _routes) {
      final params = route.match(method, reqSegments);
      if (params != null) {
        final req = LocalServerRequest(
          method: method.toUpperCase(),
          path: normalizedPath,
          pathParams: params,
          queryParameters: mergedQuery,
          body: bodyMap,
          idempotencyKey: idempotencyKey,
          authHeader: options?.headers?['Authorization']?.toString(),
        );
        final res = await route.handler(req);
        if (method.toUpperCase() != 'GET' && idempotencyKey != null) {
          db.saveIdempotentResponse(idempotencyKey, res);
        }
        return res;
      }
    }

    throwHttpError(path, 404, 'NOT_FOUND', 'Route not found: $method $path');
  }
}
