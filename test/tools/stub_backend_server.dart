import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eyadty/core/local_server/local_server_api_consumer.dart';

/// Lightweight in-process HTTP stub server for testing `BACKEND_MODE=remote`
/// (`DioConsumer` + `AppInterceptors` + `HttpRemoteSyncApi`) without a live backend.
///
/// Handles explicit auth/error/timeout/sync test routes and delegates all other
/// schema routes to [LocalServerApiConsumer] so every endpoint in
/// `EYADTY_BACKEND_SCHEMA.json` is reachable over HTTP.
class StubBackendServer {
  HttpServer? _server;
  final LocalServerApiConsumer _localApi = LocalServerApiConsumer();

  int get port => _server!.port;
  String get baseUrl => 'http://127.0.0.1:$port/';
  String get apiBaseUrl => '${baseUrl}api/v1/';

  final List<Map<String, dynamic>> patients = [
    for (int i = 1; i <= 5; i++)
      {
        'id': 'PAT-STUB-$i',
        'name': 'Stub Patient $i',
        'phone': '0100000000$i',
        'revision': 1,
      },
  ];
  final Map<String, Map<String, dynamic>> idempotencyCache = {};
  final List<String> observedAuthHeaders = [];
  final List<String> observedIdempotencyKeys = [];
  final List<String> observedAcceptLanguages = [];
  int slowCallCount = 0;

  Future<void> start({int bindPort = 0}) async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, bindPort);
    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest req) async {
    final auth = req.headers.value('authorization');
    if (auth != null) observedAuthHeaders.add(auth);
    final idem = req.headers.value('idempotency-key');
    if (idem != null) observedIdempotencyKeys.add(idem);
    final lang = req.headers.value('accept-language');
    if (lang != null) observedAcceptLanguages.add(lang);

    final path = req.uri.path;
    final bodyStr = await utf8.decoder.bind(req).join();
    final body = bodyStr.isNotEmpty
        ? Map<String, dynamic>.from(jsonDecode(bodyStr) as Map)
        : <String, dynamic>{};

    // 1. Auth refresh (succeeds once for valid refresh token, 401 for expired)
    if (req.method == 'POST' && path.endsWith('/admin/auth/refresh')) {
      if (body['refreshToken'] == 'expired-refresh-value') {
        return _json(req, 401, {
          'error': {'code': 'REFRESH_EXPIRED', 'message': 'refresh_expired'},
        });
      }
      return _json(req, 200, {
        'data': {
          'accessToken': 'refreshed-access-value',
          'refreshToken': 'refreshed-refresh-value',
        },
      });
    }

    // 2. Protected endpoint (401 -> refresh -> 200)
    if (req.method == 'GET' && path.endsWith('/protected')) {
      if (auth != 'Bearer refreshed-access-value') {
        return _json(req, 401, {
          'error': {'code': 'UNAUTHORIZED', 'message': 'token_expired'},
        });
      }
      return _json(req, 200, {'data': {'ok': true}});
    }

    // 3. Forbidden endpoint (403)
    if (path.endsWith('/forbidden')) {
      return _json(req, 403, {
        'error': {
          'code': 'PERMISSION_DENIED',
          'message': 'ليس لديك صلاحية لتنفيذ هذا الإجراء',
        },
      });
    }

    // 4. Slow endpoint for timeout + retry
    if (req.method == 'GET' && path.endsWith('/slow')) {
      slowCallCount++;
      if (slowCallCount == 1) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      return _json(req, 200, {'data': {'attempt': slowCallCount}});
    }

    // 5. Paginated GET patients
    if (req.method == 'GET' && path.endsWith('/patients')) {
      final page = int.tryParse(req.uri.queryParameters['page'] ?? '1') ?? 1;
      final limit = int.tryParse(req.uri.queryParameters['limit'] ?? '2') ?? 2;
      final start = (page - 1) * limit;
      final end = (start + limit).clamp(0, patients.length);
      final slice = start < patients.length
          ? patients.sublist(start, end)
          : <Map<String, dynamic>>[];
      return _json(req, 200, {
        'data': slice,
        'totalCount': patients.length,
        'currentPage': page,
        'totalPages': (patients.length / limit).ceil(),
        'meta': {'page': page, 'limit': limit, 'total': patients.length},
      });
    }

    // 6. POST patients (422 validation with field errors + Idempotency-Key)
    if (req.method == 'POST' && path.endsWith('/patients')) {
      if (idem != null && idempotencyCache.containsKey(idem)) {
        return _json(req, 200, {'data': idempotencyCache[idem]});
      }
      final name = (body['name'] ?? '').toString().trim();
      if (name.isEmpty) {
        return _json(req, 422, {
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'patient_name_required',
            'fields': {'name': 'patient_name_required'},
          },
        });
      }
      final created = {
        ...body,
        'id': 'PAT-STUB-${patients.length + 1}',
        'revision': 1,
      };
      patients.add(created);
      if (idem != null) idempotencyCache[idem] = created;
      return _json(req, 200, {'data': created});
    }

    // 7. PUT patients/{id} (409 conflict on stale baseRevision)
    if (req.method == 'PUT' && path.contains('/patients/')) {
      final id = path.split('/').last;
      final idx = patients.indexWhere((p) => p['id'] == id);
      if (idx == -1) {
        return _json(req, 404, {
          'error': {'code': 'NOT_FOUND', 'message': 'patient_not_found'},
        });
      }
      final currentRev = (patients[idx]['revision'] as num?)?.toInt() ?? 1;
      final baseRev = (body['baseRevision'] as num?)?.toInt();
      if (baseRev != null && baseRev < currentRev) {
        return _json(req, 409, {
          'error': {'code': 'CONFLICT', 'message': 'version_conflict'},
          'serverVersion': patients[idx],
        });
      }
      patients[idx] = {...patients[idx], ...body, 'revision': currentRev + 1};
      return _json(req, 200, {'data': patients[idx]});
    }

    // 8. Delegate all remaining schema routes (bookings, audit-logs, sync/push, sync/pull, etc.)
    // to LocalServerApiConsumer so all ~155 schema endpoints work over HTTP.
    try {
      var relPath = path;
      if (relPath.startsWith('/api/v1/')) {
        relPath = relPath.substring('/api/v1/'.length);
      } else if (relPath.startsWith('/')) {
        relPath = relPath.substring(1);
      }
      final options = Options(headers: {
        if (idem != null) 'Idempotency-Key': idem,
        if (auth != null) 'Authorization': auth,
      });
      final qp = Map<String, dynamic>.from(req.uri.queryParameters);
      final result = await _localApi.router.dispatch(
        method: req.method,
        path: relPath,
        queryParameters: qp,
        body: body,
        options: options,
      );
      return _json(req, 200, Map<String, dynamic>.from(result as Map));
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 500;
      final errData = e.response?.data is Map
          ? Map<String, dynamic>.from(e.response!.data as Map)
          : {
              'error': {'code': 'HTTP_$status', 'message': e.message ?? 'error'}
            };
      return _json(req, status, errData);
    } catch (e) {
      return _json(req, 404, {
        'error': {'code': 'NOT_FOUND', 'message': 'route_not_found'},
      });
    }
  }

  Future<void> _json(
    HttpRequest req,
    int status,
    Map<String, dynamic> payload,
  ) async {
    req.response.statusCode = status;
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode(payload));
    await req.response.close();
  }
}
